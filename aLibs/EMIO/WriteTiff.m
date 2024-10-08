function WriteTiff(m,filename,clipThreshold,compressed)
% function WriteTiff(m,filename,clipThreshold)
% Autoscale the image m and write it out as an 8-bit tiff image.  If filename has
% no extension add '.tif' to it.  clipThreshold is the fraction of gray
% values that are clipped at black and white ends of the range; default is
% 1e-3.
if nargin<3
    clipThreshold=1e-3;
end;
if nargin<4
    compressed=1;
end;
% If there's not extension, add one.
if numel(regexp(filename,'.+\.tif'))+numel(regexp(filename,'.+\.tiff'))==0
    filename=[filename '.tif'];
end;
if compressed
    imwrite(uint8(imscale(rot90(m),256,clipThreshold)),filename,'compression','lzw');
else
    imwrite(uint8(imscale(rot90(m),256,clipThreshold)),filename);
end;
