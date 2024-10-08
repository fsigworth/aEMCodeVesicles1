function out=SharpFilt3(in, fc);
%	SharpFilt3: 3D fourier filter.
% out = SharpFilt3( in, fc)
% Filter the input array to give the half-power frequency fc
% (in units of the sampling frequency).
% The output array is the same size as the input; the filter
% uses ffts so the boundaries are periodic.
m=size(in);
% the unit of frequency in the x direction will be
% 1/m(1), etc.  We want the output to be zero at fc, i.e.
% at fx=fc*m(1) units.

k=1./(fc^2*m.^2);
[x,y,z]=ndgrid(-m(1)/2:m(1)/2-1, -m(2)/2:m(2)/2-1, -m(3)/2:m(3)/2-1);
q=(k(1)*x.^2+k(2)*y.^2+k(3)*z.^2)<1;
q=fftshift(q);
fq=q.*fftn(in);
out=real(fftn(conj(fq)))/prod(m); % This saves memory, to use fftn instead.
