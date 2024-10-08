function ShowSections( map, x, y, z )
% function ShowSections( map, x, y, z );
% Show sections of the 3d map, and the
% three orthogonal projections.  The optional arguments
% (x,y,z) are the
% coordinates at which the sections are taken.
%
SetGrayRed;
[nx ny nz]=size(map);
if nargin<4
	x=ceil(nx/2);
	y=ceil(ny/2);
	z=ceil(nz/2);
end;
mn=min(min(min(map)));
mx=-min(min(min(-map)));
% mx=1.3e5;
ds=255/(mx-mn);
db=-mn*ds;
smap=map*ds+db;

smap(x,y,:)=256;
smap(:,y,z)=256;
smap(x,:,z)=256;
subplot(3,3,1);

image(squeeze(smap(x,:,:)));
xlabel('Z');
ylabel('Y');
axis image;

subplot(3,3,2);
image(squeeze(smap(:,y,:)));
xlabel('Z');
ylabel('X');
axis image;
title('Sections');

subplot(3,3,3);
image(squeeze(smap(:,:,z)));
xlabel('Y');
ylabel('X');
axis image;

% show projections
subplot(3,3,4);
imagesc(squeeze(sum(map)));
axis image;
axis off;

subplot(3,3,5);
imagesc(squeeze(sum(shiftdim(map,1)))');
axis image;
axis off;
subplot(3,3,6);
xy=squeeze(sum(shiftdim(map,2)));
imagesc(xy);
axis image;
axis off;

subplot(3,3,7);
zf=squeeze(map(x,y,:));
plot(zf);
xlabel('Z');
% hold on;

subplot(3,3,8);
title('Projections');
axis off;

% subplot(3,3,9);
% % yf=squeeze(map(x,:,z));
% % plot(yf);
% % xlabel('Y');
% % hold on;
% % 
% contour(xy);
% axis ij
% axis equal;
% axis image;
