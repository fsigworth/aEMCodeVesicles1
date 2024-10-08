function w=SquareWindow(n, width, ndims)
% function w=SquareWindow(n, width)
% Creates a 2D cosine-tapered window, where the taper occurs
% width from the edge.  The edge points are equal to zero.
% The returned matrix is simply the outer product of
% two 1D windows, each of dimension n.  The default width is n/64.
% If n has two elements, the returned array is rectangular.  If width has
% two elements, the horizontal and vertical tapers may be different.

if nargin<2
    width=n/64;
end;

if numel(n)<2
    n=[1 1]*n;
end;

if nargin<3
    ndims=numel(n);
end;

if numel(width)<2
    width=[1 1]*width;
end;

% if numel(n)==1  % square
%     wd=ceil(max(width));
%     w1=ones(1,n);  % a row vector
%     w1(1:wd)=0.5-0.5*cos(pi/wd*(0:wd-1));
%     w1(n:-1:n-wd+1)=w1(1:wd);
%     w=kron(w1,w1'); % take the outer product of w1 with itself.
%
% else  % rectangular
wd1=round(width(1));
w1=ones(1,n(1));
w1(1:wd1)=0.5-0.5*cos(pi/wd1*(0:wd1-1));
w1(n(1):-1:n(1)-wd1+1)=w1(1:wd1);

if ndims==1
    w=w1';
else
    
    
    wd2=round(width(2));
    w2=ones(1,n(2));
    w2(1:wd2)=0.5-0.5*cos(pi/wd2*(0:wd2-1));
    w2(n(2):-1:n(2)-wd2+1)=w2(1:wd2);
    w=kron(w2,w1');  % both w1 and w2 are row vectors; hence the order.
    
end;