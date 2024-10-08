function [val, i, j]=max2di(m)
% function [val, i, j]=max2di(m)
% find the interpolated maximum value and its interpolated
% maximum in the matrix m(i,j).  Interpolation is quadratic and
% uses InterpMax2.

[nx ny]=size(m);
[v0 i0 j0]=max2d(m);

i0=max(i0-1,1);
i0=min(i0,nx-2);
j0=max(j0-1,1);
j0=min(j0,ny-2);

[val di dj ai aj]=InterpMax2(m(i0:i0+2,j0:j0+2));
i=i0+di-1;
j=j0+dj-1;
