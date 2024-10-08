% rsMakeMvsFiles.m
% What to do if we forgot to have rsRefineVesicleFits to write the .mvs files.
ds=4; % we assume this is the same as the *.ms files.
infoDir='Info_xchg/';
jpegDir='Jpeg_xchg/';


miNames=f2FindInfoFiles(infoDir);
nim=numel(miNames);
overwrite=0;

for i=1:nim
    mi=ReadMiFile(miNames{i});
    outputName=[mi.procPath_sm mi.baseFilename 'mvs.mrc'];
    outOk= ~exist(outputName,'file') || overwrite;  % Check for file already present
    if ~outOk
        disp([num2str(i) '  ' outputName ' skipped.']);
        continue;
    end;
    [m,Mx,inOk]=meLoadNormalizedImage(mi,mi.padImageSize/ds,'mv');
    if inOk
        WriteMRC(m,mi.pixA*ds,outputName);
        disp([num2str(i) '  ' outputName]);
        outputJpeg=[jpegDir mi.baseFilename 'mvs.jpg'];
        WriteJpeg(m,outputJpeg);
    else
        disp([num2str(i) '  ' mi.baseFilename ': no input image found.']);
    end;
end;

