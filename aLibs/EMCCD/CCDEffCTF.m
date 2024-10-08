function h = CCDEffCTF(iCamera, n, ds, deNormalize)
% f = CCDEffCTF(iCamra, n, ds, denormalize);
% This function was formerly called CCDSqrtDQE.
% Compute a 2D array to multiply the result of CTF(n), to give the actual
% CTF of a pre-whitened image acquired with our CCD camera.  The function
% is the square root of the DQE as it is normally defined.  
% Like CTF(), zero frequency is in the center of the returned 2D array, so
% you will have to use fftshift before taking any IFFT.  By default
% n=4096, the size of our CCD.
% The ds argument is also optional, with default 1; if >1 it means
% that the image being processed was downsampled, and therefore the maximum
% frequency is that much smaller than Nyquist.
% if ds=1, the returned function is literally the sqrt(DQE).  If deNormalize = 0
% (default) then the maximum (central) value = 1.  Otherwise the central
% value of h is equal to sqrt(DQE) at zero frequency which is less than 1.
%
% Example.  Compute a simulated image to compare with a pre-whitened
% experimental image.  Let Obj be the true 2D image, e.g. a projection of a
% 3D model, pixA be the angstroms per pixel, and CPars be a structure with
% the CTF parameters (lambda, defocus, etc.)  Then,
%
% n=size(Obj,1);
% h=CCDEffCTF(1,n).*CTF(n,res,CPars);
% ObjFilt=real(ifftn(fftn(Obj).*fftshift(h)));
%

% fs 6 Nov 2010
% added normalization 22 Apr 13
% added iCamera 1 July 14

% Get the native image size
switch iCamera
    case 3
        n0=[3072 4096];
    case 5
        n0=[3840 3840];  % k2 camera, padded
    case 7
        n0=[5760 4096];  % k3 camera, padded
    otherwise
        n0=[4096 4096]; % indices 1,2,4
end;
if nargin<2
    n=n0;
end;
if nargin<3
    ds=n0(1)/n(1);
end;
if nargin<4
    deNormalize=0;
end;
if numel(n)<2
    n=n*[1 1];
end;

fd=RadiusNorm(n)/ds;  % frequency relative to pixel pitch
h=CCDModelMTF(fd,iCamera)./sqrt(CCDModelSpectrum2D(iCamera,n));
if ~deNormalize  % normalize to unity at low frequency
    ctr=floor(n/2+1);
    h=h/h(ctr(1),ctr(2));
end;
