using Plots: get_markerstrokecolor
#=
Press alt+j + alt+o for starting repl
Press ctrl+d to restart REPL
=#  

# Import stuff
using Revise
using JLD, Statistics, Plots
import StatsBase: sem

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
        trialTypes= convert(Matrix{Int64}, trialTypes);
        trialData= data[mName][day]["RawEvents"]["Trial"];
        minusT= trialTypes.==1;
        plusT= trialTypes.==2;
        nTrial= size(trialTypes,2);
        nTrialPlus= size(plusT, 2);
        nTrialMinus= size(minusT, 2);
        hits= 0;
        fa= 0; 
        for trial in 1:nTrial
            if haskey(trialData[trial]["Events"], "Port1In")
                licks= trialData[trial]["Events"]["Port1In"];
                if any(i -> (infBound<i<supBound), licks)
                    if trialTypes[trial]==1
                        fa+=1; 
                    elseif trialTypes[trial]==2
                        hits+=1;
                    end
                end
            end
        end
        ls= (hits-fa);
        df[mouse, day]= ls; 
    end
end

# Plot
meanData= [mean(df[1:5,:], dims=1); mean(df[6:10,:], dims=1)];
stdData= [std(df[1:5,:], dims=1); std(df[6:10,:], dims=1)];
#semData= stdData./5;
meanData= transpose(meanData);
stdData= transpose(stdData);
labels= ["Experimental" "Control"];

gr();   # set backend
p1= plot(meanData, yerr= stdData, label=labels, lw=2, marker=:circle, msc=:auto, msw=2);
xaxis!(p1, xlabel="Session", xticks=1:6);
yaxis!(p1, ylabel= "\$ \\sum hits - false alarms \$")


savefig(p1, plotpath*"\\learning_scores.png")