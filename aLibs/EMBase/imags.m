function h=imags(x,y,m)
% function h=imags(x,y,m);
% function h=imags(m);
% function h=imags(m,sz);
% This makes an autoscaled grayscale image regardless of the colormap.
% Draw an image m using cartesian coordinates and autoscaling,
% with m(1,1) being in the standard position at lower left, where with
% m(ix,iy), ix increases to the right, and iy increases upwards.
% if m is 1D with nx^2 elements, we try to display it as an nx x nx image.
% If x and y vectors are given, they set the coordinate system and the 
% scaling of ticks.
% if a second argument sz is given, the image to be displayed is
% reshape(m,sz). Or, if m is 1D and no second argument is given, we assume
% sz=floor(sqrt(ne))*[1 1] and do the reshaping anyway, discarding extra
% elements.
% If an output argument h is given, the function returns the handle to the
% image object.
nl=256;  % number of levels in the colormap

if nargin==3
    if isa(m,'integer')
        m=single(m);
    end;
    m=squeeze(m);
    mn=min(min(m));
    mx=max(max(m));
    if (mx-mn)<eps*max(1,(mx+mn))  % Nothing there: show gray
        mx=mx+1;
        mn=mn-1;
    end;
    h=imaga(x,y,nl*(m-mn)/(mx-mn));
    
else % no scale arguments, just display the x variable.
    if nargin==2
        x=reshape(x,y);  % second argument is reshape variable
    end;

    if isa(x,'integer')
        x=single(x);
    end;
    x=squeeze(x);
    if ndims(x)>3
        x=x(:,:,1);  % take only the first plane.
    end;
    n=size(x);
% %     given a 1D vector, try to convert it to a square image
%     if any(n(1:2))==1 && mod(sqrt(n(1)),1)==0
%         n(1:2)=sqrt(n(1))*[1 1];  % a 1d vector
%         x=reshape(x,n);
%     end;
    mn=min(min(x));
    mx=max(max(x));
    if (mx-mn)<eps*max(1,(mx+mn))  % Nothing there: show gray
        mx=mx+1;
        mn=mn-1;
    end;
    h=imaga(nl*(x-mn)/(mx-mn));
end;
if nargout<1
    clear h
end;
