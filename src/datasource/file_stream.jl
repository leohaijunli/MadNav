# producers/file_stream.jl — large-file stream reader
#
# FileStreamProducer does not preload all data into memory;
# it reads the HDF5 file line by line and pushes frames at real-time pace.
# Suitable for large files (> hundreds of MB) or memory-constrained scenarios like RPi5.
#
# Supported commands: :pause / :speed / :stop (does not support :seek; stream read cannot rewind)

"""
    FileStreamProducer(path; line, speed) -> Function

# Return a Producer function that streams XYZ20 HDF5 file frames in real time.
# Does not support :seek (stream read cannot randomly access previous frames).

# Parameters
# - `path`  : HDF5 file path
# - `line`  : flight line number, default 1006.08
# - `speed` : initial playback speed, default 1.0

# Usage
```julia
src = LiveSource(
    FileStreamProducer("data/Flt1006_train.h5");
    caps = Set([:pause, :speed]),
)
```
"""
function FileStreamProducer(
    path  :: String;
    line  :: Float64 = 1006.08,
    speed :: Float64 = 1.0,
)
    return (ch::Channel{SimFrame}, ctrl_ch::Channel) -> begin
        running = true
        spd     = speed

        h5open(path, "r") do f
            # Read flight line indices (still needs full tt to locate, but other fields are read lazily)
            xyz = get_XYZ20(path)
            ind = get_ind(xyz; lines=line)
            n   = length(ind)
            t0  = xyz.traj.tt[ind[1]]

            for k in 1:n
                isopen(ch) || break

                # Consume control commands
                while isready(ctrl_ch)
                    cmd, val = take!(ctrl_ch)
                    cmd == :pause && (running = false)
                    cmd == :start && (running = true)
                    cmd == :speed && (spd = clamp(Float64(val), 0.1, 32.0))
                    cmd == :stop  && return
                end

                while !running && isopen(ch)
                    sleep(0.05)
                    while isready(ctrl_ch)
                        cmd, val = take!(ctrl_ch)
                        cmd == :start && (running = true)
                        cmd == :stop  && return
                    end
                end

                i = ind[k]
                frame = SimFrame(
                    xyz.traj.tt[i] - t0,
                    xyz.traj.lat[i],
                    xyz.traj.lon[i],
                    xyz.traj.alt[i],
                    xyz.mag_1_c[i],
                )
                put!(ch, frame)

                # Push frames at real Δt pace
                if k < n
                    Δt = (xyz.traj.tt[ind[k+1]] - xyz.traj.tt[i]) / spd
                    sleep(max(Δt, 0.0))
                end
            end
        end
    end
end
