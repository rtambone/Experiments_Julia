#=
Press alt+j + alt+o for starting repl
Press ctrl+d to restart REPL
=#  

# Import stuff
using Revise
using StatsPlots, JLD, Statistics, DataFrames, Gadfly, Compose, Cairo, Fontconfig

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
dfPlus= zeros(10);
dfMinus= zeros(10);

day= 4;
nTrial= 20;

# Preprocessing 
for mouse in 1:10
    mName= miceList[mouse]
    trialTypes= data[mName][day]["TrialTypes"];
    trialData= data[mName][day]["RawEvents"]["Trial"];
    trialTypes= convert(Array{Int}, trialTypes);
    nTrialPlus= size(filter(x -> x==2, trialTypes[1:20]),1);
    nTrialMinus= size(filter(x -> x==1, trialTypes[1:20]),1);
    alicksPlus= 0;
    alicksMinus= 0; 
    for trial in 1:20
        if haskey(trialData[trial]["Events"], "Port1In")
            licks= trialData[trial]["Events"]["Port1In"];
            if any(i -> (infBound<i<supBound), licks)
                trialTypes[trial]==1 ? alicksMinus+=1 : alicksPlus+=1
            end
        end
    end
    percentPlus= alicksPlus/nTrialPlus*100;
    percentMinus= alicksMinus/nTrialMinus*100;
    dfPlus[mouse]= percentPlus; 
    dfMinus[mouse]= percentMinus;
end



# create vectors for labels
p= ["Familiar" for x= 1:10];
m= ["Novel" for x= 1:10];
g= [["Experimental" for x=1:5]; ["Control" for x=1:5]];

# create a big matrix
dfPlus= [miceList dfPlus p g];
dfMinus= [miceList dfMinus m g];
df= [dfPlus; dfMinus];

# transform the matrix in a dataframe with all the labels
colName= ["subject", "variable", "type", "group"];
dataframe= DataFrame(df, colName);


#include(scriptpath*"\\themeSpec.jl")
#Gadfly.set_default_plot_size(1920px, 1080px);

plotTheme= Theme(background_color= "white",
                 panel_stroke= "black",
                 key_label_font_size= 16pt, 
                 major_label_font_size= 16pt,
                 minor_label_font_size= 16pt, 
                 key_label_color= "black",
                 major_label_color= "black",
                 minor_label_color="black")
Gadfly.push_theme(plotTheme)


p1= Gadfly.plot(dataframe, x= :group, y= :variable, color=:type, Geom.beeswarm,
                Scale.x_discrete(levels=["Experimental", "Control"]), 
                Guide.ylabel("Trials with aLicks"),
                Scale.color_discrete_manual("orange","blue"))
push!(p1, layer(x= :group, y= :variable, color= :type, Geom.boxplot))

draw(PNG(plotpath*"\\generalization.png"), pPlus)

p= @df dataframe groupedboxplot(:group, :variable, group= :type, outliers= false)
@df dataframe groupeddotplot!(:group, :variable, group= :type, label=false, color_palette=[:blue, :orange])
ylabel!("Trials with aLicks")
savefig(plotpath*"\\gt.png")
