% TifToSpider( Infile, Outfile );
% Converts the tiff file to a spider file.
im=imread( Infile, 'tif' );
m=double(im)/256;
[nr nc]=size(m);

setgrayscale;
image(m * 256);

headrec=ceil(256/nc);
h=zeros(211,1);	   % All the numeric part of the header
h(1)=1; % number of slices
h(2)=nr;
h(3)=nr+headrec; % Number of records
h(5)=1; % Data type = 2d image
h(6)=1; % Normalization data present
h(7)=max(max(m));
h(8)=min(min(m));
h(9)=sum(sum(m))/(nr*nc);
h(10)=-1;  			% no s.d.
h(12)=nc;
h(13)=headrec;
h(21)=1;   			% Scale factor
h(22)=headrec*nc*4; % Bytes in header
h(23)=nc*4;			% Bytes in record

f=fopen( Outfile, 'w' );
n=fwrite(f,h,'float');

% Write the date, time and name fields.
% ok=fseek( Outfile, 844, 'bof'); % Seek to date field
dtxt=date; dtxt(8:9)=dtxt(10:11); % Y2k problem!
dtxt(10)=char(0); dtxt(11)=char(0); dtxt(12)=char(0);
n=fwrite(f,dtxt,'char'); % Write 12 characters

ttxt=datestr(now,13);
n=fwrite(f,ttxt,'char'); % Write 8 characters

[q len]=size(Outfile);
filename = char(zeros(1,160));
filename(1:len)=Outfile;
n=fwrite(f,filename,'char'); % Write 160 characters.


n=fwrite(f,m,'float');
ok=fclose(f);

