function angles=axesToEuler(axes)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Converts my old style axes (9 \times N) to Euler angles
% that are standard in cryoEM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nAxes=size(axes,2);

%Get the individual X,Y,X axes (wikipedia convention)
X=axes(1:3,:);
Y=axes(4:6,:);
Z=axes(7:end,:);

%Calculate angles
psi=atan2(Z(2,:),-Z(1,:));
% Make psi positive
psiNeg=double(psi<0);
psi=(1-psiNeg).*psi+psiNeg.*(2*pi+psi);


theta=acos(Z(3,:));
phi=atan2(Y(3,:),X(3,:));
% Make phi positive
phiNeg=double(phi<0);
phi=(1-phiNeg).*phi+phiNeg.*(2*pi+phi);

angles=[phi' theta' psi'];
