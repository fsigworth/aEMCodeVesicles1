function h=imaga(X,Y,m)
% function h=imaga(m);  % Draw image m as 256-level grayscale
% function h=imaga(X,Y,m);  % label axes according to vectors X and Y.
% Draw an image using cartesian coordinates; the image pixel values are 
% assumed to lie in 0...255. It is rendered in grayscale regardless of the
% colormap in use.  The coordinates are cartesian with m(1,1) being in the
% lower left, m(end,1) on the lower right.
% If the arguments X and Y are given, these define the
% x and y axes as in image().
% If m is 1D, we attempt to display it as a square image.
% The returned value h is the handle to the graphics object.

ClearFigureCallbacks(gcf);

if nargin<2    
    z=squeeze(X)';
    if isvector(z) % we'll try to display a 1D array as square.
        nx=floor(sqrt(numel(z)));
        z=z(1:nx^2);
        z=reshape(z,nx,nx);
    end;
    h=image(repmat(single(z)/256,1,1,3)); axis xy;
else
    z=squeeze(m)';
    h=image(X,Y,repmat(single(z)/256,1,1,3)); axis xy;
end;
if nargout<1
    clear h  % Don't echo the handle if no output variable given.
end;
