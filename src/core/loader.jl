# loader.jl — offline data loader
#
# Provides two helper functions for ReplayProducer / FileStreamProducer:
#   load_xyz20      — load a selected line from SGL XYZ20 HDF5 format
#   make_demo_frames — generate synthetic frames without any external files

"""
    load_xyz20(path, line=1006.08) -> Vector{SimFrame}

# Load a single flight line from SGL XYZ20 HDF5 and return frames with timestamps zeroed.

# Parameters
# - `path`  : HDF5 file path, e.g. `"data/Flt1006_train.h5"`
# - `line`  : flight line number, default 1006.08 (query available values via `xyz.df_options`)
"""
function load_xyz20(path::String, line::Float64=1006.08)::Vector{SimFrame}
    xyz = get_XYZ20(path)
    ind = get_ind(xyz; lines=line)

    tt      = xyz.traj.tt[ind]
    t0      = tt[1]
    lat     = xyz.traj.lat[ind]
    lon     = xyz.traj.lon[ind]
    alt     = xyz.traj.alt[ind]
    mag_1_c = xyz.mag_1_c[ind]

    return [
        SimFrame(tt[i] - t0, lat[i], lon[i], alt[i], mag_1_c[i])
        for i in eachindex(tt)
    ]
end

"""
    make_demo_frames(n=300; dt=0.02) -> Vector{SimFrame}

Generate n synthetic frames simulating constant-speed flight and sinusoidal magnetic field.
Does not depend on external files; used for development and CI testing.

# Parameters
# - `n`  : number of frames
# - `dt` : frame interval in seconds, default 0.02 (50 Hz)
"""
function make_demo_frames(n::Int=300; dt::Float64=0.02)::Vector{SimFrame}
    frames = Vector{SimFrame}(undef, n)
    # Each frame is computed independently with no cross-frame dependencies, safe for @threads
    Threads.@threads for i in 1:n
        t = (i - 1) * dt
        frames[i] = SimFrame(
            t,
            deg2rad(48.4  + i * 0.0002),
            deg2rad(-123.4 + i * 0.0003),
            150.0 + 10.0 * sin(t * 0.3),
            52000.0 + 200.0 * sin(t * 0.5) + randn() * 3.0,
        )
    end
    return frames
end
