function rv = RVTcalmodi(respwave,resptime,respfs,Nfrs,TR,wds,time0)
% function rv = RVTcalmodi(espwave,resptime,respfs,Nfrs,TR,wds,time0)  
% calculate the standard deviations of respwave across windows 
% input -- respwave (raw resp data) 
%       -- resptime (indicating the acquisition time)
%       -- respfs (sampling rate) 
%       -- Nfrs,TR MR acquisition  
%       -- window to integrate data (s)
%       -- time0 the starting time point of first TR    

for ifr = 1:Nfrs
    range(1) = max(round((time0+(ifr-1)*TR-resptime(1)-wds/2)*respfs), 1);  
    range(2) = min(round((time0+(ifr-1)*TR-resptime(1)+wds/2)*respfs), ... 
        length(resptime));     
    rv(ifr) = std(respwave(range(1):range(2)));  
end

% rv = rv(:) - nanmean(rv(:));  

end