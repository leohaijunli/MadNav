# live_source.jl — unified data source
#
# LiveSource is the core system abstraction. It does not care where data comes from,
# it only handles:
#   1. running the producer function in a separate thread
#   2. synchronously writing producer frames from ch into the circular buffer buf
#   3. forwarding control commands to producer via ctrl_ch (producer may ignore them)
#
# All Producers (ReplayProducer, FileStreamProducer, UAVProducer)
# have signature (ch::Channel{SimFrame}, ctrl_ch::Channel) -> Nothing.
# They are injected externally, so LiveSource itself does not need modification.

"""
    LiveSource

Unified data source. The producer function runs in a separate thread, pushing SimFrame into ch;
an internal worker thread synchronously writes ch frames into the circular buffer buf for UI slicing.

# Fields
- `producer` : `(ch, ctrl_ch) -> Nothing`, runs in a separate thread
- `ch`        : frame stream channel, UI subscribes here for trigger events
- `buf`       : circular buffer holding the latest buf_size frames for UI rendering
- `ctrl_ch`   : control command channel (:start/:pause/:seek/:speed), producer may respond
- `caps`      : set of capabilities supported by the producer, used to enable/disable UI controls
"""
struct LiveSource
    producer :: Function
    ch       :: Channel{SimFrame}
    buf      :: CircularBuffer{SimFrame}
    ctrl_ch  :: Channel{Tuple{Symbol,Any}}
    caps     :: Set{Symbol}
end

    # Example (do not execute on include):
    # src = LiveSource(UAVProducer("/dev/ttyAMA0"))   # default caps = Set([:pause])
"""
    LiveSource(producer; buf_size, ch_size, caps) -> LiveSource

Construct a LiveSource and immediately start the producer thread and buffer worker thread.

# Parameters
- `producer`  : producer function with signature `(ch, ctrl_ch) -> Nothing`
- `buf_size`  : circular buffer capacity (frames), default 3000
- `ch_size`   : frame stream channel buffer depth, default 64
- `caps`      : producer control capabilities, default `Set([:pause])`

# Example
```julia
src = LiveSource(ReplayProducer(frames); caps=Set([:pause, :seek, :speed]))
src = LiveSource(UAVProducer("/dev/ttyAMA0"))   # default caps = Set([:pause])
```
"""
function LiveSource(
    producer :: Function;
    buf_size :: Int    = 3000,
    ch_size  :: Int    = 64,
    caps     :: Set{Symbol} = Set([:pause]),
)
    src = LiveSource(
        producer,
        Channel{SimFrame}(ch_size),
        CircularBuffer{SimFrame}(buf_size),
        Channel{Tuple{Symbol,Any}}(32),
        caps,
    )
    Threads.@spawn _buffer_worker!(src)
    Threads.@spawn src.producer(src.ch, src.ctrl_ch)
    return src
end

"""
    send_ctrl!(src, cmd, val=nothing)

Send a control command to the producer. If the producer does not support the command, it ignores it silently.

# Common commands
- `:start`         — start pushing frames
- `:pause`         — pause
- `:seek, idx::Int` — jump to a specific frame index (ReplayProducer only)
- `:speed, v::Float64` — set playback speed (ReplayProducer only)
- `:stop`          — stop the producer and terminate the thread
"""
function send_ctrl!(src::LiveSource, cmd::Symbol, val=nothing)
    isopen(src.ctrl_ch) && put!(src.ctrl_ch, (cmd, val))
end

"""
    stop!(src)

Stop the producer and close all channels.
"""
function stop!(src::LiveSource)
    send_ctrl!(src, :stop)
    sleep(0.1)
    isopen(src.ch)      && close(src.ch)
    isopen(src.ctrl_ch) && close(src.ctrl_ch)
end

"""
    latest_frames(src, n) -> Vector{SimFrame}

Get the latest n frames from the circular buffer. Thread-safe (Julia CircularBuffer reads are read-only).
"""
function latest_frames(src::LiveSource, n::Int)::Vector{SimFrame}
    buf = src.buf
    len = length(buf)
    n   = min(n, len)
    n == 0 && return SimFrame[]
    return collect(buf)[max(1, len - n + 1):len]
end

"""
    _buffer_worker!(src)

Internal worker: synchronously write frames from channel ch into the circular buffer.
"""
function _buffer_worker!(src::LiveSource)
    for frame in src.ch          # for loop exits automatically when channel closes
        push!(src.buf, frame)
    end
end
