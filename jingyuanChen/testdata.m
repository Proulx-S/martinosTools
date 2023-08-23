clear all, clc;  
% load the physiological signals 
phys = load('rfMRI_REST1_LR_Physio_log.txt');  
c = phys(:,3);  
fs = 400;  
t = [1:length(c)]/fs;  

% low-pass the PPG signal below 9 Hz (value used in Physio I/O demo, could be lower)
f_cutoff = 9; 
n = 100;  
b = fir1(n,f_cutoff/(fs/2));
c_fil = filtfilt(b,1,detrend(c(:),2));  

% detect peaks 
cpulse_detect_options.method = 'auto_matched';
cpulse_detect_options.max_heart_rate_bpm = 90;
cpulse_detect_options.file = 'initial_cpulse_kRpeakfile.mat';
cpulse_detect_options.min = 0.4;
cardiac_modality = 'PPU';  
verbose.level = 1;
[cpulse] = tapas_physio_get_cardiac_pulses(t, c, cpulse_detect_options, cardiac_modality, verbose);  
[cpulse_fil] = tapas_physio_get_cardiac_pulses(t, c_fil, cpulse_detect_options, cardiac_modality, verbose);  

% compare the results 
load phys_card.txt  % output from popp 
cpulse_popp = phys_card; 

figure,  
plot(t, c); hold on; 
plot(cpulse, c(fix(cpulse*fs)), 'r.', 'markersize', 10); hold on;  
plot(cpulse_fil, c(fix(cpulse_fil*fs)), 'm.', 'markersize', 10); hold on;  
plot(cpulse_popp, c(fix(cpulse_popp*fs)), 'g.', 'markersize', 10); hold on;  
legend({'raw signal', 'phsio I/O non-filtered', 'physio I/O filtered', 'FSL popp'}); 









