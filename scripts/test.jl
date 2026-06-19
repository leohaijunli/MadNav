using MadNav
using Plots
using CairoMakie

println("Hello, MadNav!")

xyz    = get_XYZ20("data/Flt1006_train.h5") # load flight data
typeof(xyz) # check data type

line = 1006.08 # select flight line (row) from df_options
ind = get_ind(xyz;lines=line) # get index of selected line
show_plot    = true
save_plot    = false
detrend_data = false

Fig1 = plot_mag(xyz;ind,show_plot,save_plot,detrend_data,
            use_mags = [:mag_1_c])
display(Fig1)
print("按回车键结束...")
readline() # 等待用户输入，防止程序直接退出导致绘图窗口关闭