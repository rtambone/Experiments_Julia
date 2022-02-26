# Import stuff
using Revise
using JLD, DataFrames, CSV, Glob, DelimitedFiles, GTK

dataPath= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\Neuroanatomy\CTB PFC+Nac\WT60";
cd(dataPath);
files= glob("*.csv", dataPath);
channels= ["Dapi", "Green", "Red"];

a=Dict();
for i in 1:size(files,1)
    d, h= readdlm(files[i],',',Float64, header=true);
    a[channels[i]]= d
end
save("df_wt60.jld", a)