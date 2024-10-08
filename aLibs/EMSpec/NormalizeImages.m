function [out,means,vars]=NormalizeImages(m,varNormalize,applyMask,globalNorm)
% function [out,means,vars]=NormalizeImages(m,varNormalize,applyMask,globalNorm)
% Normalize each image in an image stack for classification and alignment.
% Images are assumed to be square.
% Defaults are varNormalize=1 and applyMask=1; globalNorm=0.
% We use an annulus for estimating variance and mean value.  We normalize
% it so that the annulus mean is zero and variance is unity.  If mask=1 a
% circular mask is also applied to the returned images, 
% 95% of max radius. if globalNorm then the
% norm is computed for the entire stack, not individual images.

if nargin<4
    globalNorm=0;
end;
if nargin<3
    applyMask=1;
end;
if nargin<2
    varNormalize=1;
end;
OutR=0.6;  % Outer radius
InR=0.4;   % Inner radius
Rise=0.05;   % Feathering of masks

[n, ny, nim]=size(m);

% Make the masks for normalizing images
Masko=fuzzymask(n,2,OutR*n,Rise*n); % Outer mask at 90% of radius
Maski=fuzzymask(n,2,InR*n,Rise*n); % Inner mask at 75% of radius
AnnMask=Masko-Maski;  % Annular mask for measuring mean and variance
AnnMaskSum=sum(AnnMask(:));

out=single(zeros(n,n,nim));
vars=zeros(nim,1);
means=zeros(nim,1);
am2=AnnMask(:)'*AnnMask(:);
for i=1:nim
    m0=double(m(:,:,i));
    m1=AnnMask.*m0;  % Pick out the annulus to estimate mean and variance
    means(i)=sum(m1(:))/AnnMaskSum;
    msub=m0-means(i);
    m2=AnnMask.*msub;
    var=m2(:)'*m2(:)/am2;
    
    % Apply outer mask
    if applyMask
        m1=Masko.*msub;
    else
        m1=msub;
    end;
    if ~globalNorm && varNormalize && var>1e-12 % avoid division by zero
        m1=m1/sqrt(var);
    end;
    vars(i)=var;
    out(:,:,i)=m1;
end;
if globalNorm
    out=out/sqrt(median(vars));
end;
