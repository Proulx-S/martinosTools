function physio = popp(physio)
figFlag = 0;
if ~exist('srcFs','var')
    srcFs = 'source /usr/local/freesurfer/fsenv dev';
end

physio.popp = cell(size(physio.data,1),1);
for runInd = 1:2%size(physio.data,1)
    disp(['run' num2str(runInd) '/' num2str(size(physio.data,1))])
    %% write physio data to temp file
    physioFileTmp1 = tempname;
    writematrix(cat(1,physio.data{runInd,:})',physioFileTmp1,'Delimiter',' ')
    %% process it with fsl's popp
    cmd = {srcFs};
    cmd{end+1} = ['popp \'];
    cmd{end+1} = ['--samplingrate=' num2str(physio.sampleRate(1)) ' \'];
    cmd{end+1} = ['--tr=' num2str(physio.tr) ' \'];
    cmd{end+1} = ['--resp=' num2str(find(ismember(physio.chan,'resp'))) ' \'];
    cmd{end+1} = ['--cardiac=' num2str(find(ismember(physio.chan,'cardiac'))) ' \'];
    cmd{end+1} = ['--trigger=' num2str(find(ismember(physio.chan,'trigger'))) ' \'];
    cmd{end+1} = ['--startingsample=' num2str(find(physio.time{runInd,1}==0)) ' \'];
    cmd{end+1} = ['--rvt --heartrate \'];
    cmd{end+1} = ['-i ' physioFileTmp1 '.txt \'];
    physioFileTmp2 = tempname;
    cmd{end+1} = ['-o ' physioFileTmp2];
    cmd = strjoin(cmd,newline); % disp(cmd)
    [status,cmdout] = system(cmd); if status; error(cmdout); end
    
    %% convert the hex output with python
    sufList = {'card' 'hr' 'resp' 'rvt' 'time'};
    for i = 1:length(sufList)
        cmd = {};
        cmd{end+1} = ['/space/takoyaki/1/users/proulxs/tools/martinosTools/readHex.py \'];
        cmd{end+1} = [physioFileTmp2 '_' sufList{i} '.txt'];
        cmd = strjoin(cmd,newline); % disp(cmd)
        [status,cmdout] = system(cmd); if status; error(cmdout); end
        %%% read back the terminal output
        physio.popp{runInd}.(sufList{i}) = str2num(cmdout);
    end

    if figFlag
        figure('WindowStyle','docked');
        yyaxis left
    end
    t    = physio.time{runInd,ismember(physio.chan,'cardiac')};
    card = physio.data{runInd,ismember(physio.chan,'cardiac')};
    if figFlag
        plot(t,card); hold on
    end
    cardPeaks = physio.popp{runInd}.card;
    cardAmps = nan(size(cardPeaks));
    for peakInd = 1:length(cardPeaks)
        [~,b] = min(abs(cardPeaks(peakInd)-t));
        cardAmps(peakInd) = card(b);
    end
    if figFlag
        scatter(cardPeaks,cardAmps,'ro','filled')
        ylabel('piezo trace')
        yyaxis right
        plot(physio.popp{runInd}.hr(:,1),physio.popp{runInd}.hr(:,2))
        ylabel('heart rate (bpm)'); xlabel('time (sec)')
    end

    physio.popp{runInd}.cardAmp = cardAmps;

    if figFlag
        figure('WindowStyle','docked');
        yyaxis left
        plot(physio.popp{runInd}.resp(:,1),physio.popp{runInd}.resp(:,2));
        ylabel('phase')
        hold on
        yyaxis right
    end
    resp = physio.data{runInd,ismember(physio.chan,'resp')};
    if figFlag
        plot(t,resp);
        ylabel('belt signal')
        xlabel('time(sec)')
    end
    
    if figFlag
        figure('WindowStyle','docked');
        plot(physio.popp{runInd}.rvt(:,1),physio.popp{runInd}.rvt(:,2))
        ylabel('RVT'); xlabel('time (sec)')
    end
%     plot(abs(fft(physio.popp{runInd}.rvt(:,1))))
end


