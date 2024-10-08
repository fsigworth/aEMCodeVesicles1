function r=Radial(w,org)
% function r = Radial(w,org)
% Compute the circularly-averaged, radial component of w,
% with the origin taken to be org.
% Given w is nx x ny, r is nr x 1 with nr=floor(nx/2);

% if w is three-dimensional, compute the averages over spherical shells.
% r(1) = average of points with r in [0,1),
% r(2) = average of points with r in [1,2), etc.
%
% If w is a rectangular 2d image of size nx x ny, the radius is normalized
% and r(1)...r(floor(nx/2)) is returned.
% Algorithm is based on that used in Hist.m

[nx, ny, nz] = size(w);
n=[nx ny nz];
nr=floor(nx/2);
if nargin>1 || nx ~= ny || ~ismatrix(w) % general version: rect or 3D
    if nargin<2
        org=ceil((n+1)/2);
    end;
    if nz==1  % 2D input
        R=RadiusNorm([nx ny],org(1:2))*nx;  % handle rectangular images
    else
        R=Radius3([nx ny nz],org);
    end;
    r=zeros(nr,1);
    r0=zeros(nr,1);
    for i=1:nr
        q=R<i;
        r(i)=sum(q(:).*w(:));
        r0(i)=sum(q(:));
    end;
    r=[r(1);diff(r)];
%     r(2:nr)-r(1:nr-1);
    r0=[r0(1);diff(r0)];
%     =r0(2:nr)-r0(1:nr-1);
    r = r./r0;
else
    % fast Mex version
    nx=size(w,1);
    % we assume w is square and nx is even.
    R=Radius(nx);
    
    [r, norm]=WeightedHisto(R,w,nr);
    r=r./(norm+eps);
end;