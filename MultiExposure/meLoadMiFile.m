function mi=meLoadMiFile(name)
% Attempt to load the mi structure from an mi text file *mi.mtx
%  if unsuccessful, load the file *mi.mat
[pa,nm,ex]=fileparts(name);
baseName=[AddSlash(pa) nm];
mi=struct;
if exist([baseName '.txt'],'file')
    mi=ReadMiText([baseName '.txt']);
elseif exist([baseName '.mat'],'file')
    s=load([baseName '.mat']);
    mi=s.mi;
else
    error(['mi file could not be found: ' baseName '.txt']);
end;
