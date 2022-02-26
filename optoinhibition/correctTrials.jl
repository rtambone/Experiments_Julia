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

# Preprocessing 
for mouse in 1:10
    mName= miceList[mouse]
    for day in 1:6
        trialTypes= data[mName][day]["TrialTypes"];
        trialData= data[mName][day]["RawEvents"]["Trial"];
        trialTypes= convert(Array{Int}, trialTypes);
        nTrialPlus= size(filter(x -> x==2, trialTypes),1);
        nTrialMinus= size(filter(x -> x==1, trialTypes),1);
        nTrials= length(trialTypes);
        correct= 0;
        wrong= 0; 
        for trial= 1:nTrials
            if trialTypes[trial]==1    
                # if licks but not alicks             
                if haskey(trialData[trial]["Events"], "Port1In")
                    licks= trialData[trial]["Events"]["Port1In"];
                    if any(i -> (infBound<i<supBound), licks)== false
                        correct+=1;
                    end
                # if there are no licks    
                else 
                    correct+=1; 
                end
            elseif trialTypes[trial]== 2
                if haskey(trialData[trial]["Events"], "Port1In")
                    licks= trialData[trial]["Events"]["Port1In"];
                    if any(i -> (infBound<i<supBound), licks)
                        correct+=1;
                    end
                end
            end
        end
        #correctCSminus= nTrialMinus - wrong; 
        correctP= correct/nTrials*100; 
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
savefig(p, plotpath*"\\correctTrials.png")

