function c=FSCorr(m1,m2)
% c=FSCorr(m1,m2)
% Compute the fourier shell correlation between the 3D maps m1 and m2,
% which must be n x n x n in size with the same n, assumed to be even.
%
% The FSC is defined as
%           \sum{F1 .* conj(F2)}
% c(i) = -----------------------------
%        sqrt(\sum|F1|^2 * \sum|F2|^2)
%
% Where F1 and F2 are the Fourier components at the given spatial frequency i.
% i ranges from 0 to n/2-1, times the unit frequency 1/(n*res) where res
% is the pixel size.

% First, construct the radius values for defining the shells.
n=size(m1,1);
[x, y, z] = ndgrid(-n/2:n/2-1);  % zero at element n/2+1.
R = sqrt(x.^2 + y.^2 + z.^2);
eps = 1e-4;

% Fourier-transform the maps
f1=fftshift(fftn(m1));
f2=fftshift(fftn(m2));

% Perform the sums.
d0=R<0.5 + eps;  % Sphere at origin
c=zeros(n/2,1);
c(1)=0;
for i=1:n/2-1
	d1=R<0.5+i+eps;
	ring=d1-d0;
% 	nr=sum(sum(sum(ring)))
	r1=ring(:).*f1(:);
	r2=ring(:).*f2(:);
	num=real(r1(:)'*r2(:));
	den=sqrt(sum(sum(sum(abs(r1).^2)))*sum(sum(sum(abs(r2).^2))));
	c(i+1)=num/den;
	d0=d1;
end;
