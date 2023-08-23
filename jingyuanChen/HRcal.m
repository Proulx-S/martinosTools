function [hbi hrv_rmsd] = HRcal(cardtrigger,Nfrs,TR,wds,time0)
% [hr hrv_rmsd] = HRcal(cardtrigger,Nfrs,TR,wds,time0)
% calculate the heart rate variability, assuming cardtime starts at 0 
% input -- cardtrigger 
%       -- Nfrs,TR MR acquisition  
%       -- window to integrate data (s)
%       -- time0 the starting time point of first TR    

for ifr = 1:Nfrs
    hrtime(1) = max((time0+(ifr-1)*TR-wds/2), 0);  
    hrtime(2) = min((time0+(ifr-1)*TR+wds/2), (time0+(Nfrs-1)*TR)); 
    inwd = find((cardtrigger >= hrtime(1)) & (cardtrigger < hrtime(2))); 
    if length(inwd) == 1
       inwd = [inwd-1 inwd]; 
    end
%     hr(ifr) = length(inwd-1)/(cardtrigger(inwd(end))-cardtrigger(inwd(1)))*60;
    hbi(ifr) = mean(diff(cardtrigger(inwd)));
%     hr(ifr) = mean(1./diff(cardtrigger(inwd)))*60;
    hrv_rmsd(ifr) = sqrt(mean((1./diff(cardtrigger(inwd))).^2));  
end

% hr = hr(:) - nanmean(hr(:));  
% hrv_rmsd = hrv_rmsd(:) - nanmean(hrv_rmsd(:));  

end