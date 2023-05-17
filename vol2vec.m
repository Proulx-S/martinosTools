function mri = vol2vec(mri,mask)
% vol2vec.m and vec2vol.m
% To be used with MRIread.m and MRIwrite.m from Freesurfer
% (/usr/local/freesurfer/dev/matlab/).
% Moves from a 4D volume timeseries to a vectorize 2D (time X voxel) format
% using a user-specified mask (vol2vec.m), and vice-versa (vec2vol.m).
% This saves memory while keeping data in a compatible format.
% Mask is mandatory for vol2vec.m as there is little point in vectorizing
% the complete 4D data.
if isempty(mri.vol) && ~isempty(mri.vec)
    % already in vector format, don't do anything
    return
end
mri = setNiceFieldOrder(mri,{'vol' 'vol2vec' 'vec'});

%% Set mask to vol2vec
if exist('mask','var') && ~isempty(mask) && ~isempty(mri.vol)
    if isfield(mri,'vol2vec')
        error('mask already exists')
    end
    mri.vol2vec = logical(mask);
    mri.vol2vecFlag = 'customMask';
else
    % if mask not specified, use all ones except voxels where the
    % timeseries is all zeros (edge voxels)
    sz = size(mri.vol);
    mri.vol2vec = true(sz(1:3)) & ~all(mri.vol==0,4);
    mri.vol2vecFlag = 'allInclusiveMask';
end
%% Vectorize according to vol2vec
mri.vol = permute(mri.vol,[4 1 2 3]);
mri.vec = mri.vol(:,mri.vol2vec);
mri.vol = [];


