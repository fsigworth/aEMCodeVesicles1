% CopyMiVesiclesAndParticles.m
monthStr='Jan';


        % Select info files from the file selector

        [fname, pathName]=uigetfile('*mi.mat','Select new info files','multiselect','on');
        if isnumeric(pathName) % File selection was cancelled
            return
        end;
        if ~iscell(fname)
            fname={fname};
        end;
        [rootPath, dirInfo]=ParsePath(pathName);
        cd(pathName);  % Point to the mi file directory
                

        [fnameOld, pathOld]=uigetfile('*mi.mat','Select old info files','multiselect','on');
        if isnumeric(pathOld) % File selection was cancelled
            return
        end;
        if ~iscell(fnameOld)
            fname={fnameOld};
        end;
% Get all the old file dates
nOld=numel(fnameOld);
datesOld=cell(nOld,1);
for ind=1:nOld
    name=fnameOld{ind};
    p=strfind(name,monthStr);
    datesOld{ind}=name(p:p+13);
end;

%%

nNew=numel(fname);
for ind=1:nNew
    name=fname{ind};
    p=strfind(name,monthStr);
    dateStr=name(p:p+13);
    pAll=strfind(datesOld,dateStr);
    p=0;
    for j=1:nOld
        if numel(pAll{j})>0
            p=j;
            break
        end;
    end;
    if p>0
        miNew=load(name);
        mi=miNew.mi;
        miOld=load([AddSlash(pathOld) fnameOld{p}]);
        miOld=miOld.mi;
        disp([name ' <--  ' fnameOld{p}]);
        if numel(miOld.vesicle.x)>0
            mi.mask=miOld.mask;
            mi.vesicleModel=miOld.vesicleModel;
            mi.vesicle=miOld.vesicle;
            mi.boxSize=miOld.boxSize;
            mi.particle=miOld.particle;
            save(name,'mi');
            return
        end;
    end;
end;
    
    
%%%
