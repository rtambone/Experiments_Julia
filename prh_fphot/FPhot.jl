using DataFrames, Statistics, Loess, Polynomials, LsqFit, DSP, GLM 
include(raw"C:\Users\ricca\Documents\Scripts\julia\prh_fphot\funcDefinition.jl");

function medianFilter(inputRange::Array, inputSignal::Array, window::Int64)
    medianSignal::Array{Float64} = []
    for i in 1:length(inputRange)
        if length(inputRange) - (window + i - 1) < 0
            forward = inputSignal[i:end]
            wrap = inputSignal[1:abs(length(inputSignal) - (window + i - 1))]
            append!(medianSignal, median(vcat(forward, wrap)))
        else
            forward = inputSignal[i:(window + i - 1)]
            append!(medianSignal, median(forward))
        end
    end
    return medianSignal
end

function denoise(inputSignal::Vector{Float64}, samplingFrequency::Float64, cutOff)
    #cutoffFreq= cutOff/(samplingFrequency/2);
    buttFilt= DSP.Filters.digitalfilter(Lowpass(cutOff; fs=samplingFrequency), Butterworth(2));
    filteredSignal= filtfilt(buttFilt, inputSignal);
    return filteredSignal
end

function debleachSignal(timestamps::AbstractVector, inputSignal::AbstractVector, samplingFrequency::Number, method::String)
    if method=="HighpassFilter"
        #cutoffFreq= 0.001/(samplingFrequency/2);
        buttFilt= DSP.Filters.digitalfilter(Highpass(0.001; fs= samplingFrequency), Butterworth(2));
        dsSig= filtfilt(buttFilt, inputSignal);
    elseif method=="ExponentialFit"
        @. model(data, params)= params[1]*exp(-params[2]*data)+params[3];
        p0=[1,1e-3,1];  #bounds=([0,0,0],[4,0.1,4]), maxfev=1000)
        fitParamsSig= LsqFit.curve_fit(model, timestamps, inputSignal, p0).param;
        fitSig= model(inputSignal, fitParamsSig);
        dsSig= .-(inputSignal, fitSig);
    elseif method=="PolyFit"
        polySig= Polynomials.fit(timestamps, inputSignal,4);
        fitSig= polySig.(timestamps);
        dsSig= .-(inputSignal, fitSig);
        display(plotData(timestamps, inputSignal,fitSig, "Signal", "Fitted"))
    else 
        error("Method non existent")
    end
    return dsSig 
end

function motionCorrect(inputSignal::Array, controlSignal::Array)
    data= DataFrame(x= controlSignal, y= inputSignal);
    ols= lm(@formula(y ~ x), data);
    intercept, slope = coef(ols);
    motionEstimate= intercept.+slope.*controlSignal;
    mcSig= inputSignal .- motionEstimate;
    return mcSig
end

function baselineF(inputSignal::Array, samplingFrequency::Float64, cutOff)
    #cutoffFreq= 0.001/(samplingFrequency/2);
    buttFilter= DSP.Filters.digitalfilter(Lowpass(cutOff; fs= samplingFrequency), Butterworth(2)); # estimate F as a function of session time
    baselineF= filtfilt(buttFilter, inputSignal);
    #dfF= inputSignal./baselineF;
    return baselineF
end


function running10Percentile(input::AbstractArray, window::Int64)
    runP= zeros(length(input));
    for i= 1:length(input)
        if i < window
            runP[i]= percentile(input[begin:i], 10); 
        else
            runP[i]= percentile(input[i-window+1:i], 10);
        end
    end
    return runP
end

  
function decimate(x, r)
# Decimation reduces the original sampling rate of a sequence
# to a lower rate. It is the opposite of interpolation.
#
# The decimate function lowpass filters the input to guard
# against aliasing and downsamples the result.
#
#   y = decimate(x,r)
#
# Reduces the sampling rate of x, the input signal, by a factor
# of r. The decimated vector, y, is shortened by a factor of r
# so that length(y) = ceil(length(x)/r). By default, decimate
# uses a lowpass Chebyshev Type I IIR filter of order 8.
#
# Sometimes, the specified filter order produces passband
# distortion due to roundoff errors accumulated from the
# convolutions needed to create the transfer function. The filter
# order is automatically reduced when distortion causes the
# magnitude response at the cutoff frequency to differ from the
# ripple by more than 1E–6.

    nfilt = 8
    cutoff = .8 / r
    rip = 0.05  # dB

    function filtmag_db(b, a, f)
        # Find filter's magnitude response in decibels at given frequency.
        nb = length(b)
        na = length(a)
        top = dot(exp(-1im*[0:nb-1]*pi*f), b)
        bot = dot(exp(-1im*[0:na-1]*pi*f), a)
        20*log10(abs(top/bot))
    end

    function cheby1(n, r, wp)
        # Chebyshev Type I digital filter design.
        #
        #    b, a = cheby1(n, r, wp)
        #
        # Designs an nth order lowpass digital Chebyshev filter with
        # R decibels of peak-to-peak ripple in the passband.
        #
        # The function returns the filter coefficients in length
        # n+1 vectors b (numerator) and a (denominator).
        #
        # The passband-edge frequency wp must be 0.0 < wp < 1.0, with
        # 1.0 corresponding to half the sample rate.
        #
        #  Use r=0.5 as a starting point, if you are unsure about choosing r.
        h = digitalfilter(Lowpass(wp), Chebyshev1(n, r))
        tf = convert(PolynomialRatio, h)
        coefb(tf), coefa(tf)
      end    

    b, a = cheby1(nfilt, rip, cutoff)
    while all(b==0) || (abs(filtmag_db(b, a, cutoff)+rip)>1e-6)
        nfilt = nfilt - 1
        if nfilt == 0
            break
        end
        b, a = cheby1(nfilt, rip, cutoff)
    end
    y = filtfilt(PolynomialRatio(b, a), x)
    nd = length(x)
    nout = ceil(nd/r)
    nbeg = int(r - (r * nout - nd))
    y[nbeg:r:nd]
end


