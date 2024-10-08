function miOut=CheckVesicleOverlaps(mi)
% CheckVesicleOverlaps
ovThresh=.3;  % threshold for being an overlap

nv=numel(mi.vesicle.x);
n=mi.imageSize/8;
n2=prod(n);
vesNorms=zeros(nv,1);
vesImgs=zeros([n nv],'single');

% Force unit amplitude for the vesicle cross-sections
mi1=mi;
mi1.vesicle.s=0*mi1.vesicle.s;
mi1.vesicle.s(:,1)=1;

disp('Making model vesicles');
for i=1:nv
%     Compute cross-section images
    v1=meMakeModelVesicles(mi1,n,i,0,0,1);
    vesImgs(:,:,i)=v1;
    vesNorms(i)=sqrt(v1(:)'*v1(:));
end;
% Get the cross-matrix
disp('Computing the cross-matrix');
v2=reshape(vesImgs,n2,nv);
crossNorms=vesNorms*vesNorms';
cross=v2'*v2;
cross=cross./crossNorms-eye(nv,nv);
% imaga(cross*256)

np=0; % number of peaks found
mxInd=[];
mxVal=[];
nPruned=0;
nDeleted=0;
vesOk=mi.vesicle.ok;
[val,ind]=max(cross(:));
while val>ovThresh
%     cross(ind)=0;
    np=np+1;
%     mxInd(np)=ind;
%     mxVal(np)=val;
%     cross(ind)=0;
    [i,j]=ind2sub([nv nv],ind);
%     disp(num2str([ i j vesOk(i,:) vesOk(j,:)]));
    if all(mi.vesicle.ok([i j],1)) % both are valid vesicles
        if all(vesOk([i j],3)) % both are refined
            nPruned=nPruned+1;
            vesOk(j,:)=0; % arbitrarily zero out the second one.
        elseif vesOk(i,3)
            vesOk(j,:)=0; % zero out the unrefined one
            nDeleted=nDeleted+1;
        else
            vesOk(i,:)=0;  % zero out the unrefined one.
            nDeleted=nDeleted+1;
        end;
    end;
%     Delete the pair from cross correlations
    cross(i,j)=0;
    cross(j,i)=0;
    [val,ind]=max(cross(:));
end;

vesOk(~vesOk(:,1),:)=0; % any unfound vesicle is zeroed completely.

% nPruned
% nDeleted
% 
% [is,js]=ind2sub([nv nv],mxInd');
% 
% disp(num2str([is js round(mxVal'*100) vesOk(is,:)]));
% 
miOut=mi;
miOut.vesicle.ok=vesOk;

return
