# datasource/sim_stream.jl — offline simulation stream producer (simulate real-time)
#
# SimStreamProducer accepts a preloaded Vector{SimFrame} and pushes frames at real-time
# intervals (sleeping by the true Δt divided by speed) to simulate a live stream.
#
# Supports full control commands: :start / :pause / :seek / :speed / :stop
# This is the most fully featured producer of the three.

"""
    ReplayProducer(frames; start_paused=true) -> Function

# Return a Producer function that pushes `frames` into `ch` at real-time pace.

# Parameters
# - `frames`       : preloaded frame sequence (from load_xyz20 or make_demo_frames)
# - `start_paused` : start in paused state and wait for :start command if true (default true)

# 用法
```julia
frames = load_xyz20("data/Flt1006_train.h5")
src = LiveSource(
    ReplayProducer(frames);
    caps = Set([:pause, :seek, :speed, :start]),
)
```
"""
function ReplayProducer(frames::Vector{SimFrame}; start_paused::Bool=true)
    return (ch::Channel{SimFrame}, ctrl_ch::Channel) -> begin
        total   = length(frames)
        idx     = 1
        speed   = 1.0
        running = !start_paused

        while isopen(ch)
            # Consume all pending control commands (non-blocking)
            while isready(ctrl_ch)
                cmd, val = take!(ctrl_ch)
                if cmd == :start
                    running = true
                elseif cmd == :pause
                    running = false
                elseif cmd == :seek
                    idx = clamp(Int(val), 1, total)
                elseif cmd == :speed
                    speed = clamp(Float64(val), 0.1, 32.0)
                elseif cmd == :stop
                    return
                end
            end

            if running && idx <= total
                put!(ch, frames[idx])

                # Sleep by the real inter-frame interval to maintain timing
                if idx < total
                    Δt = (frames[idx + 1].t - frames[idx].t) / speed
                    sleep(max(Δt, 0.0))
                end

                idx += 1

                # Playback finished: pause at last frame and wait for seek or stop
                if idx > total
                    running = false
                end
            else
                sleep(0.02)   # idle: wait for control commands
            end
        end
    end
end
