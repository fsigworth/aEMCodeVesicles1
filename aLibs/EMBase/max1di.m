function [val, i]=max1di(m)
% function [val, i, j]=max1di(m)
% find the interpolated maximum value and its interpolated
% maximum in the vector m.  Interpolation is quadratic using
% the maximum and its two neighbors.  It uses InterpMax1.
m=m(:);
nx=numel(m);
[v0 i0]=max(m);

i0=max(i0-1,1);
i0=min(i0,nx-2);

[val di ai]=InterpMax1(m(i0:i0+2));
i=i0+di-1;
