% MiLoadAll.m
% Use the file selector to choose a set of mi files, or look in the
% current directory.  Load all of them into
% a single cell array, stored in the Info directory. Store the names too.
% allMis.mat, allNames.mat

% Or in batch mode, load everything in the infoPath directory.
% Use the later sections of code to find defocus values, and sort micrographs
% according to the defocus values.

getNamesOnly=0;
batchMode=1;  % Simply load everything we find in the InfoPath directory, and write out
%               to the outPath.
maxNames=inf;

if batchMode
    infoPath='Info2/';
    outPath=infoPath;
    names=f2FindInfoFiles(infoPath);
    CheckAndMakeDir(outPath,1);
else
    [names, pathName]=uigetfile({'*mi.txt';'*mi.mat'},'Select mi files','multiselect','on');
    if isnumeric(pathName) % File selection was cancelled
        return
    end;
    if ~iscell(names)
        names={names};
    end;
    [rootPath, theInfoPath]=ParsePath(pathName);
    for i=1:numel(names)
        names{i}=[theInfoPath names{i}];
    end;
    cd(rootPath);
    outPath='';
end;
%%

nNames=min(maxNames, numel(names));
allMis=cell(nNames,1);
disp([num2str(nNames) ' mi files.']);
allNames=cell(nNames,1);
step=1;
for i=1:nNames
    if step<1000 && i>=step*10
        step=step*10;
    end;
    if mod(i,step)==0
        disp([num2str(i) '  ' names{i}]);
    end;
    allNames{i}=[ names{i}];
    if ~getNamesOnly
        allMis{i,1}=ReadMiFile(allNames{i});
    end;
end;
% % save([outPath 'allNames.mat'],'allNames');
% % disp([outPath 'allNames.mat saved.']);
if ~getNamesOnly
    save([outPath 'allMis.mat'],'allMis','allNames');
    disp([outPath 'allMis.mat saved.']);
end;
disp('done.');

return





%% Find the files with defocus closest to the target value. Put the micrographs into
%% an array of images, or else copy the mrc files from a remote place.
defTarget=2.26;
% defTarget=2.26*EWavelength(200)/EWavelength(300); % Fix for 20201201
% dataset
% Sort theimages according to defsocus
[sDeltas,sInds]=sort(abs(defTarget-defs));
foundMis=allMis(sInds);
foundDefs=defs(sInds);
foundNames=allNames(sInds);

plot(foundDefs);

%%
numToLoad=20;
jpegDir='jpeg/';
fc=.2;
nsds=4;
doWrite=1;
% CheckAndMakeDir(jpegDir,1);

copyRemoteMrcs=0;
copyRemoteMicrographs=1;
processMsFiles=0;
selected=[1 7 9 11 18];

copyJpegs=0;
if copyJpegs
    selected=1:numToLoad;
end;

if copyRemoteMrcs
    %     remotePath='/Volumes/Drobo4/200922/Merged/';
    %     % localPath='/Volumes/D257/Hideki/200922/Merged/';
    %     remotePath='/Volumes/Drobo4/Yangyu/20201203/Merged/';
    %     remotePath=[remoteBasePath 'MotionCorr/job009/Movies/'];
    
    
    localPath='Merged/';
    CheckAndMakeDir(localPath,1);
    
    h=fopen('CopyScript.sh','w');
end

if copyRemoteMicrographs
    % remoteBasePath='/Volumes/Drobo4/201228/025036_1_1/';
    remoteBasePath='/Volumes/Drobo4/201228/025035_1_1/';
    %     remoteBasePath='/Volumes/Drobo4/Yangyu/20201203/';
    h=fopen('CopyMics.sh','w');
end;
if copyJpegs
    jpegOutDir='Jpeg_sel/';
    CheckAndMakeDir(jpegOutDir,1);
end;

suffix={'s' 'vs'};
suffixFull={'m' 'mv'};

ms=[];

for i=selected
    mi=foundMis{i};
    for j=1:1
        if copyRemoteMrcs
            
            fileName=[mi.baseFilename suffixFull{j} '.mrc'];
            %             disp(['get ' fileName]);
            %             disp(' ');
            
            
            str=['cp ' remotePath fileName ' ' localPath fileName];
            disp(str);
            fprintf(h,'%s\n',str);
            %
        elseif copyRemoteMicrographs
            
            fileName=[mi.imagePath mi.imageFilenames{1}];
            CheckAndMakeDir(mi.imagePath);
            str=['cp ' remoteBasePath fileName ' ' fileName];
            disp(str);
            fprintf(h,'%s\n',str);
            
            
            
            
        elseif processMsFiles  % read the 'ms' files locally, create the ms image array
            %             and make jpegs
            [m, mergeFullName,ok]=meReadMergedImage(mi,0,suffix{j});
            disp(mergeFullName);
            if ~ok
                return
            end;
            if i==1 && j==1
                ms=zeros([size(m) numToLoad 2],'single');
            end;
            ms(:,:,i,j)=m;
            mscl=uint8(imscale(GaussFilt(m,fc),256,nsds));
            imaga(mscl);
            jName=[jpegDir num2str(i) '_' mi.baseFilename 'm' suffix{j} '.jpg'];
            title([num2str(mi.ctf(1).defocus,3) '  ' jName], 'interpreter', 'none');
            drawnow;
            if doWrite
                imwrite(mscl,jName);
            end;
        elseif copyJpegs && j==1
            jName=[mi.baseFilename 'ms.jpg'];
            str=['cp Jpeg/' jName ' ' jpegOutDir sprintf('%02dd',i) jName];
            if doWrite
                system(str);;
            end;
            disp(str);
        end;
    end;
end

if copyRemoteMrcs || copyRemoteMicrographs
    fclose(h);
end;
%%
if copyRemoteMicrographs && doWrite
    !chmod a+x CopyMics.sh
    system('./CopyMics.sh');
    
end;
save DefSorted.mat foundDefs foundMis foundNames ms
return


%%  Write out micrographs in order.
doWrite=1;
% for i=[3 4 6 8]
for i=1:numToLoad
    mi=foundMis{i};
    mName=[mi.procPath mi.baseFilename 'm.mrc'];
    str=['cp ' mName ' ' sprintf('%02dd',i) mName];
    if doWrite
        system(str);
    end;
    disp(str);
end;


%%
% Look at picker amplitudes

nmi=numel(allMis);
amps=zeros(nmi,1);
for i=1:nmi
    mi=allMis{i};
    if numel(mi.particle.autopickPars)>0
        amps(i)=mi.particle.autopickPars(1);
    end;
end;


