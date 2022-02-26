# Press alt+j + alt+o for starting repl
# Press ctrl+d to restart REPL

# Import stuff
using MAT, Glob, JLD

# Load data
miceList= ["PV92","PV94","PV100","PV104","PV107","WT58","WT96","WT97","WT98","WT101"];
phases=["\\pavlovian\\","\\discrimination\\","\\reverse\\"];
filepath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Optoinhibition\optoinhibition\exp";

allData= Dict();
for mouse in 1:size(miceList,1)
    mName= miceList[mouse];
    for phase in 1:size(phases, 1)
        folder= filepath*phases[phase]*mName;
        files= glob("*.mat", folder);
        sessionData=[];
        for day in 1:3
            d= matread(files[day]);
            data= d["SessionData"];
            push!(sessionData, data);
        end
        if haskey(allData, mName)== false
            allData[mName]= []
        end
        append!(allData[mName], sessionData);
    end
end

# Save data in JLD format
cd(filepath)
save("allData.jld", allData)