function [M,mOut]=meGetImageScaling(nIn,nOut,ds);
% function M=meGetImageScaling(nIn,nOut,ds); or
% function [M,mOut]=meGetImageScaling(mIn,nOut,ds);
% Create an affine transformation matrix M for the operation of
%  padding and downsampling funny-sized
%  images from size nIn to nOut, each 1x2 vectors.
% If an output image mOut is requested, the input image mIn is also
%  downsampled and cropped appropriately.
% If the downsampling
%  factor (can be a 1x2 vector for anisotropy) ds is not 
%  given, we assume padding is the miniumum such that the scalar
%  integer downsampling factor can be obtained from
%  ds=ceil(max(nIn./nOut)). We return a matrix
%  [ds  0   xsh
%   0   ds  ysh
%   0   0    1 ]
%  If we crop-and-pad first by M1 and then by M2, then the transform from
%  final (downsampled) coordinates to the original coordinates will be
%  [x0; y0; 1]=M2.M1.[x; y; 1]; Note this would be in the case of zero-based
%  coordinates.
%  The corresponding crop-and-pad operation is
%  mOut=Downsample(Crop(mIn,ds.*nOut),nOut);

if nargout>1 % we're operating on an image
    mIn=nIn;
    nIn=size(mIn);
elseif numel(nIn)<2
    nIn=nIn*[1 1];
end;
if numel(nOut)<2
    nOut=nOut*[1 1];
end;
if nargin<3
    ds=ceil(max(nIn./nOut)); % Can't be smaller than 1.
end;
if numel(ds)<2 % isotropic downscaling
    ds=ds*[1 1];
end;
M=zeros(3,3,'single');
M(1,1)=ds(1);
M(2,2)=ds(2);
M(:,3)=[floor(nOut.*ds/2)-floor(nIn/2) 1];

if nargout>1
    mOut=Downsample(Crop(mIn,ds.*nOut),nOut);
end;