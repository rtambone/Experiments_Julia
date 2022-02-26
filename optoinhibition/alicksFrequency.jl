using Revise
using StatsPlots, JLD, Statistics, DataFrames
include(raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition\funcLicks.jl")

# Load data 
filepath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\exp";
scriptpath= raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition";
plotpath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\plots\julia";
cd(filepath);
data= load("allData.jld");

miceList= ["PV92","PV94","PV100","PV104","PV107","WT58","WT96","WT97","WT98","WT101"];
wind= [10, 11]; 
dfPlus= zeros(10,6);
dfMinus= zeros(10,6);

# Preprocessing 
for day in 1:6
    for mouse in 1:10
        mName= miceList[mouse]
        trialTypes= data[mName][day]["TrialTypes"];
        trialData= data[mName][day]["RawEvents"]["Trial"];
        nTrial= size(trialTypes,2);
        trialTypes= convert(Array{Int}, trialTypes);
        freqPlus= zeros(nTrial);
        freqMinus= zeros(nTrial); 
        for trial in 1:nTrial
            if haskey(trialData[trial]["Events"], "Port1In")
                licks= trialData[trial]["Events"]["Port1In"];
                f= licksFreq(licks, wind); 
                if trialTypes[trial]==1
                    freqMinus[trial]= f;
                elseif trialTypes[trial]==2
                    freqPlus[trial]= f; 
                end
            end
        end
        meanPlus= mean(freqPlus);
        meanMinus= mean(freqMinus)
        dfPlus[mouse, day]= meanPlus; 
        dfMinus[mouse, day]= meanMinus;
    end
end


# create vectors for labels
p= ["CS+" for x= 1:10];
m= ["CS-" for x= 1:10];
g= [["Experimental" for x=1:5]; ["Control" for x=1:5]];

# create a big matrix
dfPlus= [miceList dfPlus p g];
dfMinus= [miceList dfMinus m g];
df= [dfPlus; dfMinus];

# transform the matrix in a dataframe with all the labels
colName= ["subject", "1", "2", "3", "4", "5", "6", "type", "group"];
dataframe= DataFrame(df, colName);
df= stack(dataframe, Not([:subject, :type, :group]));

# eventually for filtering
plus= filter(type ->  type.type=="CS+", df);
minus= filter(type ->  type.type=="CS-", df);

exp= filter(group -> group.group=="Experimental", df);
con= filter(group -> group.group=="Control", df);



# Plotting CS+ vs CS- 
p= @df exp groupedboxplot(:variable, :value, group= :type, msc=:auto, outliers= false, ylims=(-0.05,2))
ylabel!("Hz");
xlabel!("Session");
title!("Experimental group")
savefig(plotpath*"\\freqExp.png")


p= @df con groupedboxplot(:variable, :value, group= :type, msc=:auto, ylims=(-0.05,2), outliers= false)
ylabel!("Hz");
xlabel!("Session");
title!("Control group")

savefig(plotpath*"\\freqControl.png")