function [mxv, x0, y0, ax, ay]=InterpMax2(m)
% function [mxv, x0, y0, ax, ay]=InterpMax2(m)
% fit the function
% m = mxv + ax*(x-x0)^2
% to the matrix of values m(x,y).  The returned values
% x0 and y0 refer to index numbers; thus if the optimum occurs
% at m(1,1), then 1,1 will be returned.
% Fixed to return values in bounds fs 1 Oct 07
%
[nx ny]=size(m);
f=zeros(nx,3);
f(:,:,1)=ones(nx,ny);
[f(:,:,2) f(:,:,4)]=ndgrid(1:nx,1:ny);
f(:,:,3)=f(:,:,2).*f(:,:,2);
f(:,:,5)=f(:,:,4).*f(:,:,4);

for i=1:5
	for j=1:5
		A(i,j)=sum(sum(f(:,:,i).*f(:,:,j)));
	end;
	y(i)=sum(sum(f(:,:,i).*m));
end;

b=y/A;

% now convert the coefficients into the desired form.
ax=b(3);
ay=b(5);
x0=-b(2)/(2*ax);
x0=min(max(1,x0),nx); % force the returned value to be in bounds.
y0=-b(4)/(2*ay);
y0=min(max(1,y0),ny);
mxv=b(1)-ax*x0*x0-ay*y0*y0;
