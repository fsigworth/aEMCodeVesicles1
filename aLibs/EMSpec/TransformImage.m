function [rm rmat]= TransformImage(m, theta, scale, shift, mode, blocksize)
% function rm = TransformImage(m, theta, scale, shift,'mode')
% Rotate the image counterclockwise by theta, magnify it by scale, and then
% shift it by the given vector.  The calculation is
% rm(x,y) = m(R*([x,y]-shift)/scale), where R(theta) being the
% clockwise rotation matrix.  Out-of-bounds points are set to zero.
% For large images, memory is conserved by doing the transformation in blocks.
% Defaults: scale=1, shift=[0 0], mode='linear', blocksize=2048.
% fs 1 Mar 10

% If scale is a three-element vector, the scale(1) sets the magnification
% in x, scale(2) is the difference in magnification in y, and scale(3) is
% the difference in magnification along the diagonal axis.

% if theta is a 2x2 matrix, we use this matrix directly for the
% transformation matrix rmat.  To obtain each output point rm([x;y]) we 
% look up the input point m(rmat*[x;y]).
% the matrix rmat is also returned as an output.
[n ny]=size(m);
if n ~= ny, error('TransformImage: input image is not square'), end;

if nargin<6
    blocksize=2048;
end;
if nargin<5
    mode='linear';
end;
if nargin<4
    shift=[0 0];
end;
if nargin<3
    scale=1;
end;

% Handle defaults if scale is not a 3-element matrix
scale=scale(:);
ne=numel(scale);
if ne<3
    scale(ne:3,1)=0;
end;

% The second parameter can either be theta or the rmat.
if all(size(theta)==2)  % this parameter is the transf. matrix
    rmat=theta;
else  % construct the rotation/scale matrix
    ma2=scale(2)/(1+scale(2));
    ma3=scale(3)/(1+scale(3));
    scalemat=[1 0 ; 0 1]*scale(1)+[1 0; 0 -1]*ma2/sqrt(2)+[0 1; 1 0]*ma3/sqrt(2);
    rmat=inv([cos(theta) -sin(theta); sin(theta) cos(theta)]*scalemat);
    
end;

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
        xi=rmat(1,1)*(x-shift(1))+rmat(1,2)*(y-shift(2))+n/2+1;
        yi=rmat(2,1)*(x-shift(1))+rmat(2,2)*(y-shift(2))+n/2+1;

        % Interpolate.
        rm(lx:ux,ly:uy) = interp2( m, yi, xi, mode, 0);
    end;
end;
