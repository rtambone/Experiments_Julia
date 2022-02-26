# Import stuff
using Revise
using StatsPlots, JLD, Statistics, DataFrames
include(raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition\funcLicks.jl");

# Load data 
filepath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\exp";
scriptpath= raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition";
plotpath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\plots\julia\cumCorrected";
cd(filepath);
data= load("allData.jld");

# Variable initiazilation 
miceList= ["PV92","PV94","PV100","PV104","PV107","WT58","WT96","WT97","WT98","WT101"];
infBound= 10;
supBound= 11; 

# Preprocessing 
for day in 1:6
    println("Processing session: ", day)
    df= Array{Union{Missing, Float64}}(missing, length(miceList), 149);
    for mouse in 1:10
        mName= miceList[mouse];
        println("Mouse : ", mName)
        trialTypes= data[mName][day]["TrialTypes"];
        trialData= data[mName][day]["RawEvents"]["Trial"];
        nTrial= length(trialData);
        #nTrial= 20;
        trialTypes= convert(Array{Int}, trialTypes);
        tt= vec(trialTypes); 
        nTrialPlus= size(filter(x -> x==2, trialTypes[1:20]),1);
        nTrialMinus= size(filter(x -> x==1, trialTypes[1:20]),1);
        idxs= collect(range(1,nTrial, step=1));
        correct= zeros(nTrial);
        for trial in 1:nTrial
            if haskey(trialData[trial]["Events"], "Port1In")
                licks= trialData[trial]["Events"]["Port1In"];
                if any(i -> (infBound<i<supBound), licks)
                    if trialTypes[trial]==2
                        correct[trial]= 1;
                    end
                else
                    if trialTypes[trial]==1
                        correct[trial]=1; 
                    end
                end
            else 
                if trialTypes[trial]==1
                    correct[trial]= 1; 
                end
            end
        end
        #---------------------------#
        println("Analyzing corrected responses ...")
        cumCorr=zeros(nTrial-1);
        for trial in 1:nTrial-1
            cumCorr[trial]= sum(correct[1:trial+1])/length(correct[1:trial+1])*100;
        end

        df[mouse,1:length(cumCorr)]= cumCorr;
    end # cycled all mouse
    
    println("Cycled all mice, analyzing session data ...")
    exp= df[1:5,:];
    con= df[6:10,:];
    if any(ismissing.(con))
        dfp= DataFrame(con, :auto);
        dfp= dropmissing(dfp); 
        con= Matrix(dfp); 
    end
    if any(ismissing.(exp))
        dfp= DataFrame(exp, :auto);
        dfp= dropmissing(dfp); 
        exp= Matrix(dfp); 
    end

    mExp= vec(mean(exp, dims=1));
    mCon= vec(mean(con, dims=1)); 
    stdExp= vec(std(exp, dims=1));
    stdCon= vec(std(con, dims=1)); 

    # Plotting 
    default(dpi=300);
    p= plot([mExp mCon], labels=["Experimental" "Control"], ribbon= ([stdExp stdCon]), 
            legend= :topright, ylims=(0,100), lw=2.5);
    hline!([50], line= (:dash, :black), labels=false);
    xlabel!("# trial");
    ylabel!("% correct responses");
    title!("Session "*string(day));
    savefig(plotpath*"\\s"*string(day)*".png")
    println("Plot saved")
end