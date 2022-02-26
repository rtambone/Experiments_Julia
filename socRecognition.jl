using Revise
using JLD, MAT, Statistics, Gtk, StatsPlots




prefix= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\SocRecog\Data";
miceList= ["1M", "2M", "3M", "4M"];
stimuli= ["Familiar", "Novel"];
reverseStimuli= ["Novel", "Familiar"];

dataM= Matrix(undef, 2,4);
for m in 1:4
    mouse= miceList[m];
    fname= open_dialog_native("Select file for mouse "*mouse);
    d= matread(fname);
    investigationTime1= d["log"]["totalInvestigationTime"]["stimulus1"];
    investigationTime2= d["log"]["totalInvestigationTime"]["stimulus2"];
    start= d["log"]["onsetRecording"];
    finish= d["log"]["endRecording"];
    duration= finish - start;
    t1= round((investigationTime1/duration)*100, digits=2);
    t2= round((investigationTime2/duration)*100, digits=2);
    if m==1 || m==2
        dataM[1,m]= t1;
        dataM[2,m]= t2;    
    else
        dataM[1,m]= t2;
        dataM[2,m]= t1;
    
    end
end

p= plot();
for i in 1:4
    plot!(p, stimuli, dataM[:,i], label= miceList[i],lw=2, marker=:circle, msc=:auto, msw=2)
    ylabel!("% investigation time")
end
display(p)
savefig(prefix*"\\investigationTime.png")




    npokes1= d["log"]["numberOfPokes"]["stimulus1"];
    npokes2= d["log"]["numberOfPokes"]["stimulus2"];
    onsets1= d["log"]["onsets"]["stimulus1"];
    onsets2= d["log"]["onsets"]["stimulus2"];
    elapsedtime1= d["log"]["logStimuliElapsedTimes"]["stimulus_1"];
    elapsedtime2= d["log"]["logStimuliElapsedTimes"]["stimulus_2"];

