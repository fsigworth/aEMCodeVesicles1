function [val,i,j,k]=max3d(m)
% function [val,i,j,k]=max3d(m)
% find the maximum value and its indices in a 3-dimensional array.
%
[x,i0]=max(m);
[y,j0]=max(x);
[val,k]=max(y);
j=j0(1,1,k);
i=i0(1,j,k);
