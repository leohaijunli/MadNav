# sim_replay.jl
# XYZ20 replay with Dash.jl - pure HTTP, no WebGL needed
# Works in any browser, including from outside the VM
#
# Usage: julia --project scripts/sim_replay.jl [data.h5]
# Open:  http://<VM_IP>:8050

using MadNav


using Dash
using PlotlyJS
using HDF5
using JSON3
using Base.Threads

# ──────────────────────────────────────────────────────────────────────────────
# 1. SimFrame
# ──────────────────────────────────────────────────────────────────────────────

struct SimFrame
    t       :: Float64
    lat     :: Float64   # [rad]
    lon     :: Float64   # [rad]
    alt     :: Float64   # [m]
    mag_1_c :: Float64   # [nT]
    # Extend here:
    # mag_1_uc :: Float64
    # ins_roll :: Float64
end

# ──────────────────────────────────────────────────────────────────────────────
# 2. Load / Demo data
# ──────────────────────────────────────────────────────────────────────────────

function load_xyz20(path::String)::Vector{SimFrame}
    xyz    = get_XYZ20("data/Flt1006_train.h5") # load flight data
    line = 1006.08 # select flight line (row) from df_options
    ind = get_ind(xyz;lines=line) # get index of selected line
    tt = (xyz.traj.tt[ind] .- xyz.traj.tt[ind][1])

    # Helper function to calculate mean using only Base Julia
    function manual_mean(v::AbstractVector)
        return sum(v) / length(v)
    end

    fields   = fieldnames(typeof(xyz))

    val_mag_1_c = getfield(xyz, :mag_1_c)[ind]
    val_lat = xyz.traj.lat[ind]
    val_lon = xyz.traj.lon[ind]
    val_alt = xyz.traj.alt[ind]

    [SimFrame(tt[i], val_lat[i], val_lon[i], val_alt[i], val_mag_1_c[i])
              for i in eachindex(tt)]
end

function make_demo_frames(n=300)::Vector{SimFrame}
    frames = Vector{SimFrame}(undef, n)
    Threads.@threads for i in 1:n
        frames[i] = SimFrame(
            (i-1) * 0.02,
            deg2rad(45.4  + (i-1) * 0.0002),
            deg2rad(-75.7 + (i-1) * 0.0003),
            305.0 + 10 * sin((i-1) * 0.05),
            52000.0 + 200 * sin((i-1) * 0.08) + randn() * 3,
        )
    end
    return frames
end

# ──────────────────────────────────────────────────────────────────────────────
# 3. Replay state (shared between callbacks)
# ──────────────────────────────────────────────────────────────────────────────

mutable struct ReplayState
    frames   :: Vector{SimFrame}
    idx      :: Atomic{Int}
    running  :: Atomic{Bool}
    speed    :: Atomic{Float64}
    last_t   :: Atomic{Float64}
    frame_ch :: Channel{Int}
    cmd_ch   :: Channel{Tuple{Symbol,Any}}
end

function ReplayState(frames; buffer=256)
    rs = ReplayState(
        frames,
        Atomic{Int}(),
        Atomic{Bool}(),
        Atomic{Float64}(),
        Atomic{Float64}(),
        Channel{Int}(buffer),
        Channel{Tuple{Symbol,Any}}(32),
    )
    rs.idx[] = 1
    rs.running[] = false
    rs.speed[] = 1.0
    rs.last_t[] = time()
    Threads.@spawn replay_thread!(rs)
    return rs
end

function send_command!(rs::ReplayState, cmd::Symbol, payload=nothing)
    if isopen(rs.cmd_ch)
        put!(rs.cmd_ch, (cmd, payload))
    end
end

function latest_frame_idx(rs::ReplayState)
    idx = rs.idx[]
    while isready(rs.frame_ch)
        idx = take!(rs.frame_ch)
    end
    return idx
end

function replay_thread!(rs::ReplayState)
    frames = rs.frames
    total = length(frames)

    while isopen(rs.cmd_ch)
        while isready(rs.cmd_ch)
            cmd, payload = take!(rs.cmd_ch)
            if cmd === :start
                rs.running[] = true
                rs.last_t[] = time()
            elseif cmd === :pause
                rs.running[] = false
            elseif cmd === :reset
                rs.idx[] = 1
                rs.last_t[] = time()
                put!(rs.frame_ch, 1)
            elseif cmd === :speed
                rs.speed[] = Float64(payload)
            elseif cmd === :seek
                rs.idx[] = clamp(Int(payload), 1, total)
                rs.last_t[] = time()
                put!(rs.frame_ch, rs.idx[])
            elseif cmd === :stop
                close(rs.frame_ch)
                close(rs.cmd_ch)
                return
            end
        end

        if rs.running[]
            now = time()
            dt_wall = now - rs.last_t[]
            rs.last_t[] = now

            idx = rs.idx[]
            t_target = frames[idx].t + dt_wall * rs.speed[]
            while idx < total && frames[idx].t < t_target
                idx += 1
            end
            idx = min(idx, total)

            if idx != rs.idx[]
                rs.idx[] = idx
                put!(rs.frame_ch, idx)
            end
        else
            rs.last_t[] = time()
        end

        sleep(0.02)
    end
end

# ──────────────────────────────────────────────────────────────────────────────
# 4. Build Dash app
# ──────────────────────────────────────────────────────────────────────────────

function build_dash_app(rs::ReplayState)

    frames  = rs.frames
    total   = length(frames)
    lons_d  = Vector{Float64}(undef, total)
    lats_d  = Vector{Float64}(undef, total)
    mags    = Vector{Float64}(undef, total)
    ts      = Vector{Float64}(undef, total)

    Threads.@threads for i in 1:total
        f = frames[i]
        lons_d[i] = rad2deg(f.lon)
        lats_d[i] = rad2deg(f.lat)
        mags[i] = f.mag_1_c
        ts[i] = f.t - frames[1].t
    end

    app = dash(; assets_folder="assets")

    app.layout = html_div([

        html_h2("MadNav Sim Replay | XYZ20",
                style=Dict("textAlign"=>"center", "fontFamily"=>"sans-serif")),

        # Control bar
        html_div([
            html_button("▶ Start",  id="btn-start",
                        style=Dict("margin"=>"4px","padding"=>"6px 14px")),
            html_button("⏸ Pause",  id="btn-pause",
                        style=Dict("margin"=>"4px","padding"=>"6px 14px")),
            html_button("⏮ Reset",  id="btn-reset",
                        style=Dict("margin"=>"4px","padding"=>"6px 14px")),
            html_button("x1",       id="btn-x1",
                        style=Dict("margin"=>"4px","padding"=>"6px 14px")),
            html_button("x2",       id="btn-x2",
                        style=Dict("margin"=>"4px","padding"=>"6px 14px")),
            html_button("x4",       id="btn-x4",
                        style=Dict("margin"=>"4px","padding"=>"6px 14px")),
            html_span(id="status-text",
                      style=Dict("marginLeft"=>"20px","fontFamily"=>"monospace")),
        ], style=Dict("textAlign"=>"center", "padding"=>"10px")),

        # Two plots side by side
        html_div([
            dcc_graph(id="graph-traj",
                      style=Dict("width"=>"50%","display"=>"inline-block")),
            dcc_graph(id="graph-mag",
                      style=Dict("width"=>"50%","display"=>"inline-block")),
        ]),

        # Progress slider
        html_div([
            dcc_slider(id="slider-frame",
                       min=1, max=total, step=1, value=1,
                       marks=Dict(
                           1       => "0s",
                           total÷4 => "$(round(ts[total÷4],digits=1))s",
                           total÷2 => "$(round(ts[total÷2],digits=1))s",
                           total   => "$(round(ts[end],digits=1))s",
                       )),
        ], style=Dict("padding"=>"0 40px")),

        # Timer triggers periodic update
        dcc_interval(id="interval", interval=200, n_intervals=0),

        # Hidden store for current frame index
        dcc_store(id="store-window", data=1),

    ])

    # ── Callbacks ─────────────────────────────────────────────────────────────

    # Button callbacks -> update replay state
    callback!(app,
        Output("store-window", "data"),
        Input("btn-start", "n_clicks"),
        Input("btn-pause", "n_clicks"),
        Input("btn-reset", "n_clicks"),
        Input("btn-x1",    "n_clicks"),
        Input("btn-x2",    "n_clicks"),
        Input("btn-x4",    "n_clicks"),
        Input("slider-frame", "value"),
        Input("interval",  "n_intervals"),
        prevent_initial_call=true,
    ) do args...

        # args order: start_n, pause_n, reset_n, x1_n, x2_n, x4_n, slider_val, n_intervals
        start_n   = length(args) >= 1 ? args[1] : nothing
        pause_n   = length(args) >= 2 ? args[2] : nothing
        reset_n   = length(args) >= 3 ? args[3] : nothing
        x1_n      = length(args) >= 4 ? args[4] : nothing
        x2_n      = length(args) >= 5 ? args[5] : nothing
        x4_n      = length(args) >= 6 ? args[6] : nothing
        slider_val= length(args) >= 7 ? args[7] : nothing
        n_intervals=length(args) >= 8 ? args[8] : nothing

        ctx = callback_context()
        triggered = isempty(ctx.triggered) ? "" : ctx.triggered[1].prop_id

        if occursin("btn-start",  triggered)
            send_command!(rs, :start)
        elseif occursin("btn-pause",  triggered)
            send_command!(rs, :pause)
        elseif occursin("btn-reset",  triggered)
            send_command!(rs, :reset)
        elseif occursin("btn-x1",     triggered)
            send_command!(rs, :speed, 1.0)
        elseif occursin("btn-x2",     triggered)
            send_command!(rs, :speed, 2.0)
        elseif occursin("btn-x4",     triggered)
            send_command!(rs, :speed, 4.0)
        elseif occursin("slider-frame", triggered)
            send_command!(rs, :seek, clamp(Int(slider_val), 1, total))
        end

        return latest_frame_idx(rs)
    end

    # Render plots from current index
    callback!(app,
        Output("graph-traj",   "figure"),
        Output("graph-mag",    "figure"),
        Output("status-text",  "children"),
        Output("slider-frame", "value"),
        Input("store-window", "data"),
        Input("interval", "n_intervals"),
    ) do args...
        # args order: store_idx, interval_n
        idx = length(args) >= 1 ? args[1] : 1

        i = clamp(Int(idx), 1, total)

        # Show up to current frame
        lon_s = lons_d[1:i]
        lat_s = lats_d[1:i]
        mag_s = mags[1:i]
        t_s   = ts[1:i]

        # Trajectory colored by mag_1_c
        traj_fig = PlotlyJS.plot(
            PlotlyJS.scatter(
                x=lon_s, y=lat_s,
                mode="lines+markers",
                marker=attr(
                    color=mag_s,
                    colorscale="Plasma",
                    size=4,
                    colorbar=attr(title="nT", thickness=12),
                ),
                line=attr(color="gray", width=1),
                name="trajectory",
            ),
            Layout(
                title="Flight Trajectory",
                xaxis_title="Longitude (deg)",
                yaxis_title="Latitude (deg)",
                height=420,
                margin=attr(l=50,r=20,t=40,b=40),
                uirevision="traj",   # prevents zoom reset on update
            )
        )

        # mag_1_c time series
        mag_fig = PlotlyJS.plot(
            PlotlyJS.scatter(
                x=t_s, y=mag_s,
                mode="lines",
                line=attr(color="dodgerblue", width=1.5),
                name="mag_1_c",
            ),
            Layout(
                title="mag_1_c Time Series",
                xaxis_title="Time (s)",
                yaxis_title="nT",
                height=420,
                margin=attr(l=60,r=20,t=40,b=40),
                uirevision="mag",
            )
        )

        f = frames[i]
        status = "Frame $(i)/$(total)  |  " *
             "t=$(round(f.t - frames[1].t, digits=2))s  |  " *
             "alt=$(round(f.alt, digits=1))m  |  " *
             "mag_1_c=$(round(f.mag_1_c, digits=2))nT  |  " *
             "speed=$(rs.speed[])x"

        return traj_fig, mag_fig, status, i
    end

    return app
end

# ──────────────────────────────────────────────────────────────────────────────
# 5. Main
# ──────────────────────────────────────────────────────────────────────────────

function main()
    hdf5_path = length(ARGS) > 0 ? ARGS[1] : ""

    frames = if hdf5_path != "" && isfile(hdf5_path)
        println("Loading XYZ20 HDF5: $hdf5_path")
        load_xyz20(hdf5_path)
    else
        println(hdf5_path != "" ? "File not found: $hdf5_path. Using demo data instead."
            : "No data file provided. Using demo data.")    
        println("Using demo data (300 frames @ 50Hz)")
        make_demo_frames(300)
    end

    println("Loaded $(length(frames)) frames, " *
            "duration = $(round(frames[end].t - frames[1].t, digits=2)) s")

    rs  = ReplayState(frames)
    app = build_dash_app(rs)

    # Get LAN IP
    try
        ips = split(strip(read(`hostname -I`, String)))
        filter!(ip -> !startswith(ip, "127."), ips)
        println("\n========================================")
        println("Dash server running!")
        println("Local:  http://127.0.0.1:8050")
        for ip in ips
            println("LAN:    http://$(ip):8050")
        end
        println("========================================\n")
    catch
        println("Open: http://0.0.0.0:8050")
    end

    run_server(app, "0.0.0.0", 8050; debug=false)
end

if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main()
end