#=
Press alt+j + alt+o for starting repl
Press ctrl+d to restart REPL
=#  

# Import stuff
using Revise
using Gadfly, JLD, Statistics, DataFrames

# Load data 
filepath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\exp";
scriptpath= raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition";
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

#v= Vector{Union{Nothing, String}}(nothing, 10);

# create vectors for labels
p= ["plus" for x= 1:10];
m= ["minus" for x= 1:10];
g= [["exp" for x=1:5]; ["con" for x=1:5]];

# create a big matrix
dfPlus= [miceList dfPlus p g];
dfMinus= [miceList dfMinus m g];
df= [dfPlus; dfMinus];

# transform the matrix in a dataframe with all the labels
colName= ["subject", "day1", "day2", "day3", "day4", "day5", "day6", "day7", "day8", "day9", "type", "group"];
dataframe= DataFrame(df, colName);
df= stack(dataframe, Not([:subject, :type, :group]));

# eventually for filtering
plus= filter(type ->  type.type=="plus", df);
minus= filter(type ->  type.type=="minus", df);

# Plotting 
include(scriptpath*"\\themeSpec.jl")
Gadfly.set_default_plot_size(1920px, 1080px);

pPlus= plot(plus, x= :variable, y= :value, color=:group, Geom.boxplot,
            Guide.ylabel("Trials with aLicks"), Guide.xlabel(""), Guide.title("Plus trials"));
pMinus= plot(minus, x= :variable, y= :value, color=:group, Geom.boxplot, 
             Coord.cartesian(ymin=0, ymax=100),
             Guide.ylabel("Trials with aLicks"), Guide.xlabel(""), Guide.title("Minus trials"));
hstack(pPlus, pMinus)
