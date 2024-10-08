function [mxv, x0, ax]=InterpMax1(m)
% function [mxv, x0, ax]=InterpMax1(m)
% fit the function
% m = mxv + ax*(x-x0)^2
% to the vector of values m(x).  The returned values
% x0 and y0 refer to index numbers; thus if the optimum occurs
% at m(1,1), then 1,1 will be returned.
% Derived from InterpMax2.
%
m=m(:);
nx=numel(m);
f=zeros(nx,3);
f(:,1)=ones(nx,1);
f(:,2)=(1:nx)';
f(:,3)=f(:,2).^2;

for i=1:3
	for j=1:3
		A(i,j)=sum(f(:,i).*f(:,j));
	end;
	y(i)=sum(f(:,i).*m);
end;

b=y/A;

% now convert the coefficients into the desired form.
ax=b(3);
x0=-b(2)/(2*ax);
x0=min(max(1,x0),nx); % force the returned value to be in bounds.
mxv=b(1)-ax*x0*x0;
