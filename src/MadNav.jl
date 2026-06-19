module MadNav

# Dependencies and submodules are added incrementally during development
# Add corresponding using and include statements here as new features are added
using ArchGDAL, CSV, Flux, ForwardDiff, HDF5, LazyArtifacts
using DataFrames: DataFrame, combine, groupby, order, sort
using DelimitedFiles: readdlm, writedlm
using Compat: @compat

using Flux: @layer, Adam, Chain, DataLoader, Dense
using Flux: destructure, flatten, huber_loss, mae, mse, trainables
using LinearAlgebra, Plots, TOML, ZipFile, Zygote
using KernelFunctions: Kernel, PolynomialKernel, kernelmatrix

using Dash
using PlotlyJS
using Sockets
using DataStructures: CircularBuffer
using Base.Threads

include("utils/types.jl")
include("utils/analysis_util.jl")
include("utils/params.jl")
include("utils/xyz2h5.jl")
include("utils/dcm.jl")
include("utils/baseline_plots.jl")
include("utils/tolles_lawson.jl")
include("utils/get_XYZ.jl")

include("core/live_source.jl")
include("core/app.jl")
include("core/loader.jl")

include("dashboard/layout.jl")
include("dashboard/callbacks.jl")
include("dashboard/figures.jl")

include("datasource/uav.jl")
include("datasource/file_stream.jl")
include("datasource/sim_stream.jl")


@compat(public, (
ottawa_area_maps_gxf,emag2,emm720,namad,
MapS,MapSd,MapS3D,MapV,MagV,Traj,INS,XYZ0,XYZ1,XYZ20,XYZ21,
FILTres,CRLBout,INSout,FILTout,TempParams,
linreg,get_x,get_y,get_Axy,get_nn_m,sparse_group_lasso,
chunk_data,predict_rnn_full,predict_rnn_windowed,krr_fit,krr_test,
project_body_field_to_2d_igrf,get_optimal_rotation_matrix,
filter_events!,filter_events,
TL_vec2mat,TL_mat2vec,plsr_fit,elasticnet_fit,linear_fit,linear_test,
create_mag_c,corrupt_mag,
eval_results,eval_crlb,eval_ins,
downward_L,psd,
map_get_gxf,map_correct_igrf!,map_correct_igrf,map_chessboard!,
map_chessboard,map_utm2lla!,map_utm2lla,map_resample,get_step,
create_P0,create_Qd,get_pinson,fogm,
fdm,
compare_fields))

# Exported API functions for external use; add more here as needed
export 
LinCompParams,NNCompParams,EKF_RT,Map_Cache,
sgl_2020_train,sgl_2021_train,ottawa_area_maps,
dn2dlat,de2dlon,dlat2dn,dlon2de,detrend,get_bpf,bpf_data,bpf_data!,
err_segs,norm_sets,denorm_sets,get_ind,eval_shapley,plot_shapley,eval_gsa,
get_IGRF,get_igrf,get_years,gif_animation_m3,plot_basic,plot_activation,
plot_mag,plot_mag_c,plot_frequency,plot_correlation,plot_correlation_matrix,
comp_train,comp_test,comp_m2bc_test,comp_m3_test,comp_train_test,
create_XYZ0,create_traj,create_ins,create_flux,create_informed_xyz,
euler2dcm,dcm2euler,
ekf,crlb,
ekf_online_nn,ekf_online_nn_setup,
ekf_online,ekf_online_setup,
eval_filt,run_filt,
plot_filt!,plot_filt,plot_filt_err,plot_mag_map,plot_mag_map_err,
get_autocor,plot_autocor,gif_ellipse,
get_map,save_map,get_comp_params,save_comp_params,
get_XYZ20,get_XYZ21,get_XYZ,get_xyz,get_XYZ0,get_XYZ1,
get_flux,get_magv,get_MagV,get_traj,get_Traj,get_ins,get_INS,
map2kmz,path2kml,
upward_fft,vector_fft,map_expand,
map_interpolate,map_itp,map_trim,map_fill!,map_fill,map_gxf2h5,
plot_map!,plot_map,plot_path!,plot_path,plot_events!,plot_events,
map_check,get_map_val,get_cached_map,map_border,map_combine,
create_model,
mpf,
nekf,nekf_train,
create_TL_A,create_TL_coef,
xyz2h5

export SimFrame
export LiveSource, send_ctrl!
export ReplayProducer, FileStreamProducer, UAVProducer
export load_xyz20, make_demo_frames
export build_dash_app


end # module MadNav
