function ShowZSections( map, numimages, step, indepscale )
%function ShowZSections( map, numimages, step, indepscale );
%
% If indepscale = 0 then all the images are scaled to the same
% range (default); otherwise each image is autoscaled.
% 
%
SetGrayscale;

[nx ny nz]=size(map);
if nargin < 4
	indepscale=0;
end;
if nargin < 3
	step=1;
end;

if nargin < 2
	numimages = nz;
end;

if (step > 1) || (numimages ~= nz) 
	nz=min(nz,numimages*step);
	map=map(:,:,1:step:nz);
end;
mn=min(min(min(map)));
mx=-min(min(min(-map)));

% scale the map for display
map=(map-mn)*256/(mx-mn);

nr=max(1,floor(sqrt(numimages)));
nc=ceil(numimages/nr);
for i=1:numimages
    z=i;
% 	z=(i-1)*step+1;
	if z>nz
		break
	end;
	subplot(nr,nc,i);
	if indepscale
		imacs(map(:,:,z));
	else
	 	imac(map(:,:,z));
	end;
	axis off;
	title(num2str(z));
end;

