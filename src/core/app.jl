# app.jl — Dash 应用组装 + CLI 入口
#
# build_dash_app(src, total_frames) 组装布局和回调，返回 Dash app。
# main() 解析 CLI 参数，构造合适的 Producer，启动服务。
#
# CLI 用法：
#   julia --project scripts/run.jl                        # demo 回放
#   julia --project scripts/run.jl data/Flt1006_train.h5  # 离线文件回放
#   julia --project scripts/run.jl --live /dev/ttyAMA0    # RPi5 UAV 实时
#   julia --project scripts/run.jl --stream data/big.h5   # 大文件流式（不全量加载）

"""
    build_dash_app(src::LiveSource, total_frames::Int=0) -> Dash.DashApp

组装 Dash 应用。`total_frames` 在回放模式下为总帧数，实时模式传 0。
"""
function build_dash_app(src::LiveSource, total_frames::Int=0)
    app = dash(; assets_folder=joinpath(@__DIR__, "..", "assets"))
    app.layout = build_layout(src, total_frames)
    register_callbacks!(app, src, total_frames)
    return app
end

"""
    main()

CLI 入口。解析 ARGS，构造 LiveSource，启动 Dash 服务。
"""
function main()
    host = "0.0.0.0"
    port = 8050

    src, total_frames = _parse_args(ARGS)

    app = build_dash_app(src, total_frames)

    _print_banner(host, port)

    # 注册退出时清理
    atexit(() -> stop!(src))

    run_server(app, host, port; debug=false)
end

# ── 参数解析 ──────────────────────────────────────────────────────────────────

function _parse_args(args::Vector{String})
    # --live /dev/ttyAMA0 [baud]
    if "--live" ∈ args
        idx   = findfirst(==("--live"), args)
        dev   = length(args) > idx ? args[idx+1] : "/dev/ttyAMA0"
        baud  = length(args) > idx+1 ? parse(Int, args[idx+2]) : 57600
        @info "UAV 实时模式：$dev @ $baud baud"
        src = LiveSource(
            UAVProducer(dev; baud=baud);
            caps = Set([:pause]),
        )
        return src, 0

    # --stream path/to/file.h5
    elseif "--stream" ∈ args
        idx  = findfirst(==("--stream"), args)
        path = length(args) > idx ? args[idx+1] : error("--stream 需要文件路径")
        @info "大文件流式模式：$path"
        src = LiveSource(
            FileStreamProducer(path);
            caps = Set([:pause, :speed]),
        )
        return src, 0   # 流式模式不预知总帧数

    # path/to/file.h5 — 预加载回放
    elseif length(args) > 0 && isfile(args[1])
        path = args[1]
        @info "离线回放模式：$path"
        frames = load_xyz20(path)
        src = LiveSource(
            ReplayProducer(frames);
            caps = Set([:pause, :seek, :speed, :start]),
        )
        return src, length(frames)

    # 无参数 — demo 数据
    else
        @info "Demo 模式（合成数据，300 帧 @ 50 Hz）"
        frames = make_demo_frames(300)
        src = LiveSource(
            ReplayProducer(frames);
            caps = Set([:pause, :seek, :speed, :start]),
        )
        return src, length(frames)
    end
end

function _print_banner(host::String, port::Int)
    ips = try
        filter(!startswith("127."), split(strip(read(`hostname -I`, String))))
    catch
        String[]
    end

    println("\n" * "="^44)
    println("  MagNav 数据监控 Dash 服务已启动！")
    println("  Local : http://127.0.0.1:$port")
    for ip in ips
        println("  LAN   : http://$(ip):$port")
    end
    println("="^44 * "\n")
end

# 允许直接 `julia --project src/app.jl` 运行（不经过 scripts/）
if abspath(PROGRAM_FILE) == abspath(@__FILE__)
    main()
end