function SetGrayRed();
r = [0:1/255:1]';
r1=r;
r1(256)=0;
h=gcf;
figure(h);
set(h,'color', [1 1 1] );
colormap( [r r1 r1] );
