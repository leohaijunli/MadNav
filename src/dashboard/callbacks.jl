# callbacks.jl — Dash 回调注册
#
# register_callbacks!(app, src, total_frames) 注册所有 Dash 回调。
# 回调只消费 src.buf（环形缓冲），不感知数据来源。
#
# 控制命令通过 send_ctrl!(src, ...) 转发给 producer，
# producer 不支持的命令会被其内部静默忽略。

"""
    register_callbacks!(app, src::LiveSource, total_frames::Int)

注册 Dash 回调。

- 控制回调：按钮 / slider / interval → send_ctrl! → producer
- 渲染回调：interval → buf 切片 → figures
"""
function register_callbacks!(app, src::LiveSource, total_frames::Int=0)
    _register_control_callback!(app, src, total_frames)
    _register_render_callback!(app, src, total_frames)
end

# ── 控制回调 ──────────────────────────────────────────────────────────────────

function _register_control_callback!(app, src::LiveSource, total_frames::Int)
    callback!(app,
        Output("store-window", "data"),
        Input("btn-start",    "n_clicks"),
        Input("btn-pause",    "n_clicks"),
        Input("btn-reset",    "n_clicks"),
        Input("btn-x1",       "n_clicks"),
        Input("btn-x2",       "n_clicks"),
        Input("btn-x4",       "n_clicks"),
        Input("slider-frame", "value"),
        Input("interval",     "n_intervals"),
        prevent_initial_call = true,
    ) do args...
        ctx       = callback_context()
        triggered = isempty(ctx.triggered) ? "" : ctx.triggered[1].prop_id

        # 使用 startswith 精确匹配，避免 id 前缀误触
        if startswith(triggered, "btn-start")
            send_ctrl!(src, :start)
        elseif startswith(triggered, "btn-pause")
            send_ctrl!(src, :pause)
        elseif startswith(triggered, "btn-reset")
            send_ctrl!(src, :seek, 1)
        elseif startswith(triggered, "btn-x1")
            send_ctrl!(src, :speed, 1.0)
        elseif startswith(triggered, "btn-x2")
            send_ctrl!(src, :speed, 2.0)
        elseif startswith(triggered, "btn-x4")
            send_ctrl!(src, :speed, 4.0)
        elseif startswith(triggered, "slider-frame")
            val = args[7]
            if total_frames > 0
                # 回放模式：slider 值为帧索引
                send_ctrl!(src, :seek, clamp(Int(val), 1, total_frames))
                return val
            else
                # 实时模式：dropdown 值为窗口大小（帧数）
                return val
            end
        end

        # 返回当前 store 值（不变）
        return length(src.buf)
    end
end

# ── 渲染回调 ──────────────────────────────────────────────────────────────────

function _register_render_callback!(app, src::LiveSource, total_frames::Int)
    callback!(app,
        Output("graph-traj",   "figure"),
        Output("graph-mag",    "figure"),
        Output("status-text",  "children"),
        Output("slider-frame", "value"),
        Input("store-window",  "data"),
        Input("interval",      "n_intervals"),
    ) do window_val, _n_intervals
        # window_val：回放模式为当前帧索引，实时模式为窗口帧数
        n      = isnothing(window_val) ? 300 : Int(window_val)
        frames = latest_frames(src, n)
        arrs   = frames_to_arrays(frames)

        traj_fig = make_traj_fig(arrs)
        mag_fig  = make_mag_fig(arrs)
        status   = _build_status(src, frames, total_frames)

        # slider value：回放返回当前帧位置，实时返回窗口大小不变
        slider_val = total_frames > 0 ? length(src.buf) : n

        return traj_fig, mag_fig, status, slider_val
    end
end

# ── 状态栏文本 ────────────────────────────────────────────────────────────────

function _build_status(src::LiveSource, frames::Vector{SimFrame}, total_frames::Int)
    isempty(frames) && return "等待数据…"

    f   = frames[end]
    buf = length(src.buf)

    base = "缓冲帧数: $buf  |  " *
           "lat=$(round(rad2deg(f.lat), digits=4))°  " *
           "lon=$(round(rad2deg(f.lon), digits=4))°  " *
           "alt=$(round(f.alt, digits=1))m  " *
           "mag=$(isnan(f.mag_1_c) ? "N/A" : "$(round(f.mag_1_c, digits=2))nT")"

    total_frames > 0 && return base * "  |  进度: $buf/$total_frames"
    return base * "  |  实时"
end