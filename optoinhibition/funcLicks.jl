# Define function to compute licks frequency
function licksFreq(timestamps, timeWindow)
    count=0
    winLen= timeWindow[2] - timeWindow[1]
    for e in timestamps
        if timeWindow[1]<e<timeWindow[2]
            count+=1
        end
    end
    freq= count/winLen
    return  freq
end


function getPSTH(data::Vector, sigma::Number, timeWindow::Vector; errorType= "bootstrap", adaptiveWarp= false)
    nTrials= size(data)[1]; # NT
    nLicks= 0;              # N_tot
    ND= zeros(nTrials);
    for i in 1:nTrials
        trialLicks= length(data[i]);
        ND[i]= trialLicks;
        nLicks= nLicks+trialLicks;
    end
    ND= convert(Vector{Int64}, ND);

    # if kernel density is such that there are on avarate one ore less 
    # spikes under the kernel, then the units are probably wrong 
    winDuration= timeWindow[2]-timeWindow[1];
    L= nLicks/(nTrials*winDuration);
    if 2*L*nTrials*sigma < 1 || L<1 
        println("Timestamps very low density")
    end

    # Smear each lick out 
    # Std is sqrt(rate*(integral over kernel^2)/trials) 
    # for gaussian integral over kernel^2 is 1/(2*sig*sqrt(pi))
    N_pts= round(Int, 5*(winDuration/sigma));
    t= collect(LinRange(timeWindow[1], timeWindow[2], N_pts));

    RR= zeros(nTrial, N_pts);
    f= 1/(2*sigma^2);
    for r in 1:nTrials
        for l in 1:ND[r]
            q= -f*(t.-data[r][l]).^2;
            @. RR[r,:]= RR[r,:] + Base.exp(q);
        end
    end
    RR= RR*(1/sqrt(2*pi*sigma^2));
    R= mean(RR, dims=1); 
    R= vec(R);

    # Compute error 
    """
    if errorType== "poisson"
        E= sqrt(R/2*nTrials*sigma*sqrt(pi));
    elseif errorType== "bootstrap"
        nBoot= 1000; 
        mE= 0; 
        sE= 0; 
        idxs= collect(range(1,nTrials,step=1));
        for b in 1:nBoot
            idx= shuffle(idxs);
            mtmp= mean(RR[idx,:]);
            mE= mE+mtmp;
            sE= sE+mtmp^2;
        end
        E= sqrt((sE/nBoot - mE^2/nBoot^2));
    end
    """
    return t, R
end

function runningPercent(data::Array, window::Int64)
    nt= length(data); 
    percentage= zeros(nt);
    for i in 1:(nt-window)
        corr= sum(data[i:i+window]);
        percent= corr/window*100; 
        percentage[i]= percent 
    end
    #percentage[(nt-window):end]= 
    return percentage
end

function findNearest(array::AbstractArray, value::Number)
    diff= abs.(.-(array, value));
    minV= findmin(diff)[1];
    minIdx= findmin(diff)[2];
    #r= findmin(diff);
    return minV, minIdx
end








