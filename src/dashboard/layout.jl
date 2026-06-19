# layout.jl — Dash 布局构造
#
# build_layout(src) 根据 src.caps 决定显示哪些控件：
#   - :seek  → 进度条可用
#   - :speed → 倍速按钮可用
#   - :start → 开始按钮可用（实时模式只有暂停）
#
# UI 控件的 disabled 状态在此处静态确定，不在回调中判断数据来源。

"""
    build_layout(src::LiveSource, total_frames::Int) -> Dash component

根据 LiveSource 的 caps 构造 Dash 布局。

# 参数
- `src`          : LiveSource 实例，用于读取 caps
- `total_frames` : 回放模式的总帧数（实时模式传 0）
"""
function build_layout(src::LiveSource, total_frames::Int=0)

    has_seek  = :seek  ∈ src.caps
    has_speed = :speed ∈ src.caps
    has_start = :start ∈ src.caps

    mode_label = total_frames > 0 ? "回放模式" : "实时监控"

    # ── 控制栏 ────────────────────────────────────────────────────────────────
    btn_style = Dict("margin" => "4px", "padding" => "6px 14px")
    dis_style = merge(btn_style, Dict("opacity" => "0.35", "cursor" => "not-allowed"))

    controls = html_div([

        # 开始（实时模式不需要，用 disabled 区分）
        html_button("▶ 开始",
            id="btn-start",
            style = has_start ? btn_style : dis_style,
            disabled = !has_start,
        ),

        # 暂停（所有模式均支持）
        html_button("⏸ 暂停",
            id="btn-pause",
            style = btn_style,
        ),

        # 重置（仅回放）
        html_button("⏮ 重置",
            id="btn-reset",
            style = has_seek ? btn_style : dis_style,
            disabled = !has_seek,
        ),

        # 倍速（仅回放）
        html_button("x1",
            id="btn-x1",
            style = has_speed ? btn_style : dis_style,
            disabled = !has_speed,
        ),
        html_button("x2",
            id="btn-x2",
            style = has_speed ? btn_style : dis_style,
            disabled = !has_speed,
        ),
        html_button("x4",
            id="btn-x4",
            style = has_speed ? btn_style : dis_style,
            disabled = !has_speed,
        ),

        html_span(" | $mode_label",
            style=Dict("marginLeft"=>"12px", "color"=>"#888",
                       "fontFamily"=>"monospace", "fontSize"=>"13px")),

        html_span(id="status-text",
            style=Dict("marginLeft"=>"16px", "fontFamily"=>"monospace",
                       "fontSize"=>"13px")),

    ], style=Dict("textAlign"=>"center", "padding"=>"10px"))

    # ── 图表区 ────────────────────────────────────────────────────────────────
    plots = html_div([
        dcc_graph(id="graph-traj",
                  style=Dict("width"=>"50%", "display"=>"inline-block")),
        dcc_graph(id="graph-mag",
                  style=Dict("width"=>"50%", "display"=>"inline-block")),
    ])

    # ── 进度条（仅回放模式显示）─────────────────────────────────────────────
    slider = if has_seek && total_frames > 0
        n = total_frames
        html_div([
            dcc_slider(
                id    = "slider-frame",
                min   = 1,
                max   = n,
                step  = 1,
                value = 1,
                marks = Dict(
                    1     => "0",
                    n÷4   => "25%",
                    n÷2   => "50%",
                    3n÷4  => "75%",
                    n     => "100%",
                ),
            ),
        ], style=Dict("padding"=>"0 40px"))
    else
        # 实时模式：隐藏进度条，放一个窗口长度选择器
        html_div([
            html_span("显示窗口：",
                style=Dict("fontFamily"=>"monospace", "fontSize"=>"13px",
                           "marginRight"=>"8px")),
            dcc_dropdown(
                id      = "slider-frame",   # 同 id，回调复用
                options = [
                    Dict("label"=>"30s",  "value"=>1500),
                    Dict("label"=>"60s",  "value"=>3000),
                    Dict("label"=>"120s", "value"=>6000),
                ],
                value     = 1500,
                clearable = false,
                style     = Dict("width"=>"100px", "display"=>"inline-block",
                                 "verticalAlign"=>"middle"),
            ),
        ], style=Dict("padding"=>"8px 40px"))
    end

    # ── 组装 ─────────────────────────────────────────────────────────────────
    return html_div([
        html_h2("MagNav 数据监控",
                style=Dict("textAlign"=>"center", "fontFamily"=>"sans-serif")),
        controls,
        plots,
        slider,
        dcc_interval(id="interval", interval=200, n_intervals=0),
        dcc_store(id="store-window", data=total_frames > 0 ? total_frames : 1500),
    ])
end