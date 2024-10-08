function [coords, rots1, type]=ReadPDB(name, debug)
% function [coords, rots1, type]=ReadPDB(name, debug)
% Read a pdb file.  Put the coordinates
% of each non-H atom into the 3xn array coords.  The set of rotation
% matrices rots1 (3 x 4 x nrot in size) give the rotations and shifts for
% each copy in the subunit in the biological oligomer.  The type array
% (characters, 1xn in size) give the one-char element name of each atom
% corresponding to the columns of coords.

% examples of the lines that are read:
%REMARK 350   BIOMT1   1  1.000000  0.000000  0.000000        0.00000      
%ATOM      1  N   LYS A 331     -66.884  50.336  53.891  1.00195.42           N  

if nargin<2
    debug=0;
end;

printout=debug;

fin = fopen(name);
if fin == -1   % couldn't be opened....
	error('ReadPDB: file not found.');
end

rots=[];
coords=zeros(3,1);
n=0; m=0;
nm=0;  % number of matrix rows
s=fgetl(fin);
while (~isempty(s))
	if s(1) == -1
		break
	end;
	m = m+1;
% 	if mod(m,100) == 0
% 		n
% 		s
%     end
    s0=s;
	[t,s]=strtok(s);

    if (strcmp(t,'ATOM')||strcmp(t,'HETATM'))
		[t,s]=strtok(s);	% skip the atom no.
		[t,s]=strtok(s);	% get the atom type
		if t(1) ~= 'H'		% We use only non-hydrogens
			n = n+1;			%Found something.
			type(n)=t(1);		% Record the atom type.
			[t,s]=strtok(s);	% skip the residue type
            s=s(3:numel(s));     % skip the chain
%             [t,s]=strtok(s);	% skip the chain
			[t,s]=strtok(s);	% skip the residue no.
			[t,s]=strtok(s);	% pick up x
			coords(1,n)=eval(t);
			[t,s]=strtok(s);	% pick up y.
			coords(2,n)=eval(t);
			[t]=strtok(s);	% pick up z.
			coords(3,n)=eval(t);
if printout
    disp(coords(:,n)')
end;
        end
    elseif strncmp(s0,'REMARK 350   BIOMT',18)
        s=s0(24:numel(s0));
        nm=nm+1;
        rots(nm,:)=sscanf(s,'%f')';
if printout
        rot=rots(nm,:)
end;
    end
	s=fgetl(fin);
end
fclose(fin);
%%
nrots=size(rots,1)/3;
rots1=zeros(3,4,nrots);
for i=1:nrots
    sh=(i-1)*3;
    rots1(:,:,i)=rots(1+sh:3+sh,:);
end;

