using Revise 
using DataFrames, StatsPlots
include(raw"C:\Users\ricca\Documents\Scripts\julia\prh_fphot\funcDefinition.jl");
include(raw"C:\Users\ricca\Documents\Scripts\julia\prh_fphot\Fphot.jl");

# Load data 
resProcessed= loadPreproccesData();
plotDir= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\PRh_phot\Tests\Batch2\mPFC\plots";
sf= 1000.0;       # sampling frequency, must be float 
sig= vec(resProcessed["rawSig"]);
iso= vec(resProcessed["rawIso"]);
ts= vec(resProcessed["ts"]);
plotData(ts, sig, iso, "GCaMP", "Isosbestic", title= "Raw sig")
savefig(plotDir*"\\rawSignal.png")

# Median filter 
sig= medianFilter(ts, sig, 5);
iso= medianFilter(ts, iso, 5);
plotData(ts, sig, iso, "GCaMP", "Isosbestic", title= "Median filter")
savefig(plotDir*"\\medianFilter.png")

# Denoise
cutOff= 10; 
denoisedSig= denoise(sig, sf, cutOff);
denoisedIso= denoise(iso, sf, cutOff);
plotData(ts, denoisedSig, denoisedIso,"GCaMP", "Isosbestic", title= "Denoised by Butterworth lowpass filter")
savefig(plotDir*"\\denoisedSignal.png")

# Debleach signal 
dsSig= debleachSignal(ts, denoisedSig, sf, 2);
dsIso= debleachSignal(ts, denoisedIso, sf, 2);
plotData(ts, dsSig, dsIso, "GCaMP", "Isosbestic", title= "Debleached signal (exponential fitting)")
savefig(plotDir*"\\debleachedSignal.png")

# Motion correction 
mcSig= motionCorrect(dsSig, dsIso);
plotData(ts, mcSig, dsSig, "Corrected", "Pre-correction", title= "Motion correction")
savefig(plotDir*"\\motionCorrection.png")

# DF over F
cutOff= 0.001; 
bF= baselineF(denoisedSig, sf, cutOff);
dfF= mcSig./bF;
plotData(ts, denoisedSig, bF, "denoised Signal", "baseline Fluorescence")
plot(ts, dfF*100, label= "DFoverF")
savefig(plotDir*"\\deltaFoverF.png")

