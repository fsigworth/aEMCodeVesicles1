function SetGrayBunt()
% function SetGrayBunt();
% Set a grayscale colormap for indices 1..256.  Values above 256 give colors:
% 257: blue
% 258: green
% 259: yellow
% 260: orange
% 261: red

r = [0:1/255:1]';
map=[r r r; 0.2 0.2 1; 0.1 0.8 0.1; 0.9 0.9 0; 1 0.5 0.1; 1 0.1 0.1];
h=gcf;
figure(h);
colormap(map);
