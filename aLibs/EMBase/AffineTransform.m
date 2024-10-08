function rm= AffineTransform(m, Tmat, mode, blocksize)
% function rm= AffineTransform(m, Tmat, mode, blocksize)
% Presently works only with 2D images, but they can be rectangular.
% Perform an affine transformation on the image.  The 3x3 matrix Tmat must
% be invertible and of the form
% [r11 r12 s1
%  r21 r22 s2
%  0   0   1 ]
%  The shift values s1 and s2 are fractions of the total image dimension.
% That way the transformation is invariant under binning of an image.
% The affine transformed image rm is
% rm(R*[x;y]+S*n)=m
% 
%  Defaults: mode='linear', blocksize=2048. This blocksize is good for my
%  4GB Macbook.
%  Example: counterclockwise rotation, followed by shift by (dx,dy)
%    Tmat= [cos(theta) -sin(theta) dx 
%           sin(theta)  cos(theta) dy
%               0            0      1]

[nx ny]=size(m);
n=[nx ny];

if nargin<4
    blocksize=2048;
end;
if nargin<3
    mode='linear';
end;
T=inv(Tmat);  % invert it, because we'll transform the source, not the target.

nb=ceil(n/blocksize);  % number of blocks in x and y directions
rm=zeros(n);

ct=n/2+1;  % assumes even n!

for by=0:nb(2)-1
    ly=1+by*blocksize;
    uy=min(ny,(by+1)*blocksize);
    for bx=0:nb(1)-1
        lx=1+bx*blocksize;
        ux=min(nx,(bx+1)*blocksize);
        
        % Create input and output coordinate matrices
        [x,y]=ndgrid(lx-1-nx/2:ux-nx/2-1,ly-1-ny/2:uy-ny/2-1);
        xi=T(1,1)*x+T(1,2)*y+T(1,3)*nx+ct(1);
        yi=T(2,1)*x+T(2,2)*y+T(2,3)*ny+ct(2);

        % Interpolate.
        rm(lx:ux,ly:uy) = interp2( m, yi, xi, mode, 0);
    end;
end;
