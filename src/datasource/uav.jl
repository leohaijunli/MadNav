# producers/uav.jl — RPi5 local UAV data parser
#
# UAVProducer reads PX4 MAVLink byte streams from UART or USB serial on RPi5,
# parses them locally, and converts them into `SimFrame` objects pushed into `LiveSource`.
#
# Does not support `:seek` (live streams cannot rewind).
# Supports `:pause` (pauses channel writes but continues consuming serial data to avoid buffer overflow).
# Supports `:stop`  (closes the serial connection).
#
# Dependencies:
#   MAVLink parsing uses a pure-Julia `mavlink_parse_char` (see `_parse_mavlink` below)
#   or can be replaced with PyCall + pymavlink (slower but more complete protocol support).
#
# Serial dependency: add `LibSerialPort.jl` to `Project.toml` to enable real serial IO.

# using LibSerialPort   # 取消注释以启用真实串口

"""
    UAVProducer(port; baud, parser) -> Function

Return a producer function that reads MAVLink byte streams from the serial `port`
and parses them into `SimFrame` objects.

# Parameters
- `port`   : serial device path, e.g. "/dev/ttyAMA0" (RPi5 UART) or "/dev/ttyUSB0"
- `baud`   : baud rate, default 57600 (PX4 default telemetry rate)
- `parser` : `(buf::Vector{UInt8}) -> Union{SimFrame,Nothing}`
             custom byte-stream parser function, defaults to built-in MAVLink HIL_STATE parser

# Usage
```julia
# Real flight controller (RPi5 + PX4 via UART)
src = LiveSource(
    UAVProducer("/dev/ttyAMA0"; baud=57600);
    caps = Set([:pause, :stop]),
)

# Custom protocol (e.g. protobuf over UART)
src = LiveSource(
    UAVProducer("/dev/ttyUSB0"; parser=my_proto_parser);
    caps = Set([:pause, :stop]),
)
```
"""
function UAVProducer(
    port   :: String;
    baud   :: Int      = 57600,
    parser :: Function = _default_mavlink_parser,
)
    return (ch::Channel{SimFrame}, ctrl_ch::Channel) -> begin
        running = true

        # ── open serial port ───────────────────────────────────────────────────────
        # Uncomment for real environments:
        # sp = LibSerialPort.open(port, baud)
        # Use a mocked serial port during development/testing:
        sp = _open_serial_or_mock(port, baud)

        read_buf = UInt8[]
        sizehint!(read_buf, 512)

        try
            while isopen(ch)
                # Consume control commands (non-blocking)
                while isready(ctrl_ch)
                    cmd, _ = take!(ctrl_ch)
                    cmd == :pause && (running = false)
                    cmd == :start && (running = true)
                    cmd == :stop  && return
                end

                # Read available bytes (non-blocking)
                # Real environment: bytes = LibSerialPort.readbytes(sp, 256; timeout_ms=20)
                bytes = _serial_read(sp; timeout_ms=20)
                isempty(bytes) && continue

                append!(read_buf, bytes)

                # Try parsing a frame from the buffer
                frame, consumed = parser(read_buf)
                consumed > 0 && deleteat!(read_buf, 1:consumed)

                # Even when paused, continue consuming serial data to avoid UART FIFO overflow.
                # Only refrain from writing to the channel.
                if !isnothing(frame) && running
                    isopen(ch) && put!(ch, frame)
                end
            end
        finally
            # Real environment: LibSerialPort.close(sp)
            _close_serial(sp)
        end
    end
end

# ── Built-in MAVLink HIL_STATE_QUATERNION parser ─────────────────────────────────
#
# MAVLink frame structure (v1):
#   0xFE  LEN  SEQ  SYS  COMP  MSGID  [PAYLOAD]  CRC_LO  CRC_HI
#
# HIL_STATE_QUATERNION (msg id 115) contains:
#   time_usec(8) q(16) rollspeed(4) pitchspeed(4) yawspeed(4)
#   lat(4) lon(4) alt(4) vx(2) vy(2) vz(2) ...
#
# Only navigation fields are parsed here. Refer to MAVLink XML definitions for a full implementation.

const MAVLINK_STX_V1    = 0xFE
const MAVLINK_STX_V2    = 0xFD
const MSG_HIL_STATE_Q   = 115    # HIL_STATE_QUATERNION
const MSG_SCALED_IMU    = 26     # SCALED_IMU (contains raw magnetometer values)

function _default_mavlink_parser(buf::Vector{UInt8})
    # Return (frame_or_nothing, bytes_consumed)
    length(buf) < 8 && return nothing, 0


    # Search for the frame header
    start = findfirst(==(MAVLINK_STX_V1), buf)
    isnothing(start) && return nothing, length(buf) - 1   # discard invalid data

    start > 1 && return nothing, start - 1   # skip garbage bytes before header

    payload_len = Int(buf[2])
    frame_len   = 6 + payload_len + 2         # STX+LEN+SEQ+SYS+COMP+MSGID+payload+CRC

    length(buf) < frame_len && return nothing, 0   # frame incomplete, wait for more data

    msg_id = buf[6]

    if msg_id == MSG_HIL_STATE_Q && payload_len >= 64
        payload = buf[7:6+payload_len]
        frame   = _parse_hil_state_q(payload)
        return frame, frame_len
    end

    # Uninteresting message: skip full frame
    return nothing, frame_len
end

function _parse_hil_state_q(payload::AbstractVector{UInt8})
    # HIL_STATE_QUATERNION payload layout (little endian):
    # [0..7]   time_usec  uint64
    # [8..23]  attitude_quaternion  float32×4
    # [24..27] rollspeed  float32
    # [28..31] pitchspeed float32
    # [32..35] yawspeed   float32
    # [36..39] lat        int32  [degE7]
    # [40..43] lon        int32  [degE7]
    # [44..47] alt        int32  [mm, MSL]
    # ...

    t_us = reinterpret(UInt64, payload[1:8])[1]
    lat  = reinterpret(Int32,  payload[37:40])[1] * 1e-7   # deg
    lon  = reinterpret(Int32,  payload[41:44])[1] * 1e-7   # deg
    alt  = reinterpret(Int32,  payload[45:48])[1] * 1e-3   # m

    # mag_1_c: HIL_STATE does not contain magnetic field info, fill NaN here.
    # In real deployments, merge with SCALED_IMU messages or local RM3100 readings.
    return SimFrame(
        t_us * 1e-6,
        deg2rad(lat),
        deg2rad(lon),
        Float64(alt),
        NaN,
    )
end

# ── Serial port mock (development/testing)
# Replace with LibSerialPort calls in real deployment

mutable struct _MockSerial
    frames :: Vector{SimFrame}
    idx    :: Int
    open   :: Bool
end

function _open_serial_or_mock(port::String, baud::Int)
    @warn "UAVProducer: serial port $port not opened, using mock data (development mode)"
    return _MockSerial(make_demo_frames(300), 1, true)
end

Base.isopen(s::_MockSerial) = s.open

function _serial_read(s::_MockSerial; timeout_ms=20)
    s.idx > length(s.frames) && return UInt8[]
    sleep(timeout_ms / 1000)
    # Return a fake MAVLink frame byte sequence (test only, no real parsing)
    f = s.frames[s.idx]
    s.idx += 1
    return _encode_mock_frame(f)
end

_close_serial(s::_MockSerial) = (s.open = false)

function _encode_mock_frame(f::SimFrame)
    # Construct the smallest parsable mock MAVLink frame for _default_mavlink_parser
    # This function is not used in production; real byte streams come from serial.
    t_us  = round(UInt64, f.t * 1e6)
    lat_e7 = round(Int32, rad2deg(f.lat) * 1e7)
    lon_e7 = round(Int32, rad2deg(f.lon) * 1e7)
    alt_mm = round(Int32, f.alt * 1000)

    payload = zeros(UInt8, 64)
    payload[1:8]   = reinterpret(UInt8, [t_us])
    payload[37:40] = reinterpret(UInt8, [lat_e7])
    payload[41:44] = reinterpret(UInt8, [lon_e7])
    payload[45:48] = reinterpret(UInt8, [alt_mm])

    frame = vcat(
        UInt8[MAVLINK_STX_V1, 64, 0, 1, 1, MSG_HIL_STATE_Q],
        payload,
        UInt8[0x00, 0x00],   # CRC placeholder (mock does not validate)
    )
    return frame
end
