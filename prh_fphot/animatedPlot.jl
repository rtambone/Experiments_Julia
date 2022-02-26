using Revise 
using StatsPlots, StatsBase
include(raw"C:\Users\ricca\Documents\Scripts\julia\prh_fphot\funcDefinition.jl");
include(raw"C:\Users\ricca\Documents\Scripts\julia\prh_fphot\Fphot.jl");

session= "test2";

# Load and extract processed data
genDir= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\PRh_phot\SocialSignature";
d, mouse= loadAlignedData()     # in processedData folder
data= d[session]["aligned"];
t= data[:,1];
ydata= data[:,2];
sf= 60; 
normData= ydata./maximum(ydata);


win= 1; # seconds
plotWin= sf*win; 
axWin= sf*10;
p= plot(xlims=(0,axWin))

for i in range(1, length(zdata)-plotWin, step=plotWin)
    if t[i+plotWin] < axWin
        plot(t[i:i+plotWin], normData[i:i+plotWin])
    else
        xlims!(xlims(p)[1]+plotWin, xlims(p)[2]+plotWin)
        plot(t[i:i+plotWin], normData[i:i+plotWin])
    end
end




#---------- Plot ---------#
plotly()
gr()
default(legend=false, size=(1200,600), ticks= nothing, border= :none)
p= Plots.plot(data[:,1], data[:,2].*100, title="\$ \\frac {\\Delta F} {F} \$")
p= plot()

@gif for i in range(60, stop= length(data[:,1]), step=sf)
    plot(data[1:i,1], data[1:i,2].*100)
    end

