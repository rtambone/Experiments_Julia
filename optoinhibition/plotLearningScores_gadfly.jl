#=
Press alt+j + alt+o for starting repl
Press ctrl+d to restart REPL
=#  

# Import stuff
using Revise
using Gadfly, JLD, Statistics, Plots

# Load data 
filepath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\exp";
scriptpath= raw"C:\Users\ricca\Documents\Scripts\julia\optoinhibition";
cd(filepath);
data= load("allData.jld");

# Variable initiazilation 
miceList= ["PV92","PV94","PV100","PV104","PV107","WT58","WT96","WT97","WT98","WT101"];
infBound= 10;
supBound= 11; 
df= zeros(10,9);

# Preprocessing 
for mouse in 1:10
    mName= miceList[mouse]
    for day in 1:9
        trialTypes= data[mName][day]["TrialTypes"];
        trialData= data[mName][day]["RawEvents"]["Trial"];
        nTrial= size(trialTypes,2);
        hits= 0;
        fa= 0; 
        for trial in 1:nTrial
            if haskey(trialData[trial]["Events"], "Port1In")
                licks= trialData[trial]["Events"]["Port1In"];
                if any(i -> (infBound<i<supBound), licks)
                    trialTypes[trial]==1 ? fa+=1 : hits+=1
                end
            end
        end
        ls= (hits-fa)/(nTrial/2);
        df[mouse, day]= ls; 
    end
end

# Plot
meanData= [mean(df[1:5,:], dims=1); mean(df[6:10,:], dims=1)];
stdData= [std(df[1:5,:], dims=1); std(df[6:10,:], dims=1)];
yMin= meanData - stdData;
yMax= meanData + stdData;

include(scriptpath*"\\themeSpec.jl")
Gadfly.set_default_plot_size(1920px, 1080px);

p= plot(x=1:9, y=meanData[1,:], Geom.point, Geom.line, color=[:Experimental], 
        layer(x=1:9, y=meanData[2,:], Geom.point, Geom.line, color=[:Control]),
        layer(x=1:9, ymin= yMin[1,:], ymax= yMax[1,:], Geom.errorbar),
        layer(x=1:9, ymin= yMin[2,:], ymax= yMax[2,:], Geom.errorbar, color=[:Control]),
        Guide.xticks(ticks=1:9),
        Guide.xlabel("Session"), Guide.ylabel("Learning scores"),
        Guide.colorkey(title="", pos=[8,1.2]))

draw(PNG("test.png"),p)