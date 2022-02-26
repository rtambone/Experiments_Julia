#=
Press alt+j + alt+o for starting repl
Press ctrl+d to restart REPL
=#  

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
dfPlus= zeros(10,9);
dfMinus= zeros(10,9);

# Preprocessing 
for mouse in 1:10
    mName= miceList[mouse]
    for day in 1:9
        trialTypes= data[mName][day]["TrialTypes"];
        trialData= data[mName][day]["RawEvents"]["Trial"];
        nTrial= size(trialTypes,2);
        trialTypes= convert(Array{Int}, trialTypes);
        nTrialPlus= size(filter(x -> x==2, trialTypes),1);
        nTrialMinus= size(filter(x -> x==1, trialTypes),1);
        alicksPlus= 0;
        alicksMinus= 0; 
        for trial in 1:nTrial
            if haskey(trialData[trial]["Events"], "Port1In")
                licks= trialData[trial]["Events"]["Port1In"];
                if any(i -> (infBound<i<supBound), licks)
                    trialTypes[trial]==1 ? alicksMinus+=1 : alicksPlus+=1
                end
            end
        end
        percentPlus= alicksPlus/nTrialPlus*100;
        percentMinus= alicksMinus/nTrialMinus*100;
        dfPlus[mouse, day]= percentPlus; 
        dfMinus[mouse, day]= percentMinus;
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
colName= ["subject", "1", "2", "3", "4", "5", "6", "7", "8", "9", "type", "group"];
dataframe= DataFrame(df, colName);
df= stack(dataframe, Not([:subject, :type, :group]));

# eventually for filtering
plus= filter(type ->  type.type=="CS+", df);
minus= filter(type ->  type.type=="CS-", df);

exp= filter(group -> group.group=="Experimental", df);
con= filter(group -> group.group=="Control", df);



# Plotting CS+ vs CS- 
p= @df exp groupedboxplot(:variable, :value, group= :type, msc=:auto, ylims=(-10, 100))
ylabel!("Trials with aLicks");
xlabel!("Session");
title!("Experimental group")
savefig(plotpath*"\\exp.png")


p= @df con groupedboxplot(:variable, :value, group= :type, msc=:auto, ylims=(-10, 100), legend=:topleft)
ylabel!("Trials with aLicks");
xlabel!("Session");
title!("Control group")

savefig(plotpath*"\\control.png")