% StackExtractor2m.m
% Simplified version that works directly from the merged image.
% For each particle, extract its region from the merged image; rotate the
% merged particle to the standard position, if desired
% (writeIndividualStacks=1) write *st.mrc and *stu.mrc files (stack and
% unsubtracted stack) into the Stack/ directory.  Also store *tstack.mrc
% and *tustack.mrc, the merged subtracted and unsubtracted stacks from all
% images, and *tsi.mat which contains the total si structure. Contrast is
% reversed so protein is white.
% We now support various merge modes, and use meComputeMergeCoeffs3 to do
% proper scaling.

%boxSize=96;  % Size of boxes to be extracted from merged images.
boxSize=384;  % Size of boxes to be extracted from merged images.
%boxSize=216;
% boxSize=256;
ds=1;        % downsampling of boxed particles from original micrograph

 fHP=.001;    % highpass Gauss filter in A^-1
types=[16 32]; % flags for valid particles
restoreFromSiFile=0; % Use info from an si file instead of mi files.

% upsample the vesicle models?
upsampleSubtractedImage=0;
%altBasePath='../KvLipo121_2retrack/';
altBasePath='';
vus=2;  % default upsampling factor (used if we construct vesicle models)

% Options for Relion are 3,0,0 respectively:
%mergeMode=2;  % new merging, changed to 1st exposure's ctf, flipped.
mergeMode=3;  % 1: original merging is left untouched.
noDamage=0;   % use damage-filtering
doAlphaRotation=0; % rotate in-plane according to position on vesicle
usePWFilter=0;  % prewhitening filter
removeOutliers=0;
setWeights=0;  % if nonzero, force the si.weights to this value.
%%setWeights=[1 0];  % if nonzero, force the si.weights to this value.
minImageSD=.01;  % if std of image is below this, don't use it

doExtractParticles=1;
showAllParticles=0;  % display each particle as the program runs.
cpe0=0.8;     % default value, if not already in mi file
resetBasePath=0;
updateMiFile=0; % write out modified mi file.
useCorrection=0;  % Use local vesicle modeling to refine vesicle subtraction
useCircularVesicleModels=0;  % ignore higher-order terms in the vesicle model, for experimentation purposes

writeIndividualStacks=0;  % Write stack files for each micrograph too.
writeUnsubtractedStack=1;

tempStackName='TempStack2.mrc';
tempUStackName='TempUStack2.mrc';

setOk4=0;  % force the unused field mi.vesicle.ok(:,4) to 1.
% mergeSuffixes={'' 'sf' 'su' 'si'}; % Suffix for merged image name, indexed by mergeMode.
inputModeSuffix=''; % expected suffix for input files

% Output file naming
stackDir='Stack1/';
dirVesicles='Vesicles/'; % location of modeled vesicle images
stackSuffix='tstack.mrc';
ustackSuffix='tustack.mrc';

% Output name is constructed thusly:
% [baseName weightString pwString sizeString corrString modeSuffix];
% e.g. name1.w11.f.p64.noParticles.m3
weightString='m1r'; % string in output file name
%weightString='pk2'; % string in output file name

defaultMembraneOffsetA=52;

% Where do we get vesicle models?
readVesicleModels=0;  % load vesicle images from files rather than making models on the fly.
readSubtractedImages=1; % load subtracted images from *mv files in Merged/ directory

writeVesicleModels=0;
writeSubtractedImages=0;
nZeros=1;  % number of zeros in 2nd exposure kept in merging
ignoreOldActiveFlags=0;

clear log % We had the error that the log function was overloaded.


% % %%%%%%%%%% Special options for non-particle stack %%%%%%%%
% boxSize=80;
% fHP=0;
% usePWFilter=0;
% types=[48 48];
% mergeMode=13;
% restoreFromSiFile=0;
% noDamage=0;
% setWeights=0;
% weightString='blanks';
% writeUnsubtractedStack=0;
% writeSubtractedImages=0;
% readSubtractedImages=0;
% % %%%%%%%%%%%%%  End special options


% dsScale=ds^2/4;  % fudge for vesicle model, don't really understand yet.
dsScale=1;   % scaling that depends on downsampling ratio
dds=2;       % further downsampling for micrograph display
vindex=0;    % 0 means force all vesicles to be modeled
padSize=NextNiceNumber(boxSize*1.5);
% Make the upsampled pad mask, and the particle fourier mask
padMask=fuzzymask(padSize,2,padSize*.48,padSize*.04);
fmasko=ifftshift(fuzzymask(padSize,2,.45*padSize,.05*padSize));

if restoreFromSiFile
    disp('Select si file');
    [oldSiName,pa]=uigetfile('*si.mat','Select si file to read');
    oldSi=load([AddSlash(pa) oldSiName]);
    miFiles=oldSi.si.mi;
%     oldActiveFlags=oldSi.si.activeFlags;
%     oldActiveFlagLog=oldSi.si.activeFlagLog;
else
    oldSiName='';
    disp('Select mi files');
    [miFiles, pa]=uigetfile('*mi.txt','Select mi files','multiselect','on');
    if ~iscell(miFiles)
        miFiles={miFiles};
    end;
end;

if isnumeric(pa)  % user clicked Cancel
    return
end;

[rootPath, infoPath]=ParsePath(pa);
cd(rootPath);
if ~exist(stackDir,'dir')
    mkdir(stackDir);
end;

CheckAndMakeDir(stackDir,1);
%%
% Initialize the si structure
totalNParts=0;
np=1e6;  % preliminary stack size
si=struct;
si.miIndex=     uint16(zeros(np,1));
si.miParticle=  uint16(zeros(np,1));
si.alpha0=      single(zeros(np,1));
si.yClick=      single(zeros(np,1));  % in units of si.pixA
si.rVesicle=    single(zeros(np,1));
si.sVesicle=    single(zeros(np,1));
si.mi=cell(0);
nfiles=numel(miFiles);
badFlags=false(np,1);
iCoordsList=zeros(np,2,'single');
ctfs=zeros(boxSize,boxSize,nfiles,'single');
ctf1s=zeros(boxSize,boxSize,nfiles,'single');
pwfs=zeros(boxSize,boxSize,nfiles,'single');
pixA0=0;  % unassigned value
fh=0;   % temp stack file handles
fhU=0;  % temp unsubtracted stack file
sumTotalStack=0;
sumTotalStackU=0;
figure(1);
clf;

fileIndex=1;
%%  Scan over files
while fileIndex<= numel(miFiles)
    disp(['File index ' num2str(fileIndex)]);
    if restoreFromSiFile
        mi=miFiles{fileIndex};
        if any(setWeights)
            mi.weights=setWeights;
        end;
    else
        disp(['Reading ' miFiles{fileIndex}]);
        mi=ReadMiFile([infoPath miFiles{fileIndex}]);  % Load the mi file
    end;
    if isa(mi,'struct')  % a valid structure
        mi.basePath=rootPath;  % Reassign this
        if fileIndex==1
            modelSpectrum=CCDModelSpectrum2D(mi.camera);  % handle DE-12 or CCD
        end;
        % Make new entries into the mi file
        mi.boxSize=boxSize;
        mi.stackPath=AddSlash(stackDir);
        
        if isfield(mi.particle,'picks') && numel(mi.particle.picks)>0
            nPicks=size(mi.particle.picks,1);
            typeArray=mi.particle.picks(:,3);
            nParts=sum((typeArray>=types(1)) & (typeArray<=types(2)));

        else
            nPicks=0;
            nParts=0;
        end;
        n0=mi.imageSize/ds;
        %     Get the final pixel size
        pixA=mi.pixA*ds;
        if pixA0==0
            pixA0=pixA;
        end;
        if abs(pixA0-pixA)>.001
            warning(['Change in pixA values: ' num2str([pixA0 pixA]) '  ' miFiles{fileIndex}]);
        end;
        if fileIndex==1
            disp(['   box size in A, box size in pixels: ' num2str([round(boxSize*pixA) boxSize])]);
        end;
        
        si.mi{fileIndex}=mi;  % store a copy of the micrograph info

           disp('Read images');
            disp(mi.baseFilename)
            [mMergeU,pa,mImageOk]=meReadMergedImage(mi,0,inputModeSuffix);  % merged image
            subplot(1,2,1);
            imags(BinImage(mMergeU,dds));
            title(mi.baseFilename,'interpreter','none');
            drawnow;

%         Create filters, read images, subtract vesicles
        if mImageOk && (nParts>0 || writeVesicleModels) % there are particles, insert filter functions

            %      ----Particle-sized and micrograph-sized CTF and filter functions----
            nZeros=1;
            pFreqs=RadiusNorm(boxSize)/pixA; % particle-sized frequencies
            mFreqs=RadiusNorm(n0)/pixA;      % image-sized frequencies
            [pcoeffs, pEffCTF, pdctfs,pTi]=meComputeMergeCoeffs3(pFreqs,mi,nZeros,mergeMode);
            [mCoeffs,mEffCTF,mCTFs,mTi]=meComputeMergeCoeffs3(mFreqs,mi,nZeros,mergeMode);
            filterOk=usePWFilter;
            if filterOk
                pTi=pTi.*meGetNoiseWhiteningFilter(mi,boxSize,ds,nZeros,fHP*pixA,pEffCTF);  % for particle ctf
                [tTi,filterOk]=meGetNoiseWhiteningFilter(mi,n0,ds,nZeros,fHP*pixA,mEffCTF);  % for micrograph
                mTi=mTi.*tTi;
            else
                    disp('No pre-whitening.');
            end;
            if fHP>0
                k=(log(2)/2)*fHP.^2;
                pTi=pTi.*exp(-k./(pFreqs.^2+1e-9));	% inverse Gaussian kernel
                mTi=mTi.*exp(-k./(mFreqs.^2+1e-9));	% inverse Gaussian kernel
            end;
            ctfs(:,:,fileIndex)=pEffCTF.*pTi;  % overall effective ctf of particle
            ctf1s(:,:,fileIndex)=pdctfs(:,:,1); % first ctf
            pwfs(:,:,fileIndex)=pTi;  % pre-whitening filter that was applied

%             Read the images
            %       Scale the image by sqrt(doses(1)) to make it nominally unit variance.
            %       Also scale up by pixel size.
            normScale=sqrt(mi.doses(1))*pixA/ds^2;  % not sure where factor of ds^2 comes from.            
            %             Read a vesicle image *v.mrc or a subtracted image *mv.mrc
            vName=[dirVesicles mi.baseFilename 'v' inputModeSuffix '.mrc'];
            if upsampleSubtractedImage
                pa=[mi.basePath altBasePath];
            else
                pa=mi.basePath;
                vus=1;  % no vesicle upsampling
            end;
            mvName=[pa mi.procPath mi.baseFilename 'mv' inputModeSuffix '.mrc'];
            [mvName,mvImageOk]=CheckForImageOrZTiff(mvName);
            mName=[pa mi.procPath mi.baseFilename 'm' inputModeSuffix '.mrc'];
            [mName,mImageOk]=CheckForImageOrZTiff(mName);
            if readSubtractedImages && mvImageOk && mImageOk
                disp(mvName);
                mvMergeU1=ReadEMFile(mvName);
                mMergeU1=ReadEMFile(mName);
                if any(size(mvMergeU1)~=size(mMergeU1))
                    mvImageOk=0;
                else
                    vMergeU1=mMergeU1-mvMergeU1;
                    imags(vMergeU1);
                    drawnow;
                    vus=size(mMergeU,1)/size(mvMergeU1,1);
                    if vus>1
                        mvMergeU=mMergeU-Downsample(vMergeU1/vus^2,size(mMergeU));
                    else
                        mvMergeU=mvMergeU1;
                    end;
                end;
            elseif readVesicleModels && exist(vName,'file')
                disp(vName);
                vMergeU1=ReadMRC(vName);
                vus=size(mMergeU,1)/size(vMergeU1,1);
                vMergeU=Downsample(vMergeU1,size(mMergeU))/vus^2;
                mvMergeU=mMergeU-vMergeU;
                mvImageOk=1;
            end;
            if ~(readSubtractedImages || readVesicleModels) || ~mvImageOk
%%
                disp('Compute vesicle models...');
                tic;
                vesMi=mi;
                if useCircularVesicleModels  % truncate to the zeroth term in r and s
                    vesMi.vesicle.r=real(mi.vesicle.r(:,1));
                    vesMi.vesicle.s=real(mi.vesicle.s(:,1));
                end;
                if setOk4
                    vesMi.vesicle.ok(:,4)=true;  % Ignore the 4th column of this.
                end;
                doCTF=1;
                vMergeU=meMakeModelVesicles(vesMi,size(mMergeU)/vus,vindex,doCTF,0);
                %                 vsCorr=zeros(size(vMerge0),'single');
                mvMergeU=mMergeU-Downsample(vMergeU,size(mMergeU))/vus^2;  % unfiltered merged subtracted image
                toc;
                if writeSubtractedImages
                    [pa,nm,ex]=fileparts(mvName);
                    subOutName=[AddSlash(pa) nm 'z.tif'];  % compressed name
                    pars.snrRatio=200;
                    disp(['Writing: ' subOutName]);
                    WriteZTiff(mvMergeU,pixA,subOutName,pars);
                 end;                
            end;
            
%             We now have unfiltered mMergeU and mvMergeU.  Filter the
%             micrographs
            mMerge=real(ifftn(fftn(mMergeU).*ifftshift(mTi)))*normScale; % prewhitened
            if removeOutliers  % if we un-phase-flip, we get hot pixels
                mMerge=RemoveOutliers(mMerge);
            end;
            
            mvMerge=real(ifftn(fftn(mvMergeU).*ifftshift(mTi)))*normScale;
            if removeOutliers
                mvMerge=RemoveOutliers(mvMerge);
            end;
            imags(GaussFilt(mvMerge,.1));
            
            mImageOk=mImageOk & std(mvMerge(:))>minImageSD & std(mMerge(:))>minImageSD;
            if ~mImageOk
                disp('Blank image, skipping');
            end;

%             Prepare to do extraction
            if doExtractParticles
                nPicks=nPicks * (mImageOk);  %%%% don't pick anything if no image.
                imags(GaussFilt(mvMerge,.2));
                title(mi.baseFilename,'interpreter','none');
                drawnow;
                
                msk=~meGetMask(mi,n0);  % Get the image mask
                expandedMsk=msk;
                
                %
                nPickerEntries=nPicks
%                 if totalNParts==0  % the first time, allocate part of the total stack.
%                     totalStack=single(zeros(boxSize,boxSize,nPicks));
%                     totalStackU=single(zeros(boxSize,boxSize,nPicks));
%                 end;
                nv=numel(mi.vesicle.x);
                vCoords=[mi.vesicle.x(:) mi.vesicle.y(:)];
                vRadii=mi.vesicle.r(:,1);
                stackSub=single(zeros(boxSize,boxSize,nPicks));
                stackImg=single(zeros(boxSize,boxSize,nPicks));
                sumImg=zeros(boxSize,boxSize);
                sumSub=zeros(boxSize,boxSize);
                disp('Extracting');
                j=0;
%                 jPicks=0;
                nMasked=0;

%                 Particle extraction loop
                for i=1:nPicks  % scan the particle coordinates
                    type=mi.particle.picks(i,3);
                    vInd=mi.particle.picks(i,4);
                    
                    if (type>=types(1) && type<=types(2)) % valid particle flags
%                         jPicks=jPicks+1;  % counter of all picked particles in micrograph
                        pCoords=mi.particle.picks(i,1:2);
                        
                        j=j+1;  % counter of good particles
                        if vInd<1 && type<48  % no vesicle marked.  Find the nearest vesicle
                            dists=sqrt(sum((vCoords-repmat(pCoords,nv,1)).^2,2));
                            [minDist, vInd]=min(dists);
                            if minDist > vRadii(vInd) % outside of membrane, check distance from mbn.
                                distm=abs(dists-vRadii);
                                [minDist, vInd]=min(distm);
                            end;
                            mi.particle.picks(i,4)=vInd;  % insert our estimated vesicle index.
                            disp(['Inserted vesicle index for particle, vesicle ' num2str([i vInd])]);
                        end;
                        %   Up to this point, all coordinates are in original pixel size.
                        %   Make downsampled coordinates and do extraction
                        iCoords=round(pCoords/ds)+1;  % downsampled coordinates
                        %                 Store for box display
                        iCoordsList(j,:)=iCoords;  % store for box display
                        intCoords=round(iCoords);  % downsampled coordinates
                        fraCoords=iCoords-intCoords;
                        xm=ExtractImage(mMerge,intCoords,padSize);
                        xmv=ExtractImage(mvMerge,intCoords,padSize);
                        %    Pad and reverse the contrast.
                        ximg2=-xm.*padMask;
                        xsub2=-xmv.*padMask;
                        %                        Compute the angle relative to the y axis
                        %                           positive alpha means particle lies ccw from vertical
                        if vInd>0               % associated with a vesicle?
                            pVec=pCoords-vCoords(vInd,:);
                            alpha=atan2(pVec(2),pVec(1))-pi/2;
                        else
                            pVec=[0 0];
                            alpha=0;
                        end;
                        %               rotate them
                        if doAlphaRotation
                            pSub=Crop(grotate(xsub2,-alpha),boxSize);
                            pImg=Crop(grotate(ximg2,-alpha),boxSize);
                        else
                            pSub=Crop(xsub2,boxSize);
                            pImg=Crop(ximg2,boxSize);
                        end;
                        stackSub(:,:,j)=pSub;
                        sumSub=sumSub+pSub;
                        
                        stackImg(:,:,j)=pImg;
                        sumImg=sumImg+pImg;
                        
                        if showAllParticles || j==1
                            subplot(2,4,3);
                            imags(pSub);
                            title(mi.baseFilename,'interpreter','none');
                            %                         Show the particle image, and subtracted image
                            subplot(2,4,4);
                            imags(pImg);
                        end;
                        
                        if showAllParticles
                            %                         Show the sums fsrom this micrograph
                            subplot(2,4,7)
                            imags(sumSub);
                            title(j);
                            subplot(2,4,8);
                            imags(sumImg);
                            drawnow;
                        end;
                        
                        jt=j+totalNParts;  % pointer to overall stack index
                        si.miIndex(jt)=     fileIndex;
                        si.miParticle(jt)=  i;
                        si.alpha0(jt)=      alpha*180/pi;
                        si.yClick(jt)=      hypot(pVec(1),pVec(2))/ds;  % in units of si.pixA
                        if vInd>0
                            si.rVesicle(jt)=    mi.vesicle.r(vInd)/ds;
                            si.sVesicle(jt)=    mi.vesicle.s(vInd);
                        end;
                    end; % if type
                end; % for i
                nparts=j;
%                 npicks=jPicks;
                
                stackSub=stackSub(:,:,1:nparts);  % truncate the stack
                stackImg=stackImg(:,:,1:nparts);
                if fh==0 && nparts>0 % Set up to write out
                    fh=WriteMRCHeader(stackImg,pixA,tempStackName);  % file handles for stack output files
                    fhU=WriteMRCHeader(stackImg,pixA,tempUStackName);
                end;
%                 Write the stack data
                fwrite(fh,stackSub,'float32');
                fwrite(fhU,stackImg,'float32');
                
                sumTotalStack=sumTotalStack+sum(stackSub,3);
                sumTotalStackU=sumTotalStackU+sum(stackImg,3);
                
                totalNParts=totalNParts+nparts
%                 figure(1);
                subplot(2,4,7)
                imags(sumTotalStack);  % unrotated image
                title(totalNParts);
                subplot(2,4,8);
                imags(sumTotalStackU);
                drawnow;
                
                if ~restoreFromSiFile && updateMiFile
                    WriteMiFile(mi,[infoPath miFiles{fileIndex}]);
                    disp([infoPath miFiles{fileIndex} ' updated']);
                end;
                
                if writeIndividualStacks
                    outname=[mi.stackPath mi.baseFilename 'st.mrc'];
                    WriteMRC(stackSub,pixA,outname);
                    outname=[mi.stackPath mi.baseFilename 'stu.mrc'];
                    WriteMRC(stackImg,pixA,outname);
                end;
            end; % if doExtractParticles
        else
            disp(' -no particle picks found');
        end;  % if np
    end;  % if isa struct
    fileIndex=fileIndex+1;
end; % while fileIndex
%
if fh>0 % we wrote something, finalize the files.
    frewind(fh);
    WriteMRCHeader(pSub,pixA,tempStackName,[boxSize boxSize totalNParts],0,2,0,fh);
    fclose(fh);
    frewind(fhU);
    WriteMRCHeader(pImg,pixA,tempUStackName,[boxSize boxSize totalNParts],0,2,0,fhU);
    fclose(fhU);
end;


if totalNParts>0 || ~doExtractParticles
%     update the si structure
    si.pixA=pixA;
    si.fHighPass=fHP*pixA;
    mi1=si.mi{1};
    if isfield(mi1,'ppVars')
        si.mbnOffset=mi1.ppVars.membraneOffsetA/pixA;
    else
        si.mbnOffset=defaultMembraneOffsetA/pixA;
    end;
    si.weights=mi.weights;
    np=totalNParts;
    % truncate the si arrays.
    si.miIndex=     si.miIndex(1:np,1);
    si.miParticle=  si.miParticle(1:np,1);
    si.alpha0=      si.alpha0(1:np,1);
    si.yClick=      si.yClick(1:np,1);
    si.rVesicle=    si.rVesicle(1:np,1);
    si.sVesicle=    si.sVesicle(1:np,1);
    si.ctfs = ctfs;
    si.ctf1s=ctf1s;
    si.pwfs=pwfs;
    if restoreFromSiFile && exist('oldActiveFlags','var')
        si.activeFlags=oldActiveFlags;
        si.activeFlagLog=oldActiveFlagLog;
    else
        si.activeFlags=true(np,1);
        si.activeFlagLog={[date '  StackExtractor2']};
    end;
    si.mergeMode=mergeMode;
    %
    %%  Construct the stack file name
%     Basename is up to 2nd underscore
    p=strfind(mi.baseFilename,'_');
    if numel(p)>1
        baseName=mi.baseFilename(1:p(2)-1);
    else
        baseName=mi.baseFilename;
    end;

    if usePWFilter
        pwString='f';
    else
        pwString='';
    end;
    
    corrString='';
    if ~doExtractParticles
        corrString='noParticles'
    end;
    
    sizeString=sprintf('p%d',boxSize);
    modeSuffix='';
    if mergeMode>1
        modeSuffix=['m' num2str(mergeMode)];
    end;
    
    outname=[mi.stackPath baseName weightString pwString sizeString corrString modeSuffix];
    disp(['Base output name: ' outname]);
    siName=[outname 'tsi.mat'];
    if exist(siName,'file')
        ch=MyInput(['Overwrite the file ' siName],'n');
        if ch~='y'
            outname=MyInput('New base name',[outname 'z']);
            siName=[outname 'tsi.mat']
        end;
    end;
    
    % save the stackInfo structure
    save([outname 'tsi.mat'],'si','-v7.3');
    disp(['Wrote the total stack info ' outname '.tsi.mat']);
    
    if totalNParts>0 % Actually particles to store
        stackName=[outname stackSuffix];
        [status,result]=system(['mv ' tempStackName ' ' stackName]);
        disp(result);
        disp(['Wrote the stack ' outname stackSuffix]);
        
        ustackName=[outname ustackSuffix];
        [status,result]=system(['mv ' tempUStackName ' ' ustackName]);
        disp(result);
            disp(['Wrote the stack ' outname ustackSuffix]);
    else
        disp('No particle stacks written');
    end;
else
    disp('--nothing written.');
    disp(' ');
end;
