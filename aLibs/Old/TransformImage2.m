function rm= TransformImage2(m, trmat, mode, blocksize)
% function rm = TransformImage2(m, trmat, mode, blocksize)
% Perform an affine transformation on the image according to the trmat
% matrix.  The calculation is
% rm(T*[x;y]+b) = m(x,y)
% where out-of-bounds points are set to zero.
% trmat can be either 2x3 or a 3x3 matrix; in general
% it is defined as the (must be invertible) matrix
% [a11 a12 b1
%  a21 a22 b2
%   0   0   1]
%  and trmat * [x y 1]' = A[x y]'+b
% 
%  Defaults: mode='linear', blocksize=2048.
% 
% example: counterclockwise rotation, followed by shift by (dx,dy)
%    rmat= [cos(theta) -sin(theta) dx; 
%    sin(theta) cos(theta) dy;
%            0            0      1]

[n ny]=size(m);
if n ~= ny, error('TransformImage: input image is not square'), end;

if nargin<4
    blocksize=2048;
end;
if nargin<3
    mode='linear';
end;

% if the transformation matrix is too small, expand it.
[nr nc]=size(trmat);
if nc<3
    trmat(:,3)=[0;0;1];
end;
if nr<3
    trmat(3,:)=[0 0 1];
end;
T=inv(trmat);  % invert it, because we'll transform the source, not the target.

nb=ceil(n/blocksize);
rm=zeros(n,n);

for by=0:nb-1
    ly=1+by*blocksize;
    uy=min(n,(by+1)*blocksize);
    for bx=0:nb-1
        lx=1+bx*blocksize;
        ux=min(n,(bx+1)*blocksize);
        
        % Create input and output coordinate matrices
        [x,y]=ndgrid(lx-1-n/2:ux-n/2-1,ly-1-n/2:uy-n/2-1);
        xi=T(1,1)*x+T(1,2)*y+T(1,3)+n/2+1;
        yi=T(2,1)*x+T(2,2)*y+T(2,3)+n/2+1;

        % Interpolate.
        rm(lx:ux,ly:uy) = interp2( m, yi, xi, mode, 0);
    end;
end;
