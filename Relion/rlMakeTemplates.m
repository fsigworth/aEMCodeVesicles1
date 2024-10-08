function templates=rlMakeTemplates(templateAngles,map,dotCount,shifts)
% function templates=rlMakeTemplates(templateAngles,map,dotCount,shifts)
% Given an array nim x 3 of templateAngles (in degrees), compute projections
% of the 3D map using the gridding functions.
% if the optional dotCount>0, write a dot to the command window every dotCount
% projections to show progress.
nangs=size(templateAngles,1);

if nargin<3
    dotCount=0;
end;
if nargin<4
    shifts=zeros(nangs,2,'single');
end;
n=size(map,1);
if mod(n,8)
    error('Map size must be a multiple of 8');
end;

ks=3; % kernel size is always 3.

templates=single(zeros(n,n,nangs));
comp=gridMakePreComp(n,ks);  % Make the pre-compensation function (a 1D array)

F3=gridMakePaddedFT(map,'grid',comp);  % get the 3D fft in a form for slicing.

angs=templateAngles*pi/180;  % convert to radians
for i=1:nangs
    P2=gridExtractPlane(F3,angs(i,:),ks);  % angs is an n x 3 matrix of Euler angles (radians)
    templates(:,:,i)=gridRecoverRealImage(P2,1,shifts(i,:));     % get the un-padded projection image
    if dotCount>0 && mod(i,dotCount)==0
        fprintf('.');
        if mod(i,dotCount*50)==0
            fprintf('\n');
        end;
    end;
end;
if dotCount>0
    fprintf('\n');
end;
