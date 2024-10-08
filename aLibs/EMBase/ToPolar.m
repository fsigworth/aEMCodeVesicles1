 function P = ToPolar(W, nr, ntheta, rscale, x0, y0)
%  function P = ToPolar(W, nr, ntheta, rscale, x0, y0)
% P = ToPolar(W, nr, ntheta, rscale, x0, y0)
% Convert the image W(x,y) to polar coords P(r,theta).
% In the P array, P(1,theta) corresponds to r=0, and
% theta=0 corresponds to points (x,y0) with x>x0.
% fs
% In typical use, if W is nxn, we set ntheta=2n and nr=n/2,
% and rscale=1.
% Default values are nr=floor(nx/2), ntheta=nx*2, rscale=1,
% x0=nr+1, y0=nr+1.

% Added defaults fs 7 Oct 07

% % ----begin test code----
% n=64;
% a=18;
% d=4;
% x=32;
% y=32;
% 
% setgrayscale;
% figure(1);
% W=vidensity(n,a,d,x,y)+randn(64);
% W(32:34,:)=-5;
% W(:,32)=-5;
% W(40,40)=-5;
% subplot(1,2,1);
% imagesc(W);
% 
% ntheta=128;
% nr=32;
% rscale=1;
% x0=32;
% y0=32;
% imagesc(W);
% % ----end test code----

[nx ny]=size(W);
if nargin<2
    nr=floor(nx/2);
end;
if nargin<3
    ntheta=2*nx;
end;
if nargin<4
    rscale=1;
end;
if nargin<5
    x0=nr+1;
    y0=nr+1;
end;
eps=0.0001;

theta=(0:ntheta-1)*2*pi/ntheta;
ct=cos(theta);
st=sin(theta);
r=(0:nr-1)*rscale;


% Find the coordinates corresponding to each polar matrix element.
X=r'*ct+x0;	%Outer product
Y=r'*st+y0;

% Convert to 1D arrays
X=reshape(X,nr*ntheta,1);
Y=reshape(Y,nr*ntheta,1);

% Clip the coordinates to be in bounds.
X=max(X,1+eps);
X=min(X,nx-eps);

Y=max(Y,1+eps);
Y=min(Y,ny-eps);

% Bi-linear interpolation
X0=floor(X);
Xi=X-X0;
X1=X0+1;

Y0=floor(Y);
Yi=Y-Y0;
Y1=Y0+1;
Y0=(Y0-1)*nx;
Y1=(Y1-1)*nx;	% Convert to linear index component for rows.

P= (1-Yi).*(W(X0+Y0).*(1-Xi) + W(X1+Y0).*Xi)...
     + Yi.*(W(X0+Y1).*(1-Xi) + W(X1+Y1).*Xi);
P=reshape(P,nr,ntheta);

% %  ----test code follows----
% subplot(1,2,2);
% imagesc(P);
% axis xy;
