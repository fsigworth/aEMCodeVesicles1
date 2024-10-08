function h=imac(X,Y,m)
% function imac(m);
% Draw an image using cartesian coordinates.  It is rendered in 256-level
% grayscale regardless of the colormap in use.  The coordinates are
% Cartesian with m(x,y) being in the standard position.
% If the arguments X and Y are given, these define the
% x and y axes as in image().

if nargin<2
    
    h=image(squeeze(X)'); axis xy;
    
else
    h=image(X,Y,squeeze(m)'); axis xy;
end;

if nargout<1
    clear h  % Don't echo the handle if no output variable given.
end;