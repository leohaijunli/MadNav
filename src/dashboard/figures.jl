# figures.jl — PlotlyJS 图表工厂
#
# 集中管理所有图表定义。新增 series 只需在 SERIES 中添加条目，
# make_mag_fig 自动生成对应 trace，无需修改其他文件。

# ── Series 配置 ───────────────────────────────────────────────────────────────
# 每个 entry 对应磁场时序图中的一条曲线。
# field: SimFrame 中的字段名（Symbol）
# label: 图例标签
# color: Plotly 颜色字符串

const SERIES = [
    (field=:mag_1_c, label="mag_1_c [nT]", color="dodgerblue"),
    # 未来扩展示例：
    # (field=:mag_1_uc, label="mag_1_uc [nT]", color="tomato"),
]

# ── 工具函数 ──────────────────────────────────────────────────────────────────

"""
    frames_to_arrays(frames) -> NamedTuple

将 Vector{SimFrame} 拆解为各字段的 Float64 数组，供图表使用。
"""
function frames_to_arrays(frames::Vector{SimFrame})
    isempty(frames) && return (t=Float64[], lat=Float64[], lon=Float64[],
                                alt=Float64[], mag_1_c=Float64[])
    t0 = frames[1].t
    return (
        t      = [f.t - t0        for f in frames],
        lat    = [rad2deg(f.lat)  for f in frames],
        lon    = [rad2deg(f.lon)  for f in frames],
        alt    = [f.alt           for f in frames],
        mag_1_c = [f.mag_1_c     for f in frames],
    )
end

# ── 图表工厂 ──────────────────────────────────────────────────────────────────

"""
    make_traj_fig(arrs) -> PlotlyJS figure

生成轨迹散点图，颜色编码 mag_1_c。
`arrs` 为 `frames_to_arrays` 的返回值。
"""
function make_traj_fig(arrs)
    isempty(arrs.t) && return _empty_fig("等待数据…", "经度 (deg)", "纬度 (deg)")

    trace = PlotlyJS.scatter(
        x    = arrs.lon,
        y    = arrs.lat,
        mode = "lines+markers",
        marker = attr(
            color     = arrs.mag_1_c,
            colorscale = "Plasma",
            size      = 4,
            colorbar  = attr(title="nT", thickness=12),
        ),
        line = attr(color="gray", width=1),
        name = "trajectory",
    )

    layout = Layout(
        title       = "飞行轨迹",
        xaxis_title = "经度 (deg)",
        yaxis_title = "纬度 (deg)",
        height      = 420,
        margin      = attr(l=50, r=20, t=40, b=40),
        uirevision  = "traj",   # 防止视角在更新时被重置
    )

    return PlotlyJS.plot(trace, layout)
end

"""
    make_mag_fig(arrs) -> PlotlyJS figure

生成磁场时序图。根据 SERIES 配置自动生成多条曲线。
`arrs` 为 `frames_to_arrays` 的返回值。
"""
function make_mag_fig(arrs)
    isempty(arrs.t) && return _empty_fig("等待数据…", "时间 (s)", "nT")

    traces = [
        PlotlyJS.scatter(
            x    = arrs.t,
            y    = getfield(arrs, s.field),
            mode = "lines",
            line = attr(color=s.color, width=1.5),
            name = s.label,
        )
        for s in SERIES
        if hasproperty(arrs, s.field)
    ]

    layout = Layout(
        title       = "磁场时序",
        xaxis_title = "时间 (s)",
        yaxis_title = "nT",
        height      = 420,
        margin      = attr(l=60, r=20, t=40, b=40),
        uirevision  = "mag",
        legend      = attr(x=0, y=1),
    )

    return PlotlyJS.plot(traces, layout)
end

# 空占位图，channel 尚无数据时使用
function _empty_fig(msg::String, xtitle::String, ytitle::String)
    layout = Layout(
        title       = msg,
        xaxis_title = xtitle,
        yaxis_title = ytitle,
        height      = 420,
        margin      = attr(l=50, r=20, t=40, b=40),
    )
    return PlotlyJS.plot(PlotlyJS.scatter(x=[], y=[]), layout)
end