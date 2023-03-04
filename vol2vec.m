function mri = vol2vec(mri,mask)
% vol2vec.m and vec2vol.m
% To be used with MRIread.m and MRIwrite.m from Freesurfer
% (/usr/local/freesurfer/dev/matlab/).
% Moves from a 4D volume timeseries to a vectorize 2D (time X voxel) format
% using a user-specified mask (vol2vec.m), and vice-versa (vec2vol.m).
% This saves memory while keeping data in a compatible format.
% Mask is mandatory for vol2vec.m as there is little point in vectorizing
% the complete 4D data.

if exist('mask','var') && ~isempty(mask) && ~isempty(mri.vol)
    if isfield(mri,'vol2vec')
        error('mask already exists')
    end
    mri.vol2vec = logical(mask);
    mri.vec = [];
    curNames = fieldnames(mri);
    curInd = find(ismember(curNames,{'vol' 'vol2vec' 'vec'}));
    tmpNames1 = curNames(1:(curInd(1)-1));
    tmpNames2 = curNames((curInd(1)):end); tmpNames2(ismember(tmpNames2,{'vol' 'vol2vec' 'vec'})) = [];
    newNames = [tmpNames1; {'vol' 'vol2vec' 'vec'}'; tmpNames2];
    [~,Locb] = ismember(newNames,curNames);
    mri = orderfields(mri,Locb);
end

mri.vol = permute(mri.vol,[4 1 2 3]);
mri.vec = mri.vol(:,mri.vol2vec);
mri.vol = [];

