function [m, pixA, hdr] = ReadSpider( name )
% function [m pixA] = ReadSpider( name )
% Read a SPIDER 2d image file and deposit the data into matrix m.
%
f=fopen( name,'r' );
hdr=fread(f,211,'*single');  % Read the header
nrow=hdr(2);
nsam=hdr(12); % Number of samples in a row
headrec=hdr(13); % Number of records (same size as a row) in header
pixA=hdr(38);
% disp('date: '); disp(char(fread(f,12)'));
% disp('time: '); disp(char(fread(f,8)'));
% disp('name: '); disp(char(fread(f,160)'));
ok=fseek(f,4*nsam*headrec,'bof');
m=fread(f,[nrow nsam],'*single');
x=fclose(f);
