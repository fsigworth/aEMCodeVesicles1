function s=RadialPowerSpectrum(in,stack,binFactor)
% s=RadialPowerSpectrum(in,stack,binFactor);
% Compute the radially-averaged power spectrum of the rectangular image or
% cubic volume in, returning the result in a column vector s.  If x is
% three-dimensional and stack=0 (default), compute the power spectrum on
% shells. 
% If stack=1, from the (nx x ny x nim) stack compute the n x nim array of
% spectra from the stack of nim images. To get the mean, compute
% mean(RadialPowerSpectrum(in,1),2).
% For each image the DC component is subtracted and a window is used. If x
% is nx x ny, n=min(nx,ny) then the returned vector s has length
% floor((n+1)/2). s(1) is the fs/n frequency component . s(2) is the 2fs/n frequency component, (fs is the sampling
% frequency); s(n/2) is the (fs/2) frequency component. The
% frequency step is fs/n.
%
% ** s is computed as averages of fftn(in)/prod(size(in)).
% ** Note that to get an absolute power spectrum in units of A^2, you must
% multiply s by pixA^2 of the input image.  For a volume, the absolute
% spectrum will be in A^3 and you must multiply by pixA^3.
%
% Modified to give unity output for white noise with unity pixel variance.
% --fs 2 Sep 07
% Modified to bin the output points by binFactor; this saves lots of time.
% --fs 15 Mar 15
% Modified to handle 3D volumes.  Note that stacks of volumes are handled
% correctly, but binning is not.
% --fs 00 Aug 15

if nargin<2
    stack=0;
end;
if nargin<3
    binFactor=1;
end;
ndim=ndims(in);
% [nx, ny, nz, nim]=size(in);
n=size(in);
nim=1;
if stack
    if ndim>2  % 3D input: treat it as a stack?
        nim=n(ndim);  % no. of stacked images
        ndim=ndim-1;
        n=n(1:ndim);
    end;
end;
if ndim>2
    binFactor=1;  % we don't bin in 3D
end;

nr=floor((min(n)+1)/(2*binFactor));
accum=zeros(nr,nim);

% Make a window of width n/8 around the edges.
if ndim>2
    w=fuzzymask(n,3,n(1)*.45,.1);
else
    w=SquareWindow(n, ceil(n(1)/8));
end;
norm=w(:)'*w(:);  % Accounts for power attenuation due to the window.
ws=sum(w(:));

for i=1:nim
    if ndim<3
        x=in(:,:,i);
    else
        x=in(:,:,:,i);
    end;
    % Remove DC component.
    x=x-mean(x(:));
    
    x=x.*w;  % Windowed signal
    xs=sum(x(:));
    x=x-w*(xs/ws); % Second round of DC subtraction.
    % sum(wx(:))  % check DC subtraction
    
    % Spectrum in rectangular coordinates
    fs=fftshift(abs(fftn(x)).^2);
    if binFactor>1
        fs=BinImage(fs,binFactor);
    end;
    % x=[];  % save memory.
    % w=[];
    % Radial averaging
    if ndim==2
        accum(:,i)=Radial2(fs);
    else
        accum(:,i)=Radial3(fs);
    end;
end;
s=accum/norm;
% ps=ToPolar(fs,n/2,2*n,1,n/2+1,n/2+1);
% s=sum(ps')/(2*n*norm);
