# MadNav.jl
repo for MagNav navigation online, simulation and Dashboard.

# structure of the main codes
MadNav
├─ scripts
│  ├─ data_replay.jl                    
│  ├─ run.jl
│  └─ test.jl     
├─ src
│  ├─ MadNav.jl
│  ├─ core
│  │  ├─ app.jl
│  │  ├─ live_source.jl
│  │  └─ loader.jl
│  ├─ dashboard
│  │  ├─ callbacks.jl
│  │  ├─ figures.jl
│  │  └─ layout.jl
│  ├─ datasource
│  │  ├─ file_stream.jl
│  │  ├─ sim_stream.jl
│  │  └─ uav.jl
│  └─ utils
│     ├─ analysis_util.jl
│     ├─ baseline_plots.jl
│     ├─ dcm.jl
│     ├─ get_XYZ.jl
│     ├─ params.jl
│     ├─ tolles_lawson.jl
│     ├─ types.jl
│     └─ xyz2h5.jl


# Usage

```bash
# Simulated data
julia --project scripts/run.jl

# offline datasets replay
julia --project scripts/run.jl data/Flt1006_train.h5
