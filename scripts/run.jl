#!/usr/bin/env julia
# scripts/run.jl — CLI 入口
#
# 用法（在项目根目录执行）：
#
#   julia --project scripts/run.jl
#   julia --project scripts/run.jl data/Flt1006_train.h5
#   julia --project scripts/run.jl --live /dev/ttyAMA0
# scripts/run.jl — CLI entry
#
# Usage (run from the project root):
#
#   julia --project scripts/run.jl
#   julia --project scripts/run.jl data/Flt1006_train.h5
#   julia --project scripts/run.jl --live /dev/ttyAMA0
#   julia --project scripts/run.jl --live /dev/ttyAMA0 57600
#   julia --project scripts/run.jl --stream data/Flt1006_train.h5

using MadNav
MadNav.main()
