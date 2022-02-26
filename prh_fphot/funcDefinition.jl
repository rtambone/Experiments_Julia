# Import stuff
using JLD, MAT, Statistics, Loess, Gtk, StatsPlots

function loadPreproccesData()
    fname= open_dialog_native("File Dialog")

    # load data
    d= matread(fname);
    resDict= Dict();
    resDict["rawSig"]= d["s"]["rawSig1"];
    resDict["rawIso"]= d["s"]["rawSig2"];
    resDict["ts"]= d["s"]["ts"];
    resDict["syncIn"]= d["s"]["syncInTimes"];
    resDict["originalSF"]= d["s"]["dsSF"];

    # extract subject info 
    p= splitpath(fname);
    win= splitext(p[end])[1];
    mIdx= length(p) - 2; 
    mouse= p[mIdx];
    fileDir= splitdir(fname)[1];
    info= (mouse, win, fileDir);

    return resDict, info
end

function loadAlignedData()
    fname= open_dialog_native("Choose JLD file")
    d= JLD.load(fname);

    # extract subject info 
    p= splitpath(fname);
    win= splitext(p[end])[1];
    mIdx= length(p) - 2; 
    mouse= p[mIdx];
    return d, mouse
end

function extractData(fname)
    d= matread(fname);
    resDict= Dict();
    resDict["rawSig"]= d["s"]["rawVals1"];
    resDict["rawIso"]= d["s"]["rawVals2"];
    resDict["ts"]= d["s"]["dsTimes"];
    resDict["syncIn"]= d["s"]["syncInTimes"];
    resDict["correctedRaw"]= d["s"]["dsVals1"];
    resDict["correctedIso"]= d["s"]["dsVals2"];
    return resDict
end


function plotData(ts, sig1, sig2, label1::String, label2::String; title::String="")
    resolution= 300;
    p= Plots.plot(ts, sig1, label= label1, dpi=resolution, size=(1200,500))
    Plots.plot!(p, ts, sig2, label= label2, dpi=resolution);
    title!(title)
end


function downSample(data, samplingFrequency, group= nothing)
    if group=== nothing
        g= 10;
    else
        g= group;
    end
    l= size(data,1);
    v= collect(range(1, length=l));
    ts= v/samplingFrequency;
    DTs= ts[1:g:end];
    DFs= samplingFrequency/g;
    DSDeltaF=[];    
    for i= 1:g:l
        if i+g-1 > l 
            push!(DSDeltaF, median(data[i:l]));
        else
            push!(DSDeltaF, median(data[i:i+(g-1)]));
        end
    end
    DSSig= convert(Array{Float64,1},DSDeltaF);
    return DTs, DSSig, DFs
end   


function smoothLoess(timestamps, data, span)
    l= size(data,1);
    m= loess(timestamps, data, span=span, degree=1);
    p= Loess.predict(m, timestamps);
    return p 
end


function consecutive(f, A::AbstractVector)
    [ f(A[i+1], A[i]) for i = 1:length(A)-1 ]
end


function findNearest(array::AbstractArray, value::Float64)
    diff= abs.(.-(array, value));
    minV= findmin(diff)[1];
    minIdx= findmin(diff)[2];
    #r= findmin(diff);
    return minV, minIdx
end


"""
plotTheme = Theme(default_color= "red", 
                  point_size= 3mm,
                  line_width= 1mm,
                  line_style= [:solid],
                  panel_fill= "white",
                  panel_stroke= "black",      # border color of the main plot panel
                  panel_line_width= 0.3mm,        # border line width for main plot panel            # float in [0, 1]
                  background_color= "white",
                  grid_color= colorant"transparent",
                  key_title_font_size= 22pt,
                  key_label_font_size= 22pt,
                  key_title_color= "black",
                  minor_label_font_size= 20pt,
                  major_label_font_size= 22pt,
                  plot_padding= [2.0mm],
                  key_position=:inside)

function plotData(ts, sig, iso, label1::String, label2::String; title::String)
    #Gadfly.set_default_plot_size(1920px, 1080px);
    Gadfly.push_theme(plotTheme)
    p= Gadfly.plot(x=ts, y= sig, Geom.line, color=[label1],
                   layer(x=ts, y=iso, Geom.line, color=[label2]),
                   Guide.colorkey(title="", pos=[0.8w, -0.4h]),
                   Theme(background_color="white"),
                   Guide.xlabel("time (ms)"),
                   Guide.ylabel(nothing))
                   Guide.title("bla")
    display(p)
end
"""
