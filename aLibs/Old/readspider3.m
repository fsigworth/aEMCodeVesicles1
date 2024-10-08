function [vol,angle,offset,scalefactor]=readspider3(filename)
%readspider: input the files in spider format. If the infile is a 2D image, the returned
% image will be a 2-D matrix of float points. If the infile is a 3D slices, the
% returned vol will be 3D matrix. angle returns the Eulerian angles possibly 
% assigned to the slice (only when there is one or two slices). The first three angles are
% for slice one. The next six angles are phi1,theta1,psi1,phi2,theta2,and psi2. 
% Offset records the x-, y- and z-shift of the image. The scalefactor is the scaling of 
% the image. 

fid=fopen(filename,'r','ieee-le');  % the byte order of the image in em2em was set to IBM PC by default for its output spider format.
if fid < 1
	error('ReadSpider: file could not be opened.');
end;
[h1 count] =fread(fid,256,'float32');
count

angle=zeros(9,1);

if h1(14)
   angle(1)=h1(15);
   angle(2)=h1(16);
   angle(3)=h1(17);
end
if h1(30)
   angle(4)=h1(31);
   angle(5)=h1(32);
   angle(6)=h1(33);
   angle(7)=h1(34);
   angle(8)=h1(35);
   angle(9)=h1(36);
end
offset=[h1(18),h1(19),h1(20)];
scalefactor=h1(21);

nslice=floor(h1(1));

nrow=floor(h1(2));

n2d3d=h1(5);
ncolum=floor(h1(12));

headbyte=h1(22);
vol=zeros(nrow,ncolum,nslice);
stforward=fseek(fid,headbyte-1024,0);  % forward to the start of the first slice
if stforward
   display('Forward seeking failed!');
   fclose(fid);
   exit(1);
end

for i=1:nslice
   for j=1:nrow
      vol(j,1:ncolum,i)=fread(fid,ncolum,'float');
   end
end
fclose(fid);
