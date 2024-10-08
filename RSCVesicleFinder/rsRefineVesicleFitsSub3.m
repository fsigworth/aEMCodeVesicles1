function [miNew,vesFit]=rsRefineVesicleFitsSub(miOld,ms,mb,pars,displayOn)
% Do the vesicle refinement.  miOld is the original mi file; miNew is a
% copy with model parameters, vesicle.extraPeaks and vesicle.extraSD set.
%  ms is the 'small' image, downsampled to about 8A/pixel. mb is the 'big'
%  image, about 4A/pixel.
% pars.rTerms is a vector of radii in A, setting the number of terms in the fit.
%  e.g. rTerms=[90 120 160 200 inf] causes all vesicles with r<90A to be
%  fitted only with one term (spherical)
% Default parameter values:
dpars.rTerms=[100 150 200 250 250 300 inf];
dpars.fitMode='RadiusAndLin';
dpars.fractionStartingTerms=1; % total terms to use in each round
dpars.fracAmpTerms=1;
dpars.extraPeaks=[-30 0 30];  % in pixA.
dpars.extraSD=5; % width of extra Gaussian peaks, in angstrom
dpars.pixAWork=10;  % downsampled image resolution for radius fitting
dpars.doPreSubtraction=1;
dpars.listFits=0;
dpars.limitOrigNTerms=4;
dpars.stepNTerms=3;
dpars.maxVesiclesToFit=inf;
dpars.radiusStepsA=0;
dpars.disA=1200;  % display/fitted window size in angstroms
dpars.M4=zeros(3,3,'single');
dpars.M8=zeros(3,3,'single');
dpars.nRoundIters=300;  % simplex iters
dpars.preserveOldRadiusTerms=0;
dpars.nTermsForExtraRound=5;

% Merge the defaults with the given mpars
pars=SetOptionValues(dpars,pars);

ps=struct; % structure to pass to sub-function for small fits

minRadiusA=45; % smallest vesicle radius

doFitAmp=1; % linear fit of amplitudes to full-size image
doFitRadius=1; % nonlinear fit
minAmpValue=1e-5; % negligible amp threshold

switch pars.fitMode
    case 'LinOnly'
        doFitRadius=0;
    case 'RadiusOnly'
        doFitAmp=0;
    case 'RadiusAndLin'
    otherwise
        warning(['Unrecognized fitMode: ' pars.fitMode]);
end;

doFitRadius
doFitAmp

maxMaskLayers=2;   % Don't include any masking beyond merge and beam
useOkField=1;      % refine every vesicle for which ok is true.
disA=pars.disA;          % size of displayed/fitted window in angstroms
fHP=.0003;          % Gauss high-pass filter for fitting: 300 A^-1
disFc=.1;
nZeros=1;          % number of zeros used in the merged CTF

%       Calculate variance from .30 to .45 x Nyquist; this is faster than using RadialPowerSpectrum:
ns=size(ms);       % Size of the 8A image.
% pick the frequency range with an annulus in freq domain
annulus=fuzzymask(ns,2,0.225*ns,.05*ns)-fuzzymask(ns,2,0.15*ns,.05*ns);
spc=annulus.*fftshift(abs(fftn(ms)).^2)/(prod(ns));
ps.hfVar=sum(spc(:))/sum(annulus(:));

nv=numel(miOld.vesicle.x);

% Create the new mi structure
miNew=miOld;
% Set the extra peaks
miNew.vesicle.extraPeaks=pars.extraPeaks;
miNew.vesicle.extraSD=pars.extraSD;
% Insert the new 'active fraction' field.
if ~isfield(miNew.vesicle,'af') || numel(miNew.vesicle.af)~=nv  % active fraction (= unmasked)
    miNew.vesicle.af=ones(nv,1,'single');
end;

%%  Get the original subtraction, and modify the amplitudes if necessary.
% miNew should be pretty much the same as miOld except for the fields
% vesicle.extraPeaks and vesicle.extraSD.
%
nPeaks=numel(miNew.vesicle.extraPeaks);

sVals=miOld.vesicle.s(:,1,1);  % Copy the basic amplitude
sVals(isnan(sVals)|sVals<minAmpValue)=0;
miNew.ok(sVals==0,:)=false;  % zero or negative assigned to be null vesicles.

% Determine the number of terms for radius and amplitude fitting
maxNTerms=numel(pars.rTerms); % maximum number of terms allowed.
nSTerms=maxNTerms;

miNew.vesicle.s=zeros(nv,nSTerms,nPeaks+1);
miNew.vesicle.s(:,1,1)=sVals;

% Make vesicle.r have the correct number of elements
miNew.vesicle.r(:,end+1:maxNTerms)=0;
miNew.vesicle.r(:,maxNTerms+1:end)=[];

nvToFit=sum(miNew.vesicle.ok(:,1));
nvToFit=min(nvToFit,pars.maxVesiclesToFit);
disp([num2str(nvToFit) ' vesicles to fit.']);
vesList=find(miNew.vesicle.ok(:,1)); % fit everything with ok(:,1) true.

% Get the scaling structure for the small image size.
scls=struct;
scls.n=ns;
scls.M=pars.M8;
dss=scls.M(1,1);
pixAs=dss*miOld.pixA; % pixel size of the image we're given.

%   Compute the old subtraction (small image size)
nsPW=meGetNoiseWhiteningFilter(miOld,ns,dss,nZeros,fHP*pixAs);
nsCTF=meGetEffectiveCTF(miOld,ns,dss);
msf=real(ifftn(fftn(ms).*ifftshift(nsPW)));  % High-pass filtered image, no CTF
if pars.doPreSubtraction
    vs=meMakeModelVesicles(miOld,scls,vesList,0,0); % no ctf or prewhitening
    vsf=real(ifftn(fftn(vs).*ifftshift(nsPW.*nsCTF)));
else
    vsf=0;
end;

% Get the CTF information for the fitting regions
% --'small' image
nds=NextNiceNumber(disA/pixAs);  % size of display/fitting image
ndsPW=meGetNoiseWhiteningFilter(miOld,nds,dss,nZeros,fHP*pixAs);
ndsCTF=meGetEffectiveCTF(miOld,nds,dss);

% --'big' image
    dsb=pars.M4(1,1); % downsampling of the big image mb
    pixAb=dsb*miOld.pixA;
    nb=size(mb);
if doFitAmp  % Get big-sized CTF and PW functions also
    sclb.n=nb;
    sclb.M=pars.M4;
    nbPW=meGetNoiseWhiteningFilter(miOld,nb,dsb,nZeros,fHP*pixAb);
    nbCTF=meGetEffectiveCTF(miOld,nb,dsb);
    mbf=real(ifftn(fftn(mb).*ifftshift(nbPW)));  % High-pass filtered image
    
    if displayOn
        figure(1);
        clf;
        mysubplot(3,2,1);
        imags(GaussFilt(mbf,disFc*dsb));
        title(['Prewhitened image ' miOld.baseFilename],'interpreter','none');
        drawnow;
    end;
    %     Make a big-sized model for subtraction
    if pars.doPreSubtraction
        vb=meMakeModelVesicles(miOld,sclb,vesList,0,0);
        vfb=real(ifftn(fftn(vb).*ifftshift(nbPW.*nbCTF)));
        if displayOn
            mysubplot(3,2,2)
            imags(GaussFilt(mbf-vfb,disFc*pixAb));
            title(['Preliminary subtraction ' miOld.baseFilename],'interpreter','none');
        end;
    else
        vfb=0;
    end;
    drawnow;
    ndb=NextNiceNumber(disA/pixAb);  % size of fit for full-size image
    ndbPW=meGetNoiseWhiteningFilter(miOld,ndb,dsb,nZeros,fHP*pixAb);
    ndbCTF=meGetEffectiveCTF(miOld,ndb,dsb);
end;

%  If amplitude values are tiny, we force them to a default value.
smallAmps=miOld.vesicle.s(:,1)<minAmpValue; % More than an order of magnitude too small.
miOld.vesicle.s(smallAmps,:)=0;
% miOld.vesicle.s(smallAmps,1)=minAmpValue;

%         Get the masks
layers=1:min(maxMaskLayers,numel(miOld.mask));
msmask=Crop(meGetMask(miOld,round(miOld.imageSize/dss),layers),ns);
mbmask=Crop(meGetMask(miOld,round(miOld.imageSize/dsb),layers),nb);


%%  Actual fitting is done here
if displayOn
    figure(2);
end;
miNew.vesicle.ok(:,3)=miNew.vesicle.ok(:,1);  % we'll mark unfitted vesicles here.

if pars.listFits
    disp('  ind   1000s    r (A) pick   ok     nTerms ------- 100s/s(1) -------------');
    %        1    2.779     205   2  1 1 1 1    4    24.80   23.71    0.00    0.00   0
end;

for j=1:nvToFit  % Loop over vesicles
    ind=vesList(j);
    ok=miOld.vesicle.ok(ind,1);  % The vesicle exists
    if (~ok && useOkField) || miOld.vesicle.s(ind,1,1)==0
        continue;  % skip this vesicle.
    end;
    
    %             Look up the number of radius terms to use.
    %             rTerms is something like [150 200 250 300 350 400 inf];
    %             r<150A gets 1 term; <200 gets 2 terms; etc.
    finalNRTerms=find(miNew.vesicle.r(ind,1)<pars.rTerms/miNew.pixA,1);
    % Set the number of amplitude terms.
    finalNSTerms=max(1,ceil(finalNRTerms*pars.fracAmpTerms)); % Always >=1
    %             We'll do multiple rounds of fitting.  We first see how much
    %             we'll be expanding the number of terms from previously.
    % The typical limitOrigNTerms is 4.
    origNRTerms=pars.limitOrigNTerms;
%     origNRTerms=min(pars.limitOrigNTerms,sum(miOld.vesicle.r(ind,:)~=0));
    stepNRTerms=pars.stepNTerms; % we'll set this as a parameter, typ. 3
    nRRounds=1+max(0,ceil((finalNRTerms-origNRTerms)/stepNRTerms));
    
    origNSTerms=max(1,ceil(origNRTerms*pars.fracAmpTerms));
    stepNSTerms=max(1,ceil((finalNSTerms-origNSTerms)/3));
    nRounds=max(nRRounds,2);
    %             Set up the number of terms we'll fit for each round
    ps.nTerms=zeros(nRounds,2); % no. terms in round for [r s]

    for i=1:nRounds
%         No. of terms for each round for radius fitting
        ps.nTerms(i,1)=min(finalNRTerms,ceil(origNRTerms+(i-1)*stepNRTerms));
%           No. of terms for each round of amp fitting
        ps.nTerms(i,2)=min(finalNSTerms,origNSTerms+(i-1)*stepNSTerms);
    end;
    %%%% rConstraints set here. Limit the magnitude of higher terms
    ps.rConstraints=ones(finalNRTerms,1);
%     ps.rConstraints(2:finalNRTerms)=0.4./((2:finalNRTerms).^2)';
    ps.rConstraints(2:finalNRTerms)=2/((2:finalNRTerms).^1.5)'; %%%%%%
    ps.nRoundIters=pars.nRoundIters;
    ps.preserveOldRadiusTerms=pars.preserveOldRadiusTerms;
    ps.nTermsForExtraRound=pars.nTermsForExtraRound;
    %-------------------Basic fit------------------
    if doFitRadius % we're doing nonlinear fit
        if pars.doPreSubtraction
            %                 First, compute the old model of the one vesicle in question
            vs1=meMakeModelVesicles(miOld,scls,ind,0,0); % no ctf or prewhitening
            vs1f=real(ifftn(fftn(vs1).*ifftshift(nsPW.*nsCTF)));  % filtered model
        else
            vsf=0;
            vs1f=0;
        end;
        ps.M=pars.M8;
        %         Repeated fits with perturbed initial radius
        ndr=numel(pars.radiusStepsA);
        miTemps=cell(ndr,1);
        errs=zeros(ndr,1);
        ps.amps=zeros(ndr,1);  % keep track of previous amplitudes.
        resImgs=zeros(nds,nds,ndr,'single');
        for jr=1:ndr
            %             Perturb the radius
            miInput=miNew;
            rStep=pars.radiusStepsA/miInput.pixA;
            newR1=max(miInput.vesicle.r(ind,1)+rStep(jr),minRadiusA/miInput.pixA);
            miInput.vesicle.r(ind,1)=newR1; % Replace the constant radius


            %      --------------nonlinear fitting---------------
            [miTemps{jr},fitIms,vesFits]=rsQuickFitVesicle2(msf-vsf,vs1f,msmask,miInput,...
                ind,ndsCTF.*ndsPW,ps,displayOn);
            errs(jr)=miTemps{jr}.vesicle.err(ind);

            
            if displayOn
                resImgs(:,:,jr)=fitIms-vesFits;
                subplot(3,2,4);
                imags(resImgs(:,:,jr));
                title(num2str([jr finalNRTerms]));
                drawnow;
            end;
        end;
        %         Find the best fit
        [~,jr]=min(errs);
        [~,jr0]=min(abs(pars.radiusStepsA)); % the step that is our nominal radius
        
        miNew=miTemps{jr};
        if displayOn && ndr>1 % show the various fit results
%             figure(1);
            nCols=max(4,ndr);
            for k=1:ndr
                mysubplot(6,nCols,nCols*4+k);
                imags(resImgs(:,:,k));
                if k==jr
                    str='***';
                else
                    str='';
                end;
                title([num2str(errs(k)) str]);
            end;
%             figure(2);
        end;
    end;
    %   ----------------- Linear fit only --------------
    if doFitAmp % do a linear fit of the vesicle
        jr=1;
        jr0=1;
        if pars.doPreSubtraction
            v1=meMakeModelVesicles(miOld,sclb,ind,0,0);
            v1f=real(ifftn(fftn(v1).*ifftshift(nbPW.*nbCTF)));  % filtered model
        else
            v1=0;
            v1f=0;
        end;
        pb=ps;
        pb.nTerms=[0 ps.nTerms(end,end)];
        pb.M=pars.M4;
        %                 Do a fit of only the amplitude terms
        [miNew,fitIm,vesFit]=rsQuickFitVesicle2(mbf-vfb,v1f,mbmask,miNew,...
            ind,ndbCTF.*ndbPW,pb,displayOn & ~doFitRadius);  % no display
        
        if displayOn  % update the subtracted image
            subplot(3,2,4);
            imags(GaussFilt(fitIm-vesFit,pixAb*disFc)); % 20 A filter
            drawnow;
        end;
    else
        vesFit=vesFits;
    end;
    
    nsTerms=size(miNew.vesicle.s,2);
    ampString=repmat('%6.2f  ',1,nsTerms-2);
    if pars.listFits
        str=sprintf(['%4d %8.3f  %6.1d  %2d  %2d%2d%2d%2d  %2d  ' ampString],...
            ind, 1000*miNew.vesicle.s(ind,1),...
            round(miNew.vesicle.r(ind,1)*miNew.pixA),...
            jr-jr0,...
            miNew.vesicle.ok(ind,:), sum(miNew.vesicle.r(ind,:)~=0),...  % insert s(1)
            100*abs(miNew.vesicle.s(ind,3:end,1))/miNew.vesicle.s(ind,1,1));
        disp(str);
    end;
end;

%         Disallow negative amplitudes, and nan values
for i=1:nv
    miNew.vesicle.s(isnan(miNew.vesicle.s))=0;
    if any(isnan(miNew.vesicle.s(i,:)))
        miNew.vesicle.s(i,:)=0;
        miNew.vesicle.ok(i,:)=0;
    end;
end;
numberRefined=sum(miNew.vesicle.ok(:,3))
numberGood=sum(all(miNew.vesicle.ok(:,1:3),2))  %    exists, in range, refined
miNew.vesicle.refined=1;


