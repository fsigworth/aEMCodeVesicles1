function rm = lrotate(m, theta)
% function rm = lrotate(m, theta)
% Fast image rotation using bilinear interpolation.
% rm = lrotate(m, theta): rotate the square matrix m counter-clockwise
% by the angle theta about the point [(n+1)/2, (n+1)/2].
% Thus rm(j,i) = m( cos(theta)*i - sin(theta) * j,
%					sin(theta)*i + cos(theta) * j ).

[ny nx]=size(m);

% Create input and output coordinate matrices
rampx= (1-nx)/2:(nx-1)/2;		% a row vector
rampy= (1-ny)/2:(ny-1)/2;		% a row vector
[x,y]=meshgrid(rampx, rampy);% for i=1:n; x(:,i)=ramp'; y(i,:)=ramp; end
X=cos(theta)*x - sin(theta)*y + (nx+1)/2;
Y=sin(theta)*x + cos(theta)*y + (ny+1)/2;

% Convert to 1D arrays
X=reshape(X,nx*ny,1);
Y=reshape(Y,nx*ny,1);

% Clip the coordinates to be in bounds.
eps=1e-4;
X=max(X,1+eps);
X=min(X,nx-eps);

Y=max(Y,1+eps);
Y=min(Y,ny-eps);

X0=floor(X);
Xi=X-X0;
X1=X0+1;
X0=(X0-1)*nx;  % Convert to linear index component for rows.
X1=(X1-1)*nx;

Y0=floor(Y);
Yi=Y-Y0;
Y1=Y0+1;
% rm=m(X0+Y0);
rm= (1-Yi).*(m(X0+Y0).*(1-Xi) + m(X1+Y0).*Xi)...
     + Yi.*(m(X0+Y1).*(1-Xi) + m(X1+Y1).*Xi);
rm=reshape(rm,ny,nx);

