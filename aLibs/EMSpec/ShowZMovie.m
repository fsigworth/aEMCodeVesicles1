function ShowZMovie( map, numimages, frametime, indepscale );
%function ShowZSections( map, [numimages, frametime, indepscale] );
%
% Default frametime is 0.2 seconds.
% If indepscale = 0 then all the images are scaled to the same
% range (default); otherwise each image is autoscaled.
% 
%
SetGrayscale;
set(gcf,'doublebuffer','on');

[nx ny nz]=size(map);
if nargin < 4
	indepscale=0;
end;
if nargin < 3
	frametime=0.2;
end;
if nargin < 2
	numimages = inf;
end;

numimages = min(nz, numimages);
mn=min(min(min(map)));
mx=-min(min(min(-map)));

% scale the map for display
map=(map-mn)*256/(mx-mn);

for i=1:numimages
	if indepscale
		imacs(map(:,:,i));
	else
	 	imac(map(:,:,i));
	end;
	axis off;
	title(i);
    pause(frametime);
end;

