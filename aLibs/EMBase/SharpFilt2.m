function out=SharpFilt2(in, fc, deltaf)
% function out=SharpFilt2(in, fc [, deltaf])
%	SharpFilt2: 2D fourier filter.
% out = SharpFilt2( in, fc, deltaf)
% Filter the input array or stack to give the half-power frequency fc
% (in units of the sampling frequency).
% The output array is the same size as the input; the filter
% uses ffts so the boundaries are periodic.
% Modified to accept stacks and the optional argument deltaf, which is the
% width of the filter transition region, in the same units as fc.
% If deltaf=0, this is a conventional sharp filter.

if nargin<3
    deltaf=0;
end;
m0=size(in);
if numel(m0)>2
    nim=m0(3);
else
    nim=1;
end;
m=m0(1:2);

% the unit of frequency in the x direction will be
% 1/m(1), etc.  We want the output to be zero at fc, i.e.
% at fx=fc*m(1) units.

k=1./(fc^2*m.^2);
[x,y]=ndgrid(-m(1)/2:m(1)/2-1, -m(2)/2:m(2)/2-1);
if deltaf<=0
    q=(k(1)*x.^2+k(2)*y.^2)<1;
else
    r=sqrt(k(1)*x.^2+k(2)*y.^2);
    w=deltaf/fc;
    q=0.5*(1-erf((r-1)/w));
end;
q=fftshift(q);

out=in;  % allocate the output array
for i=1:nim
    fq=q.*fftn(in(:,:,i));
%     out(:,:,i)=real(fftn(conj(fq)))/prod(m); % This saves memory, to use fftn instead.
    out(:,:,i)=real(ifftn(fq)); % This saves memory, to use fftn instead.
end;
