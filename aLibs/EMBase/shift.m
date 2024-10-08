function ms=shift(m, x, y)
% ms = shift(m,x,y)
% shift: rotate elements of a matrix, such that
% ms(x+i, y+j) = m(i,j), with wrap-around of indices.
% Shifts are done modulo the size of m.
% shift(m,0,0) does no shifting.
% **The built-in function circshift should be used instead of this one.

[xs ys]=size(m);
x=mod(x, xs); y=mod(y, ys);
% Rotate the first dimension
m1(x+1:xs,:) = m(1:xs-x,:);
m1(1:x,:) = m(xs-x+1:xs,:);
% Rotate the second dimension
ms(:,y+1:ys) = m1(:,1:ys-y);
ms(:,1:y) = m1(:,ys-y+1:ys);
