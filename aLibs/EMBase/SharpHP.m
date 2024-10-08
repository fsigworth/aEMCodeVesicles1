function out=SharpHP(in, fc, deltaf, stack)
% function out=SharpHP(in, fc, deltaf, stack)
%	SharpFilt: 2D or 3D high-pass fourier filter.
% Filter the input array or stack to give the half-power frequency fc
% (in units of the sampling frequency).
% The output array is the same size as the input; the filter
% uses ffts so the boundaries are periodic.
% Modified to accept stacks and the optional argument deltaf, which is the
% width of the filter transition region, in the same units as fc.  The
% default value of deltaf=0.1*fc.
% If deltaf=0, this is a completely sharp filter,  If stack=1, the 3D
% array is interpreted as a stack of 2D images.

if nargin<3
    deltaf=0;
end;
if nargin<4
    stack=0;
end;
m=size(in);
dims=numel(m); % number of dimensions
if stack
    nim=m(3);
    m=m(1:2);
    dims=2;
else
    nim=1;
end;

% the unit of frequency in the x direction will be
% 1/m(1), etc.  We want the output to have half-amplitude at fc, i.e.
% at fx=fc*m(1) units.

k=1./(fc^2*m.^2);

if dims==2
    
    [x,y]=ndgrid(-m(1)/2:m(1)/2-1, -m(2)/2:m(2)/2-1);
    if deltaf<=0
        q=(k(1)*x.^2+k(2)*y.^2)>1;
    else
        r=sqrt(k(1)*x.^2+k(2)*y.^2)+eps;
        w=deltaf/fc;
        q=0.5*(1-erf((1./r-1)/w));
    end;
    q=fftshift(q);
    
    out=zeros(size(in));  % allocate the output array
    for i=1:nim
        fq=q.*fftn(in(:,:,i));
        %     out(:,:,i)=real(fftn(conj(fq)))/prod(m); % This saves memory, to use fftn instead.
        out(:,:,i)=real(ifftn(fq));
    end;
    
elseif dims==3
    
    % 3D case
    [x,y,z]=ndgrid(-m(1)/2:m(1)/2-1, -m(2)/2:m(2)/2-1, -m(3)/2:m(3)/2-1);
    if deltaf<=0
        q=(k(1)*x.^2+k(2)*y.^2+k(3)*z.^2)>1;
    else
        r=sqrt(k(1)*x.^2+k(2)*y.^2+k(3)*z.^2)+eps;
        w=deltaf/fc;
        q=0.5*(1-erf(w./r));
    end;
    q=fftshift(q);
%     q(33)
    fq=q.*fftn(in);
    out=real(fftn(conj(fq)))/prod(m); % This saves memory, to use fftn instead.
else
    error('SharpFilt: can operate on 2D or 3D data only.');
end;

