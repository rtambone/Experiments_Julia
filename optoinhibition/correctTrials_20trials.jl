# Import stuff
using Revise
using StatsPlots, JLD, Statistics, DataFrames

# Load data 
filepath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\exp";
scriptpath= raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition";
plotpath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\plots\julia";
cd(filepath);
data= load("allData.jld");

# Variable initiazilation 
miceList= ["PV92","PV94","PV100","PV104","PV107","WT58","WT96","WT97","WT98","WT101"];
infBound= 10;
supBound= 11; 
df= zeros(10,6);

# Preprocessing 
for mouse in 1:10
    mName= miceList[mouse]
    for day in 1:6
        trialTypes= data[mName][day]["TrialTypes"];
        trialData= data[mName][day]["RawEvents"]["Trial"];
        #nTrial= length(trialData);
        nTrial= 20;
        trialTypes= convert(Array{Int}, trialTypes);
        nTrialPlus= size(filter(x -> x==2, trialTypes[1:20]),1);
        nTrialMinus= size(filter(x -> x==1, trialTypes[1:20]),1);
        correct= 0;
        wrong= 0; 
        for trial in 1:nTrial
            if haskey(trialData[trial]["Events"], "Port1In")
                licks= trialData[trial]["Events"]["Port1In"];
                if any(i -> (infBound<i<supBound), licks)
                    trialTypes[trial]==1 ? wrong+=1 : correct+=1
                end
            end
        end
        correctCSminus= nTrialMinus - wrong; 
        correctP= (correct+correctCSminus)/nTrial*100; 
        df[mouse, day]= correctP;
    end
end


# Compute mean and std 
meanD= [mean(df[1:5,:], dims=1); mean(df[6:10,:], dims=1)];
meanD= transpose(meanD);
stdD= [std(df[1:5, :], dims=1); std(df[6:10, :], dims=1)];
stdD= transpose(stdD);
# Plot 
labels= ["Experimental" "Control"];
p= plot(meanD, yerr= stdD, label= labels, lw=2, marker=:circle, msc=:auto, msw=2)
xaxis!(p, xlabel="Session", xticks=1:6);
yaxis!(p, ylabel= "% correct trials");
savefig(p, plotpath*"\\correctTrials_20trials.png")
