using Revise
using Gtk, CSV, DelimitedFiles, RollingFunctions, Plots, Loess


channels= ["Green", "Red"];
f1= open_dialog_native("File Dialog")
f2= open_dialog_native("File Dialog")

d1, h1= readdlm(f1,',',Float64, header=true);
d2, h2= readdlm(f2,',',Float64, header=true);
x1= d1[:,1];
x2= d2[:,1];

# Normalize data 
greenNorm= d1[:,2]./maximum(d1[:,2]);
redNorm= d2[:,2]./maximum(d2[:,2]);

# Smooth data 
function smoothLoess(timestamps, data, span)
    l= size(data,1);
    m= loess(timestamps, data, span=span, degree=1);
    p= Loess.predict(m, timestamps);
    return p 
end

green= smoothLoess(x1, greenNorm, 0.2);
red= smoothLoess(x2, redNorm, 0.2);

p= plot(x1, green, color=:green, label="PFC neurons", legend=:bottomright)
plot!(x2, red, color=:red, label="Nac neurons")
xaxis!(p, xlabel= "Distance \\mum")
yaxis!(p, ylabel= "Normalized fluorescence")

saveF= save_dialog_native("")
savefig(p, saveF)