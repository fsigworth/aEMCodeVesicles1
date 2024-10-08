function rm = mrotate(m, theta, org);
% rm = mrotate(m, theta, [org]): rotate the square matrix m counter-clockwise
% by the angle theta about the origin point org.
% Thus rm(i,j) = m( cos(theta)*i - sin(theta) * j,
%					sin(theta)*i + cos(theta) * j ).
% Bicubic interpolation is used.
% fs 26.6.04

[n ny]=size(m);
if n ~= ny, error('mrotate: input matrix is not square'), end;

if nargin<3
    org = [(n+1)/2 (n+1)/2];  % Coordinate of the center
end;

% Create input and output coordinate matrices
[x,y]=meshgrid(-org(2)+1:n-org(2),-org(1)+1:n-org(1));
xi=cos(theta)*x - sin(theta)*y;
yi=sin(theta)*x + cos(theta)*y;

% Interpolate.
% Use my modified routine that doesn't introduce NaNs.
rm = interp2a( x, y, m, xi, yi, 'cubic');
