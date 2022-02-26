using Revise
using StatsPlots, JLD, Statistics, DataFrames
include(raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition\funcLicks.jl")

# Load data 
filepath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\exp";
scriptpath= raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition";
plotpath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\plots\julia";
cd(filepath);
data= load("allData.jld");

# Variable initiazilation 
miceList= ["PV92","PV94","PV100","PV104","PV107","WT58","WT96","WT97","WT98","WT101"];
dfPlus= zeros(10,6);
dfMinus= zeros(10,6);

# Preprocessing 
psth1= [];
psth2= [];
t_all= [];
sigma= 0.1;
timeWind= [-1, 25];

for mouse in 1:10
    mName= miceList[mouse];
    for day in 1:3
        trialTypes= data[mName][day]["TrialTypes"];
        trialData= data[mName][day]["RawEvents"]["Trial"];
        nTrial= 20;
        trialTypes= convert(Array{Int}, trialTypes);
        nTrialPlus= size(filter(x -> x==2, trialTypes[1:20]),1);
        nTrialMinus= size(filter(x -> x==1, trialTypes[1:20]),1);
        licksXtrial1= [];
        licksXtrial2= [];
        for trial in 1:nTrial
            if haskey(trialData[trial]["Events"], "Port1In")
                licks= trialData[trial]["Events"]["Port1In"]
                if trialTypes[trial]== 1
                    push!(licksXtrial1, licks)
                elseif trialTypes[trial]==2
                    push!(licksXtrial2, licks)
                end
            end
        end
        t, R1= getPSTH(licksXtrial1, sigma, timeWind);
        t, R2= getPSTH(licksXtrial2, sigma, timeWind); 
        #data= [R1 R2]; 
        push!(psth1, R1); 
        push!(psth2, R2);
    end
end
