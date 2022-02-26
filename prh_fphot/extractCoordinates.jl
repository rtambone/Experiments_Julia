using Revise 
using DataFrames, CSV, Gtk, JLD

genDir= raw"C:\Users\ricca\Documents\Iurilli Lab\Experiments\PRh_phot";
cd(genDir);
# Choose the file (.csv)
fname= open_dialog_native("File Dialog");
data= CSV.File(fname, header= 2:3) |> DataFrame;

# Take the input bodypart interested in 
bodypart= Gtk.input_dialog("Insert the bodypart interested id", "");
bpVec= split(bodypart, ", ");

#bodypart= "nose";

# Extract data 
allData= Dict();
columns= ["x", "y", "likelihood"];
l= size(data[!,1],1);
for b=1:size(bpVec, 1) 
    bp= bpVec[b];
    m= Array{Float64, 2}(undef, l,3);
    for i=1:3
        c= columns[i];
        name= string("$bp", "_", "$c");
        v= data[!, name];
        m[:,i]= v; 
    end
    allData[bp]= m; 
end

cd()
save("extractedCoordinates.jld, allData")