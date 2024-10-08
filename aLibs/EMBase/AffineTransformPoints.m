function rpts= AffineTransformPoints(pts, n, Tmat)
% function rpts= AffineTransformPoints(pts,n,Tmat)
% Presently works only with 2D vectors.  pts is a 2xnp array of vectors,
% and n = [nx ny] is the size of the domain.  The 3x3 matrix Tmat must
% be invertible and of the form
% [r11 r12 s1
%  r21 r22 s2
%  0   0   1 ]
%  The shift values s1 and s2 are fractions of the domain sizes nx and ny.
% The affine transformed point rpt is the solution of
% pt=(R*rpt+S.*n)
% 

if numel(n)<2
    n=[1 1]*n;
end;
n=n(:);
np=size(pts,2);

T=inv(Tmat);  % invert it, because we'll transform the source, not the target.
T(1:2,3)=T(1:2,3).*n;
ctr=ceil((n+1)/2);

rpts=pts;  % allocate the output array
for i=1:np
    rpt=T*[pts(:,i)-ctr ; 1];
    rpts(:,i)=rpt(1:2)+ctr;
end;
