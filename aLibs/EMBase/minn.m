function [val,inds]=minn(m)
% function [val,inds]=minn(m)
% find the minimum value and its indices in an n-dimensional array.
%
s=size(m);
[val,i]=min(m(:));
[a b c d e f g h]=ind2sub(s,i);
inds=[a b c d e f g h];
inds=inds(1:ndims(m));
