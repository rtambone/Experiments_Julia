# Import stuff
using Revise
using StatsPlots, JLD, Statistics, DataFrames
using NaNMath; nm= NaNMath;

# Load data 
filepath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\exp";
scriptpath= raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition";
plotpath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\plots\julia\correctedResp";
cd(filepath);
data= load("allData.jld");

# Variable initiazilation 
miceList= ["PV92","PV94","PV100","PV104","PV107","WT58","WT96","WT97","WT98","WT101"];
infBound= 10;
supBound= 11; 
df= zeros(10,6);

#trialWin= [1,30];
#trialWin= [60, 90];
trialWin= [120, 150];

outliers= [];

# Preprocessing 
for mouse in 1:10
    mName= miceList[mouse]
    for day in 1:6
        trialTypes= data[mName][day]["TrialTypes"];
        trialData= data[mName][day]["RawEvents"]["Trial"];
        trialTypes= convert(Array{Int}, trialTypes);
        nTrialPlus= size(filter(x -> x==2, trialTypes[1:20]),1);
        nTrialMinus= size(filter(x -> x==1, trialTypes[1:20]),1);
        if length(trialTypes) < trialWin[2]
            println("Mouse: ", mouse)
            println("Session: ", day)
            push!(outliers, [mouse, day]);
            continue
        end
        correct= 0;
        wrong= 0; 
        for trial in trialWin[1]:trialWin[2]
            if haskey(trialData[trial]["Events"], "Port1In")
                licks= trialData[trial]["Events"]["Port1In"];
                if any(i -> (infBound<i<supBound), licks)
                    trialTypes[trial]==1 ? wrong+=1 : correct+=1
                end
            else
                if trialTypes[trial]==1
                    correct+=1;
                end
            end
        end
        #correctCSminus= nTrialMinus - wrong; 
        correctP= correct/30*100; 
        df[mouse, day]= correctP;
    end
end


# Compute mean and std 
mD= Array{Float64}(undef, 6, 2);
sD= Array{Float64}(undef, 6, 2);
for i=1:6
    m1= nm.mean(df[1:5,i]);
    m2= nm.mean(df[6:10,i]);
    s1= nm.std(df[1:5,i]);
    s2= nm.std(df[6:10,i]);
    mD[i,1]= m1;
    mD[i,2]= m2;
    sD[i,1]= s1;
    sD[i,2]= s2;
end

# Plot 
labels= ["Experimental" "Control"];
p= plot(mD, yerr= sD, label= labels, lw=2, marker=:circle, msc=:auto, msw=2, ylims=(0,100))
xaxis!(p, xlabel="Session", xticks=1:6);
yaxis!(p, ylabel= "% correct trials");
savefig(p, plotpath*"\\correctTrials_last.png")
