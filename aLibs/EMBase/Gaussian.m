function m = Gaussian(n,dims,sigma,org)
% function m = Gaussian(n,dims,sigma,org)
% Make a Gaussian function m=exp(-x.^2/(2*sd^2))
% with the given number of dimensions and standard
% deviation sigma (in units of points) centered on the given origin vector.
% ** For example, the GaussFilt discrete frequency response has
% sigma=sqrt(fc*n/sqrt(log(2)), and its real-space kernel will be
% normalized and have sigma=.133/fc.
% For 2 and 3d Gaussians, sigma may have 2 or 3 elements.
% The result is not normalized.  Its integral will be (2*pi*sigma^2)^(dims/2)
% 
% 2 Jul 17: first inserted a spurious 2 in the denominator.
% 20 Aug 18: removed it.

ctr=floor(n/2)+1;  % default center is appropriate for ffts.
sd=sqrt(2)*sigma;

switch dims
    case 1
        if nargin<4
            org = ctr;  % Coordinate of the center
        end;
        r=(1-org(1):n-org(1))'/sd;
        r2=r.^2;
        
    case 2
        if nargin<4
            org = [ctr ctr]; % Coordinates of the center
        end;
        if numel(n)<2
            n(2)=n(1);
        end;
        if numel(sd)<2
            sd(2)=sd(1);
        end;
        if numel(org)<2
            org=[org org];
        end;
        [x,y]=ndgrid((1-org(1):n(1)-org(1))/sd(1),(1-org(2):n(2)-org(2))/sd(2));
        r2=x.^2+y.^2;
        
    case 3
        if nargin<4
            org = [ctr ctr ctr]';  % Coordinate of the center
        end;
        if numel(n)<3
            n=n(1)*[1 1 1];
        end;
        if numel(sd)<3
            sd=sd(1)*[1 1 1];
        end;
        if numel(org)<3
            org=org(1)*[1 1 1];
        end;
        
        [x,y,z]=ndgrid((1-org(1):n(1)-org(1))/sd(1),...
                       (1-org(2):n(2)-org(2))/sd(2),...
                       (1-org(3):n(3)-org(3))/sd(3));
            r2 = x.^2 + y.^2 + z.^2;
    otherwise
        error(['Number of dimensions out of bounds: ' num2str(dims)]);
end;

m=exp(-r2);
