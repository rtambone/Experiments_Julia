using Revise 
using DataFrames, CSV, JLD, HDF5
include(raw"C:\Users\ricca\Documents\Scripts\julia\prh_fphot\funcDefinition.jl");
include(raw"C:\Users\ricca\Documents\Scripts\julia\prh_fphot\Fphot.jl");


# Load and extract processed data
genDir= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\PRh_phot\Exp";

mouse= "1ticks";        # m111, m115, m117, pfc, 1ticks
files, mDir, fDir= loadData(mouse);
for f in files
    # extract data and information 
    folder= splitext(f)[1];
    println("Analyzing ", mouse, "\n Session: ", folder)
    plotDir= joinpath(mDir, "plots", folder);
    fname= joinpath(fDir, f);
    data= extractData(fname)

    ts= vec(data["ts"]);
    sig= vec(data["rawSig"]);
    iso= vec(data["rawIso"]);
    syncIn= vec(data["syncIn"]);

    println("Processing data")

    # Cut window
    diffSync= consecutive(-, syncIn);
    valS, indS= findNearest(ts, syncIn[1]);
    valE, indE= findNearest(ts, syncIn[end]);
    ts= ts[indS:indE];
    sig= sig[indS:indE];
    iso= iso[indS:indE];

    # Explore raw signal 
    plotData(ts, sig, iso, "GCaMP", "Isosbestic", title= "Raw Signal")
    savefig(joinpath(plotDir, "rawSig.png"))

    # Median filter 
    filtSig= medianFilter(ts, sig, 5);
    filtIso= medianFilter(ts, iso, 5);
    plotData(ts, filtSig, filtIso, "GCaMP", "Isosbestic", title= "Median filter")
    savefig(plotDir*"\\medianFilter.png")

    # Denoise
    cutOff= 10; 
    sf= 1000.0; # Hz
    denoisedSig= denoise(filtSig, sf, cutOff);
    denoisedIso= denoise(filtIso, sf, cutOff);
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
    cutOff= 0.5; 
    bF= baselineF(denoisedSig, sf, cutOff);
    dfF= mcSig./bF;

    plotData(ts, denoisedSig, bF, "denoised Signal", "baseline Fluorescence")
    savefig(plotDir*"\\baselineF.png")

    Plots.plot(ts, dfF.*100, legend= false, title= "\$ \\frac {\\Delta F} {F} \$")
    xaxis!(xlabel="time (s)")
    yaxis!(ylabel="% change")
    savefig(plotDir*"\\deltaFoverF.png")

    println("Data processed and plots saved")

    # Store data 
    fileName= mDir*"\\"*mouse*".jld";
    if isfile(fileName)
        file= jldopen(fileName, "r+")
        g= JLD.create_group(file, folder)
        g["FPhot"]= [ts dfF];
        g["synchIn"]= syncIn;
        close(file)
    else 
        file= jldopen(fileName, "w")
        g= JLD.create_group(file, folder)
        g["FPhot"]= [ts dfF];
        g["synchIn"]= syncIn;
        close(file)   
    end

    println("Data stored correctly")

end