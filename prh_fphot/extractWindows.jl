using Revise 
using DataFrames, Plots, JLD
include(raw"C:\Users\ricca\Documents\Scripts\julia\prh_fphot\funcDefinition.jl");

plotDir= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\PRh_phot\Batch1\Day2\M117\plots";

# Load and extract processed data
resProcessed= loadPreproccesData();
rawSig= vec(resProcessed["rawSig"]);
rawIso= vec(resProcessed["rawIso"]);
ts= vec(resProcessed["ts"]);
correctedSig= vec(resProcessed["correctedRaw"]);
correctedIso= vec(resProcessed["correctedIso"]);
plotData(ts, rawSig, rawIso, "GCaMP", "Isosbestic", title= "Raw signals")
savefig(plotDir*"\\rawData.png");
plotData(ts, correctedSig, correctedIso,"GCaMP", "Isosbestic", title= "Photobleached-corrected");
savefig(plotDir*"\\debleachedData.png");

# Extract windows
syncIn= vec(resProcessed["syncIn"]);
diffSync= consecutive(-, syncIn);
plot(diffSync)

windows= Dict();
dataMat= [ts rawSig rawIso];
windNames= ["habituation", "food", "cagemate", "24-familiar", "novel"];
threshold= diffSync[diffSync.>25]

# It returns a dict with keys= videos and each video is a dict with keys data=[ts rawSig rawIso] and ttl= syncIn
idxs= [];
for i=1:4
    idx= findall(diffSync.==threshold[i])[1]; 
    push!(idxs, idx);
end
starts= pushfirst!(idxs.+1,1);
ends= push!(idxs, size(syncIn,1));
for video=1:5
    s= starts[video];
    e= ends[video];
    valS, indS= findNearest(ts, syncIn[s]);
    valE, indE= findNearest(ts, syncIn[e]);
    windows[windNames[video]]= Dict([("data",dataMat[indS:indE,:]), ("ttl",syncIn[s:e])]);
end

# Explore data and store plots
for i=1:5
    ts= windows[windNames[i]]["data"][:,1];
    sig= windows[windNames[i]]["data"][:,2];
    iso= windows[windNames[i]]["data"][:,3];
    display(plotData(ts, sig, iso, "GCaMP", "Isosbestic", title= windNames[i]))
    savefig(plotDir*"\\"*windNames[i]*".png")
end

# Store data 
fileDir= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\PRh_phot\Batch1\Day2\M117\extractedData";
name= "\\dataDivided.jld";
JLD.save(fileDir*name, windows)