using Revise
using StatsPlots, JLD, Statistics, DataFrames
include(raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition\funcLicks.jl")

# Load data 
filepath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\exp";
scriptpath= raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition";
plotpath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\plots\julia\frequency";
cd(filepath);
data= load("allData.jld");

miceList= ["PV92","PV94","PV100","PV104","PV107","WT58","WT96","WT97","WT98","WT101"];
wind= [(0, 4), (4, 5), (5, 7), (7, 8), (8, 10), (10,11)];
windLabel= ["Baseline", "LaserOn", "Stimulus", "PostStimulus", "LaserOff", "Led"];

# create vectors for labels
p= ["CS+" for x= 1:10];
m= ["CS-" for x= 1:10];
g= [["Experimental" for x=1:5]; ["Control" for x=1:5]];
colName= windLabel; 
pushfirst!(colName, "subject");
push!(colName, "group");



# Preprocessing 
for day in 1:6
    sessionPlus= zeros(length(miceList),length(wind));
    sessionMinus= zeros(length(miceList),length(wind));
    for mouse in 1:10
        mName= miceList[mouse]
        trialTypes= data[mName][day]["TrialTypes"];
        trialData= data[mName][day]["RawEvents"]["Trial"];
        nTrial= size(trialTypes,2);
        trialTypes= convert(Array{Int}, trialTypes);
        nTrialPlus= size(filter(x -> x==2, trialTypes),1);
        nTrialMinus= size(filter(x -> x==1, trialTypes),1);
        freqPlus= zeros(nTrial, length(wind));
        freqMinus= zeros(nTrial, length(wind)); 
        for trial in 1:nTrial
            if haskey(trialData[trial]["Events"], "Port1In")
                licks= trialData[trial]["Events"]["Port1In"];
                for w=1:length(wind)
                    f= licksFreq(licks, wind[w]); 
                    if trialTypes[trial]==1
                        freqMinus[trial, w]= f;
                    elseif trialTypes[trial]==2
                        freqPlus[trial, w]= f; 
                    end
                end
            end
        end
        meanPlus= mean(freqPlus, dims=1);
        meanMinus= mean(freqMinus, dims=1);
        sessionPlus[mouse, :]= meanPlus; 
        sessionMinus[mouse, :]= meanMinus;
    end
    dfPlus= [miceList sessionPlus g];
    dfMinus= [miceList sessionMinus g];
    dataframeP= DataFrame(dfPlus, colName);
    dataframeM= DataFrame(dfMinus, colName);
    dPlus= stack(dataframeP, Not([:subject, :group]));
    dMinus= stack(dataframeM, Not([:subject, :group]));
    @df dPlus groupedboxplot(:variable, :value, group=:group ,msc=:auto, outliers= false, 
                            ylims=(-0.05,2), ylabel= "Hz", xtickfontsize= 10, title="Session $day");
    savefig(plotpath*"\\day$(day)plus.png")
    @df dMinus groupedboxplot(:variable, :value, group=:group ,msc=:auto, outliers= false, 
                            ylims=(-0.05,2), ylabel= "Hz", xtickfontsize= 10, title="Session $day");                        
    savefig(plotpath*"\\day$(day)minus.png")
    println("Day $day plots saved")
end
