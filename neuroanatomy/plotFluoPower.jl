# Import stuff
using Revise
using JLD, Plots, Peaks, RollingFunctions

# Load data 
dataPath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Neuroanatomy\CTB PFC+Nac\WT60";
cd(dataPath);
data= load("df_wt60.jld");

# Normalize data 
dapi= data["Dapi"];
green= data["Green"];
red= data["Red"];

dapiNorm= dapi[:,2]./maximum(dapi[:,2]);
greenNorm= green[:,2]./maximum(green[:,2]);
redNorm= red[:,2]./maximum(red[:,2]);

# Plot
gr();
p= plot(dapi[:,1], dapiNorm, label="Dapi", title= "Raw data")
plot!(p, green[:,1], greenNorm, color=:green, label="PFC neurons")
plot!(p, red[:,1], redNorm, color=:red, label="Nac neurons")
xaxis!(p, xlabel= "Distance \\mum");
yaxis!(p, ylabel= "Normalized fluorescence");

#scatter!(p, a[1], a[2], msc= :red)

# Try to smooth the signal and find maxima
windSize= 20; 
dapiSmooth= rollmean(dapiNorm, windSize);
greenSmooth= rollmean(greenNorm, windSize);
redSmooth= rollmean(redNorm, windSize);

pS= plot(dapiSmooth, label= "Dapi", title= "Smoothed data")
plot!(pS, greenSmooth, color=:green, label= "PFC neurons")
plot!(pS, redSmooth, color=:red, label= "Nac neurons")
xaxis!(pS, xlabel= "Distance \\mum")
yaxis!(pS, ylabel= "Normalized fluorescence")


# Find peaks 
greenPeaks= findmaxima(greenSmooth);
scatter!(pS, greenPeaks, msc=:green)