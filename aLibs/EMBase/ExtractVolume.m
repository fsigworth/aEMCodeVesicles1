function out=ExtractVolume(in,cpoint,n,insertMode)
% function out=ExtractVolume(in,cpoint,n,insertMode);
% Copy the vicinity of the point 'cpoint' (of the input volume
% into the volume of size n^3 'out'. Clipping is
% performed so that cpoint may
% be on the edge (or outside the bounds) of in.  In this case zeros are
% returned for the out-of-bounds points. If n is odd, the center of out,
% [(n+1)/2, (n+1)/2, (n+1)/2]  will correspond to cpoint.  If n is even, the point
% [n/2+1 n/2+1] will correspond to cpoint.
% If the optional argument insertMode=1, then the center of *in* will be
% copied into the location cpoint of the *output* array. this allows a
% smaller volume to be padded into a larger volume.
% The output image is the same class (single, integer, etc.) as the input.

% Based on the code of ExtractImage() and Mask()
% fs 25 May 21

if nargin<4
    insertMode=0;
end;
cpoint=cpoint(:)';  % Force a row vector
n=double(n);  % it might be passed as an integer.
if numel(n)<3
    n=[1 1 1]*n;
end;
if nargin>3 && insertMode  % case where cpoint is coordinate of 'out'
    ct1=ceil((size(in)+1)/2);  % Center of input image
    ct2=ceil((n+1)/2);         % Center of output image
    cpoint=ct1+ct2-cpoint;   % convert to input image coordinate.
end;

lower=floor(n/2); upper=n-lower-1;

% For example, mapping 3x3 into (10,10):
% lower=1, upper = 1, use points i-1:i+1, center on point 2
% e.g. mapping 4x4
% lower=2, upper =1, use points i-2:i+1, center on point 3.

% Clip the coordinates.
inl=max([1 1 1],cpoint-lower);  % lower left corner on the input
inu=min(size(in),cpoint+upper);  % upper right corner on the input
rgl=inl-cpoint+lower+1; % lower left corner of the output
rgu=inu-cpoint-upper+n; % upper right corner of the output
% Force the inputs to be in bounds
rgl0=max([1 1 1],rgl);
rgu0=min(n,rgu);
inl=inl+(rgl0-rgl);  % shift the input up if necessary
inu=inu-(rgu0-rgu);

out=zeros(n,class(in));  % force the output to be the same class as input.
%disp([inl inu rgl rgu]);
if insertMode
    out(rgl(1):rgu(1),rgl(2):rgu(2),rgl(3):rgu(3))=in(inl(1):inu(1),inl(2):inu(2),inl(3):inu(3));
else
    out(rgl(1):rgu(1),rgl(2):rgu(2),rgl(3):rgu(3))=out(rgl(1):rgu(1),rgl(2):rgu(2)) ...
        +in(inl(1):inu(1),inl(2):inu(2),inl(3):inu(3));
end;
