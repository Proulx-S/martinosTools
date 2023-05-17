function mri = vec2vol(mri)
% vol2vec.m and vec2vol.m
% To be used with MRIread.m and MRIwrite.m from Freesurfer
% (/usr/local/freesurfer/dev/matlab/).
% Moves from a 4D volume timeseries to a vectorize 2D (time X voxel) format
% using a user-specified mask (vol2vec.m), and vice-versa (vec2vol.m).
% This saves memory while keeping data in a compatible format.
% Mask is mandatory for vol2vec.m as there is little point in vectorizing
% the complete 4D data.
if isempty(mri.vec) && ~isempty(mri.vol)
    % already in volume format
    return
end

mri.vol = nan(mri.nframes,mri.height,mri.width,mri.depth);
mri.vol(:,mri.vol2vec) = mri.vec;
mri.vec = [];
mri.vol = permute(mri.vol,[2 3 4 1]);