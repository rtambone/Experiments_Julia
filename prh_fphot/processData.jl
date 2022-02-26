using Revise 
using DataFrames, StatsPlots, CSV, JLD, RollingFunctions, Measures
using StatsBase: percentile
include(raw"C:\Users\ricca\Documents\Scripts\julia\prh_fphot\funcDefinition.jl");
include(raw"C:\Users\ricca\Documents\Scripts\julia\prh_fphot\Fphot.jl");

# Load and extract processed data
genDir= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\PRh_phot\SocialSignature";

data, infos= loadPreproccesData()
mouse= infos[1];
folder= infos[2];
ts= vec(data["ts"]);
sig= vec(data["rawSig"]);
iso= vec(data["rawIso"]);
syncIn= vec(data["syncIn"]);
originalSF= data["sf"];
sf= 1/mean(consecutive(-,ts)); # compute the new sampling frequency 

plotDir= joinpath(genDir, "plots", mouse, folder);


#------- Start Preprocessing --------------#
println("Preprocessing data ...");
# Explore raw downsampled signal 
plotData(ts, sig, iso, "GCaMP", "Isosbestic", title= "Raw Signal")
savefig(plotDir*"\\rawSignal.png");

# Median filter 
sig= medianFilter(ts, sig, 5);
iso= medianFilter(ts, iso, 5);
plotData(ts, sig, iso, "GCaMP", "Isosbestic", title= "Median filter")
savefig(plotDir*"\\medianFilter.png");

# Denoise
cutOff= 10; 
denoisedSig= denoise(sig, sf, cutOff);
denoisedIso= denoise(iso, sf, cutOff);
#plotData(ts, denoisedSig, sig,"Filtered", "Raw", title= "Denoised by Butterworth lowpass filter")
#plotData(ts, denoisedSig, sig, "Denoised", "Raw")
plotData(ts, denoisedSig, denoisedIso,"GCaMP", "Isosbestic", title= "Denoised by Butterworth lowpass filter")
savefig(plotDir*"\\denoisedSignal.png");

# Debleach signal 
dsSig= debleachSignal(ts, denoisedSig, sf, "PolyFit");
dsIso= debleachSignal(ts, denoisedIso, sf, "PolyFit");
plotData(ts, dsSig, dsIso, "GCaMP", "Isosbestic", title= "Debleached signal (polynomial fitting)")
savefig(plotDir*"\\debleachedSignal.png");

# Motion correction 
mcSig= motionCorrect(dsSig, dsIso);
plotData(ts, mcSig, dsSig, "Corrected", "Pre-correction", title= "Motion correction")
savefig(plotDir*"\\motionCorrection.png");

# DF over F
baseFluoMethod= "percentile";       # It could be '"filter" or "percentile"
if baseFluoMethod== "filter"
    # --- Lowpass method --- #
    cutOff= 0.01; 
    bF= baselineF(denoisedSig, sf, cutOff);
    plotData(ts, denoisedSig, bF, "denoised Signal", "baseline Fluorescence")
elseif baseFluoMethod== "percentile"
    # --- Percentile method --- #
    windowSecond= 90;   
    winSize= convert(Int64, windowSecond/0.05);     # ts are every 0.05 sec
    bF= running10Percentile(denoisedSig, winSize);
    plotData(ts, denoisedSig, bF, "denoised Signal", "baseline Fluorescence")
end

dfF= mcSig./bF;
plot(ts, dfF.*100, legend= false, size=(1200, 600), margin= 5mm)
yaxis!(ylabel="% change");
xaxis!(xlabel="time (ms)");
title!("\$ \\frac {\\Delta F} {F} \$");
savefig(plotDir*"\\deltaFoverF.png");
println("Data preprocessed and plots saved");

# ---- Preprocessing pt2-------#
println("Cutting windows and aligning TTL");
# Cut window
#diffSync= consecutive(-, syncIn);
valS, indS= findNearest(ts, syncIn[1]);
valE, indE= findNearest(ts, syncIn[end]);
cutTs= ts[indS:indE];
cutDF= dfF[indS:indE];
#plot(ts, dfF.*100, legend= false, size=(1200, 600), margin= 5mm)

# Align TTL
alignedFluo= zeros(length(syncIn));
d= [cutTs cutDF];
for i=1:length(syncIn)
    if i < length(syncIn)
        v, idx= findNearest(d[:,1], syncIn[i]);
        v1, idx1= findNearest(d[:,1], syncIn[i+1]);
        if idx1 - idx == 1 
            alignedFluo[i]= d[idx,2]; 
        elseif idx1 - idx > 1
            alignedFluo[i]= mean(d[idx:idx1,2]);
        end    
    elseif i == length(syncIn)
        v, idx= findNearest(d[:,1], syncIn[i]);
        alignedFluo[i]= d[idx,2];
    end
end
println("TTL aligned");


# ------ Save data ------- # 
println("Saving JLD file");
alignedData= [syncIn alignedFluo];
uncutData= [ts dfF];
fPath= joinpath(genDir, "processedData");
fileName= joinpath(fPath, mouse*".jld")
if isfile(fileName)
    file= jldopen(fileName, "r+")
    g= JLD.create_group(file, folder)
    g["aligned"]= alignedData;
    g["uncut_preprocessed"]= uncutData;
    close(file)
else 
    file= jldopen(fileName, "w")
    g= JLD.create_group(file, folder)
    g["aligned"]= alignedData;
    g["uncut_preprocessed"]= uncutData;
    close(file)   
end
println("Data stored correctly")
