using Revise 
using DataFrames, StatsPlots, Polynomials, StatsBase, LsqFit, DSP, GLM, JLD
include(raw"C:\Users\ricca\Documents\Scripts\julia\prh_fphot\funcDefinition.jl");
include(raw"C:\Users\ricca\Documents\Scripts\julia\prh_fphot\Fphot.jl");


gr()
#plotly()

plotDir= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\PRh_phot\Day2\M111\plots\fphot";
sf= 1000;       # sampling frequency

# Load and extract processed data
fileDir= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\PRh_phot\Day2\M111\extractedData";
data= JLD.load(fileDir*"\\dataDivided.jld")
win= "habituation";
mat= data[win]["data"];
ts= mat[:,1];
sig= mat[:,2];
iso= mat[:,3];
plotData(ts, sig, iso, "GCaMP", "Isosbestic")

# Denoise the signals ------------------------------------------------
# Median filter to remove electrical artifacts
filtSig= medfilt(ts, sig, 5);
filtIso= medfilt(ts, iso, 5);
plotData(ts, filtSig, filtIso, "GCaMP", "Isosbestic", title= "Median filter")
savefig(plotDir*"\\denoise.png")

# Lowpass filter with zero phase used to avoid distorting the signal
denoisedSig= denoise(filtSig, sf);
denoisedIso= denoise(filtIso, sf); 
plotData(ts, denoisedSig, denoisedIso, "GCaMP", "Isosbestic,", title= "Butterworth filter")
savefig(plotDir*"\\lowpassButter.png")


# Debleach the signal -----------------------------------------------
# Method 1= highpass filter signal with low cutoff freq (remove drift and slow physiological variations)
cutoffFreq= 0.001/(sf/2);
buttFilter= DSP.Filters.digitalfilter(Highpass(cutoffFreq), Butterworth(2));
filteredSig= filtfilt(buttFilter, filteredSig);
filteredIso= filtfilt(buttFilter, filteredIso);
plotData(ts, filteredSig, filteredIso, "GCaMP", "Isosbestic", title= "Debleach by highpass Butterworth filter")
savefig(plotDir*"\\debleachButter.png")

# Method 2= fit and exponential decay and subtract it from the signal 
@. model(data, params)= params[1]*exp(-params[2]*data)+params[3];
p0=[1,1e-3,1];  #bounds=([0,0,0],[4,0.1,4]), maxfev=1000)
fitParamsSig= LsqFit.curve_fit(model, ts, smoothSig, p0).param;
fitParamsIso= LsqFit.curve_fit(model, ts, smoothIso, p0).param;
sigFitting= model(smoothSig, fitParamsSig);
isoFitting= model(smoothIso, fitParamsIso);
fitSig= .-(smoothSig, sigFitting);
fitIso= .-(smoothIso, isoFitting);
plotData(ts, fitSig, fitIso, "GCaMP", "Isosbestic", title= "Debleach by exp fitting")
savefig(plotDir*"\\debleachExp.png")

# Method 3= low order polynomial fitting (more dof than method2, but less than method1) 
polySig= Polynomials.fit(ts, smoothSig, 4);
polyIso= Polynomials.fit(ts, smoothIso, 4);
fitSig= .-(smoothSig, polySig.(smoothSig));
fitIso=.-(smoothIso, polyIso.(smoothIso));
plotData(ts, fitSig, fitIso, "GCaMP", "Isosbestic", title= "Debleach by polynomial fit")
savefig(plotDir*"\\debleachPoly.png")


# Motion correction ----------------------------------------------
# fit of iso to signal and subtract this estimated motion component from signals
data= DataFrame(x= filteredSig, y= filteredIso);
ols= lm(@formula(y ~ x), data);
intercept, slope = coef(ols);
motionEst= intercept.+slope.*filteredIso;
mcSig= filteredSig .- motionEst;
plotData(ts, filteredSig, mcSig, "pre motion correction", "motion-corrected")
savefig(plotDir*"\\motionCorr1.png")
plotData(ts, mcSig, motionEst, "motion-corrected", "estimated motion")
savefig(plotDir*"\\motionCorrect2.png")


# DF/F ----------------------------------------------------------
buttFilter= DSP.Filters.digitalfilter(Lowpass(cutoffFreq), Butterworth(2)); # estimate F as a function of session time
baselineF= filtfilt(buttFilter, smoothSig);
dFoverF= mcSig./baselineF;
plot(ts, dFoverF.*100, title= win, legend= false);
yaxis!(ylabel="\$ \\frac {\\Delta F} {F} \$");
xaxis!(xlabel="time (ms)")