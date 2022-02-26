# Import stuff
using Revise
using StatsPlots, JLD, Statistics, DataFrames, StatsBase
include(raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition\funcLicks.jl");

# Load data 
filepath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\exp";
scriptpath= raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition";
plotpath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\plots\julia\criterion";
cd(filepath);
data= load("allData.jld");

# Variable initiazilation 
miceList= ["PV92","PV94","PV100","PV104","PV107","WT58","WT96","WT97","WT98","WT101"];
infBound= 10;
supBound= 11; 

# Preprocessing 
df= Array{Float64}(undef, 10, 6);
for day in 1:6
    println("Processing session: ", day)
    for mouse in 1:10
        mName= miceList[mouse];
        println("Mouse : ", mName)
        trialTypes= data[mName][day]["TrialTypes"];
        trialData= data[mName][day]["RawEvents"]["Trial"];
        nTrial= length(trialData);
        trialTypes= convert(Array{Int}, trialTypes);
        tt= vec(trialTypes); 
        correct= zeros(nTrial);
        for trial in 1:nTrial
            if haskey(trialData[trial]["Events"], "Port1In")
                licks= trialData[trial]["Events"]["Port1In"];
                if trialTypes[trial]==1 # cs-
                    if any(i -> (infBound<i<supBound), licks)== false
                        correct[trial]= 1;
                    end
                elseif trialTypes[trial]==2 # cs+
                    if any(i -> (infBound<i<supBound), licks)
                        correct[trial]=1; 
                    end
                end
            else 
                if trialTypes[trial]==1
                    correct[trial]= 1; 
                end
            end
        end
        # Compute cumulative corrected trials
        cumCorr=zeros(nTrial);
        for trial in 1:nTrial
            cumCorr[trial]= sum(correct[1:trial])/trial;
        end
        idx= findfirst(cumCorr.>0.8);
        if typeof(idx)== Nothing
            df[mouse, day]= NaN;
        else
            if all(cumCorr[idx:idx+10].>0.8)
                df[mouse, day]= idx;
            else
                
                df[mouse, day]= NaN;
            end
        end
    end # cycled all mice
end     # cycled all sessions


# Plotting 
mice= ["PV92" "PV94" "PV100" "PV104" "PV107" "WT58" "WT96" "WT97" "WT98" "WT101"];
default(dpi=300)

groupedbar(df', bar_position= :dodge, bar_width=0.8, label= mice)
ylabel!("Trial to criterion")
vline!([1:6], line=(:dash, :black), legend=false)
savefig(plotpath*"\\trialToCrit_allMice.png")

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
    sD[i,1]= s1/length(s1);
    sD[i,2]= s2/length(s1);
end


groupedbar(mD, bar_position= :dodge, bar_width=0.8, label= ["Experimental" "Control"], 
            ylims=(-4,150), yerr= sD)
ylabel!("Trial to criterion")
savefig(plotpath*"\\trialToCrit_grouped.png")