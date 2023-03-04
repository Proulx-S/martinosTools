function M = getMaskOutline(mask,precisionFactor)
% Extract contour of a mask image (0s and 1s) Matlab's polygon object M for
% later ploting over another image ( plot(M) ).
% Higher precisionFactor alleviates the round corners problem but is
% computationally more intense (requires image resizing)

%% Resize mask
if ~exist('precisionFactor','var')
    precisionFactor = 2;
end
xRs = ( (1:(size(mask,1)*precisionFactor)) - 0.5 ) / precisionFactor;
yRs = ( (1:(size(mask,2)*precisionFactor)) - 0.5 ) / precisionFactor;
mask = imresize(mask,precisionFactor,'nearest');

%% Compute contours
Mtmp = contourc(yRs,xRs,mask,[0.5 0.5]);
M = polyshape(Mtmp(:,2:1+Mtmp(2,1))' + [0.5 0.5]); Mtmp(:,1:1+Mtmp(2,1)) = [];
while ~isempty(Mtmp)
    M = xor(M,polyshape(Mtmp(:,2:1+Mtmp(2,1))' + [0.5 0.5])); Mtmp(:,1:1+Mtmp(2,1)) = [];
end