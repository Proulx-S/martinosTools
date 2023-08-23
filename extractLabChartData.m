function [data,dataTime,sampleRate,tr,dataTrigTimes,dataChan,dataRun] = extractLabChartData(physioFile,mriFile,figFlag,segmentInd)
% Automatically extract cardiac, respiration and scanner triggers from
% LabChart data in matlab format, sorting out runs at the same time. The
% data type corresponding to each channel is automatically identified based
% on power spectra, and the appropriate data segment is selected as the
% longest, assuming all mri runs were acquired during a single long
% LabChart data segment. This latter behavior is overridden by specifying
% the segmentInd variable as input.

% By Sebastien Proulx (jsproulx@mgh.harvard.edu)
% 2023-08-21

if ~exist('segmentInd','var')
    segmentInd = [];
end
if ~exist('figFlag','var') || isempty(figFlag)
    figFlag = 1;
end
%% Load physio
physio = load(physioFile);
%% Load MRI info
mri = MRIread(mriFile,1);
tr = mri.tr/1000;
nframes = mri.nframes;
runDur = tr*nframes;
%% Identify segment
if figFlag>1; figure('WindowStyle','docked'); end
startTime = nan(size(physio.datastart,2),size(physio.datastart,1));
endTime = nan(size(physio.datastart,2),size(physio.datastart,1));
for chanInd = 1:size(physio.datastart,1)
    for segmentIndTmp = 1:size(physio.datastart,2)
        data = physio.data(physio.datastart(chanInd,segmentIndTmp):physio.dataend(chanInd,segmentIndTmp));
        Fs = physio.samplerate(chanInd,segmentIndTmp);
        if segmentIndTmp==1
            t = 0:1/Fs:length(data)/Fs-1/Fs;
            if figFlag>1; hPlotTmp(chanInd) = plot(t,data); hold on; end
        else
            t = tLast + 1/Fs + (0:1/Fs:length(data)/Fs-1/Fs);
            if figFlag>1; plot(t,data,'Color',hPlotTmp(chanInd).Color); end
        end
        tLast = t(end);
        startTime(segmentIndTmp,chanInd) = t(1);
        endTime(segmentIndTmp,chanInd) = t(end);
    end
end
x = [startTime(:,1); endTime(end,1)];
if figFlag>1
    plot(repmat(x',[2 1]),repmat(ylim',[1 length(x)]),'k','LineWidth',2);
    yLim = ylim;
    text(startTime(:,1),repmat(yLim(1),[length(startTime(:,1)) 1]),replace(fullfile('Segment',cellstr(num2str((1:size(physio.datastart,2))'))),filesep,' '),'Rotation',90,'VerticalAlignment','top','FontSize',20)
    xlabel('time (sec)')
    title('Select the appropriate segment')
end
%%% If unspecified, choose the longest segment
if isempty(segmentInd)
    [~,segmentInd] = max(endTime(:,1) - startTime(:,1));
end
if figFlag>1
    x = [startTime(segmentInd,1) endTime(segmentInd,1)];
    x = x([1 2 2 1 1]);
    y = ylim;
    y = y([1 1 2 2 1]);
    hPatch = patch(x,y,'k');
    uistack(hPatch,'bottom')
    set(hPatch,'FaceColor',[1 1 1].*0.9,'EdgeColor','none')

    legend([hPlotTmp hPatch],[replace(fullfile('Channel',cellstr(num2str((1:size(physio.datastart,1))'))),filesep,' '); {'selected segment'}])
end

%% Identify channels
if isempty(segmentInd)
    segmentInd = size(physio.datastart,2);
end
figure('WindowStyle','docked');
hTile = tiledlayout(2,1);
hTile.Padding = 'tight';
hTile.TileSpacing = 'tight';
ax1 = nexttile;
ax2 = nexttile;
n = physio.dataend(:,segmentInd) - physio.datastart(:,segmentInd) + 1;
if any(diff(n)); error('X'); end
physioSpec = nan(size(physio.datastart,1),n(1));
warning('off','MATLAB:polyfit:RepeatedPointsOrRescale')
clear hPlot1 hPlot2
for chanInd = 1:size(physio.datastart,1)
    axes(ax1);
    Fs = physio.samplerate(chanInd,segmentInd);
    curData = physio.data(physio.datastart(chanInd,segmentInd):physio.dataend(chanInd,segmentInd));
    t = 0:1/Fs:length(curData)/Fs-1/Fs;
    curData = curData - polyval(polyfit(t',curData',4),t')';
    curData = curData./max(curData);
    hPlot1(chanInd) = plot(t,curData); hold on
    axes(ax2);
    dFs = Fs/length(curData);
    f = linspace(0,Fs,length(curData));
    physioSpec(chanInd,:) = abs(fft(curData));
    hPlot2(chanInd) = plot(f,physioSpec(chanInd,:)); hold on
end
drawnow
axes(ax1)
yLim = ylim;
hText = text(t(physio.com(:,3)),ones(size(physio.com(:,3))).*yLim(1),physio.comtext,'Rotation',90);
xlabel('time(sec)')
axes(ax2)
xlabel('Hz')
title('Identify channels and runs')
drawnow
%%% specify frequency ranges
axes(ax2); yLim = ylim;
runFreq = [0 1/runDur]; plot(runFreq,[1 1].*mean(ylim),'k');
runPower = max(physioSpec(:,f>runFreq(1) & f<runFreq(2)),[],2);
cardFreq = [0.75 1.25]; plot(cardFreq,[1 1].*mean(yLim),'k');
cardPower = max(physioSpec(:,f>cardFreq(1) & f<cardFreq(2)),[],2);
respFreq = [0.1 0.5]; plot(respFreq,[1 1].*mean(yLim),'k');
respPower = max(physioSpec(:,f>respFreq(1) & f<respFreq(2)),[],2);
trFreq = [-0.5 0.5]+1/tr; hPlotFreq = plot(trFreq,[1 1].*mean(yLim),'k');
trPower = max(physioSpec(:,f>trFreq(1) & f<trFreq(2)),[],2);
xlim([0 trFreq(2)])
%%% identify based on maximum power at corresponding frequencies
%%%% trigger
[~,b1] = max(trPower); [~,b2] = max(runPower);
if b1==b2
    trigChanInd = b1;
else
    error('X');
end
%%%% cardiac
[~,cardChanInd] = max(cardPower);
%%%% respiration
[~,respChanInd] = max(respPower);
%%% set labels
if ~all(diff([trigChanInd cardChanInd respChanInd]))
    error('X')
end
chanLabel = {'trigger' 'cardiac' 'resp'}';
physio.titles1 = cell(size(chanLabel));
physio.titles1([trigChanInd cardChanInd respChanInd]) = chanLabel;

%% Sort runs
%%% Find trigger times
trigInd = ismember(physio.titles1,'trigger');
trigData = physio.data(physio.datastart(trigInd,segmentInd):physio.dataend(trigInd,segmentInd));
thresh = min(trigData)+range(trigData)/2;
trigTimes = diff(trigData>thresh); trigTimes(trigTimes<0) = 0; trigTimes = find(trigTimes)+1; trigTimes = t(trigTimes);
%%% Find candidate run start times
runStart = [trigTimes(1) trigTimes(find(diff(trigTimes)>tr*2)+1)];
%%% Keep runs with expected number of frames
runEnd = nan(size(runStart));
runFrames = nan(size(runStart));
for i = 1:length(runStart)
    indStart = find(runStart(i)==trigTimes);
    if indStart+nframes<=length(trigTimes)
        indEnd = indStart + find(diff(trigTimes(indStart:end))>tr*1.5,1) - 1;
    else
        indEnd = length(trigTimes);
    end
    runFrames(i) = indEnd - indStart + 1;
    runEnd(i) = trigTimes(indEnd);
end
runStart = runStart(runFrames==nframes);
runEnd = runEnd(runFrames==nframes);
axes(ax1);
yLim = ylim;
for i = 1:length(runStart)
    hPatch(i) = patch([runStart(i) runEnd(i) runEnd(i) runStart(i) runStart(i)],yLim([1 1 2 2 1]),'k');
end
uistack(hPatch,'bottom')
set(hPatch,'FaceColor',[1 1 1].*0.9,'EdgeColor','none')

axes(ax1); legend([hPlot1 hPatch(1)],[physio.titles1; {'runs'}]','location','northwest');
axes(ax2); legend([hPlot2 hPlotFreq],[physio.titles1; {'freq of interest'}],'location','northwest');

%%% Output data
data = cell(size(runStart,2),length(chanInd));
dataTime = cell(size(runStart,2),length(chanInd));
dataTrigTimes = cell(size(runStart,2),length(chanInd));
dataRun = nan(size(runStart,2),1);
dataChan = cell(1,length(chanInd));
timePad = 20; % in sec
for chanInd = 1:length(physio.titles1)
    Fs = physio.samplerate(chanInd,segmentInd);
    curData = physio.data(physio.datastart(chanInd,segmentInd):physio.dataend(chanInd,segmentInd));
    t = 0:1/Fs:length(curData)*1/Fs-1/Fs;
    for runInd = 1:length(runStart)
        [~,indStart] = min(abs(t-(runStart(runInd)-timePad)));
        [~,indEnd] = min(abs(t-(runEnd(runInd)+timePad)));
        data{runInd,chanInd} = curData(indStart:indEnd);
        dataTime{runInd,chanInd} = t(indStart:indEnd) - runStart(runInd);
        curTrigTimes = trigTimes - runStart(runInd); curTrigTimes = curTrigTimes(curTrigTimes>dataTime{runInd,chanInd}(1) & curTrigTimes<dataTime{runInd,chanInd}(end));
        dataTrigTimes{runInd,chanInd} = curTrigTimes;
        dataChan(chanInd) = physio.titles1(chanInd);
        dataRun(runInd) = runInd;
    end
end
sampleRate = physio.samplerate(:,segmentInd)';