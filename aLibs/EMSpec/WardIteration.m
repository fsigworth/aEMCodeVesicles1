function   [T,S,m,E,h,index,p,q]=WardIteration(T,S,m,E,index);
% For startup:       [T,S,m,E,h,index,p,q]=WardIteration(Data);
% For iterations:  [T,S,m,E,h,index,p,q]=WardIteration(T,S,m,E,h,index);
% Perform an iteration of Ward's method for classification, using a Euclidean
% penalty function.
% F. Sigworth 15 Nov 01
% last modified 26 Feb 03
%
% The Data array (nxh0) is organized such that each of the h0 columns is a
% datum.  Each datum is a column vector of size n.
%
% The number of clusters h starts at the number of data, h0, and decrements
% with each iteration.
% The vectors S,m and E are all assumed to be 1xh.  T is nxh, where n is the
% number of dimensions of the data, and is initial equal to Data.
% The index array is of size h0, that is the original number of data;
% k=index(j) tells which cluster the jth datum belongs to.
% The mean of cluster k is obtained as T(:,k)./m(k).

% The total sum-of-squares of all the clusters
% is given by sum(E).
% The extra error on merging the clusters is given by
% the increment in sum(E) from the (n-1)th to the nth iteration.
%
% At a given step, cluster q is merged into cluster p; the various arrays
% are updated to reflect this, and h is decremented.
 
% The clustering is performed as
%
% [T,S,m,E,h,index,p,q]=WardIteration(Data); % Startup.
% while h>hmin
% 	[T,S,m,E,h,index,p,q]=WardIteration(T,S,m,E,index);	
% end;

% Start-up mode.  We copy the data into T and initialize everything else.
if nargin<5
    % Assume that we are starting up.
    [n h]=size(T);  % T is taken to be the Data
    S=sum(T.*T);
    m=ones(1,h);
    E=zeros(1,h);
    index=(1:h);
end;

[n h]=size(T);
evals=zeros(1,h-1); % We evaluate the min error for each q.
ivals=zeros(1,h-1); % p index values for each q.
for q=2:h
 	pvals=1:q-1;
	Tq=repmat(T(:,q),1,q-1);
	dE=S(pvals)-sum((T(:,pvals)+Tq).^2)./(m(pvals)+m(q))-E(pvals);
	[e i]=min(dE);  % Find the minimum over the p values.
	evals(q-1)=e+S(q)-E(q);
	ivals(q-1)=i;
end;
[deltaE mq]=min(evals); % Find the minimum over q
p=ivals(mq); % pick up the corresponding p index
q=mq+1;	     % Correct for the fact that we started at q=2 in the calculations.

% update the cluster variables.  The index p is always smaller than q.
T(:,p)=T(:,p)+T(:,q);
S(p)=S(p)+S(q);
m(p)=m(p)+m(q);
E(p)=E(p)+E(q)+deltaE;

% remove the old cluster q from the arrays
oldq=q+1:h;
newq=q:h-1;
T(:,newq)=T(:,oldq); T=T(:,1:h-1);
S(newq)=S(oldq); S=S(1:h-1);
m(newq)=m(oldq); m=m(1:h-1);
E(newq)=E(oldq); E=E(1:h-1);
h=h-1;

% In the index array, convert all 'q' indices to 'p' and shift everything
% higher than q down by 1.
index=index-(index>q)-(index==q)*(q-p);
