function m = disc(n, r, origin)
% DISC
% m = disc(n, r, origin): create an n x n matrix that is all zeros except
%	for a offset circular region of radius r in the center, where elements
%	are equal to 1.  The origin is by default [(n+1)/2, (n+1)/2].

%	Determine the origin
if nargin<3
    origin = [(n+1)/2 (n+1)/2];  % Coordinate of the center
end;

[x,y]=ndgrid(-origin(1)+1:n-origin(1),-origin(2)+1:n-origin(2));
r2=x.^2+y.^2;
m=r2<(r+.5)^2;
