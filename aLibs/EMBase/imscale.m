function [ms, mulr, addr]=imscale(m,range,sds)
% function [ms mulr addr]=imscale(m,range,sds)
% Autoscale an image for display, assuming a grayscale of 'range' elements.
% The default range is 256.
% If sds>1 the image will be scaled so that [0..range-1] corresponds to mean-sds
% to mean+sds in value, where sds is the number of standard deviations.  If
% 0 < sds < 1 then sds is an outlier probability, and the range of gray
% values will be truncated to exclude n*sds values from both the lower and
% upper end of the histogram, where n is the total number of pixels.  If
% sds is a vector, n*sds(1) will be excluded at the low end, and n*sds(2)
% from the high end.
% Default value for sds is 0 (pure maximum and minimum).
% The extra output variables allow the scaling to be reproduced, i.e. as
% ms=m*mulr+addr.

% fs revised Jun09, Jan12

maxBins=1e6;  % Bins of histogram for probability calculation.

if nargin<2 || numel(range)<1 || range==0
    range=256;
end;
if isa(m,'integer')  % auto-conversion of integer to single values.
    m=single(m);
end;
if nargin<3
    sds=[0 0];
end;
if numel(sds)<2
    sds=[1 1]*sds;
end;
if any(sds>0)  % compute according to the standard deviation or
                      % residual probability
    if any(sds>=1) % number of standard deviations
        s=std(m(:));
        me=mean(m(:));
        mn=me-sds(1)*s;
        mx=me+sds(2)*s;
    else % use sds as distribution limits.
        np=numel(m);
        [~,inds]=sort(m(:));
        mnp=round((np-1)*sds(1)+1); % lowest pixel value
        mxp=round(np-(np-1)*sds(2)); % highest pixel value
        mn=m(inds(mnp));
        mx=m(inds(mxp));
%         
%         
%         mn=min(m(:));
%         mx=max(m(:));
%         s=std(m(:));
%         dx=s/100;  % step size for histogram
%         if dx<(mx-mn)/maxBins
%             dx=(mx-mn)/maxBins;
%         end;
%         n=numel(m);
%         xvals=mn:dx:mx;
%         h=hist(m(:),xvals);
%         cd=cumsum(h);  % cumulative distribution
%         mn=xvals(find(cd>n*sds,1,'first'));
%         mx=xvals(find(cd<n-n*sds,1,'last'));
    end;   
else
    mn=min(m(:));
    mx=max(m(:));
end;
if (mx-mn)<eps*max(1,(mx+mn))  % Nothing there: show gray
    mx=mx+1;
    mn=mn-1;
end;
mulr=(range)/(mx-mn);
addr=-mn*mulr;
ms=mulr*m+addr;
ms(ms<0)=0;
ms(ms>range)=range;
