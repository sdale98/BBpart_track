%% Video Import
[vfile,vpath] = uigetfile('*.*', 'Select video file', 'C:\Users');
if isequal(vfile,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(vpath,vfile)]);
end
cd(vpath)
v = VideoReader(vfile); %the video to read
get(v) %show image data
prompt = {'Enter dataset name', 'Enter start time (s)','Enter end time (s)'};
dlgtitle = 'Input Data';
inputdat = inputdlg(prompt,dlgtitle,[1 40]);
experimentname = inputdat{1}; stend = inputdat(2:3); %pull out name, start end data
stend=str2double(stend); %convert to double
timestart = stend(1); %choose time to start data analysis
timeend = stend(2); %choose time to end data analysis (select before video ends)
df=1; %choose the gap between frames (the smaller the longer it will take to run)
framerate=round(v.FrameRate);

v.CurrentTime = timestart; %% select start time
frame = rgb2gray(readFrame(v));

%% Draw line ROIs for dimensioning
thr =1;
%Horizontal
while thr == 1
dimfigx = figure('Name','Select Horizontal 5cm Line Along Surface','NumberTitle','off');
xdimcheck = imshow(mat2gray(frame));
xdiml = drawline;
xchoice = questdlg('Use this selection?','x Line Setting',...
                  'Yes','No','Yes');
              switch xchoice
              case 'No'
                      thr = 1;
                      close(dimfigx);
               case 'Yes'
                   thr = 0;
                   close(dimfigx);
             end
end
thr = 1;
%Vertical:
while thr == 1
dimfigy = figure('Name','Select Vertical 5cm Line','NumberTitle','off');
ydimcheck = imshow(mat2gray(frame));
ydiml = drawline;
ychoice = questdlg('Use this selection?','x Line Setting',...
                  'Yes','No','Yes');
              switch ychoice
              case 'No'
                      thr = 1;
                      close(dimfigy);
               case 'Yes'
                   thr = 0;
                   close(dimfigy);
             end
end

%So xpos, ypos allow dimensioning of coord system + finding centre
toploc = mean2(xpos(1, :)); centreloc = mean2(ypos(2, :));

%% Select Crop Area

fi = figure('Name','Crop Selection','NumberTitle','off');
              hold on
 imcheck1 = imshow(mat2gray(frame));
  [~, crop] = imcrop(imcheck1);
                      crop = round(crop);
                      
%find co-ords of all four corner points
topleft = [crop(1), crop(2)];
topright = [crop(1) + crop(3), crop(2)];
bottomleft = [crop(1), crop(2) + crop(4)];
bottomright = [crop(1) + crop(3), crop(2) + crop(4)];

%draw the rectangle
line([topleft(1) topright(1)],[topleft(2) topright(2)],'Color','red','LineWidth',2);
line([topleft(1) bottomleft(1)],[topleft(2) bottomleft(2)],'Color','red','LineWidth',2);
line([topright(1) bottomright(1)],[topright(2) bottomright(2)],'Color','red','LineWidth',2);
line([bottomleft(1) bottomright(1)],[bottomleft(2) bottomright(2)],'Color','red','LineWidth',2);

% Draw ROI(s)

%% Glare ROI
roiselim = imcrop(frame, crop);
sz = size(roiselim); thr = 1;
while thr == 1
roiselglare =  figure('Name','Glare ROI Selection','NumberTitle','off');
hold on
imshow(roiselim);
roi1 = drawpolygon; %draw polygon region
threshchoice = questdlg('Use this region?','Glare ROI setting',...
                  'Yes','No','Yes');
              switch threshchoice
              case 'No'
                  close(roiselglare);
               case 'Yes'
                   bwglare = poly2mask(roi1.Position(:,1), roi1.Position(:, 2), sz(1), sz(2));
                   close(roiselglare);
                   thr = 0;
             end
end
%convert polygon region to binary mask
bwglareinv = imcomplement(bwglare); %invert sel
%used to create separate threshold for glare region

%% Impeller ROI selection
thr = 1;
while thr == 1
roiselimp =  figure('Name','Impeller ROI Selection','NumberTitle','off');
img = imshow(roiselim);
roi2 = drawassisted(img,'Color','r'); %draw ROI for impeller
threshchoice = questdlg('Use this region?','Impeller ROI setting',...
                  'Yes','No','Yes');
              switch threshchoice
              case 'No'
                  close(roiselimp);
               case 'Yes'
                  bwimp = createMask(roi2); 
                   close(roiselimp);
                   thr = 0;
             end
end

%% Show ROI selections

%0 is black, 255 is white
bwimpm = 255*double(bwimp); %grayscale impeller mask
bwglarem = 255*double(bwglare); %grayscale non glare mask
bwglareinvm = 255*double(bwglareinv); %grayscale glare mask
impmasked = double(roiselim)+bwimpm+bwglarem;
impmasked(impmasked>255)=255;
glaremasked = double(roiselim)+bwimpm+bwglareinvm;
glaremasked(glaremasked>255)=255;
impmasked = uint8(impmasked);
glaremasked = uint8(glaremasked);
roishow = figure('Name','ROIs selected','NumberTitle','off');
imshowpair(impmasked, glaremasked, 'montage');

%% Glare Region Threshold Selection

thr = 1;
glaretest = glaremasked;
threshsel = figure('Name','Glare Region Thresholding','NumberTitle','off');
title('Glare Region Thresholding')
imshow(glaretest)
while thr == 1
    glareout = glaretest;
prompt = {'Threshold Value (0-255)'};
dlgtitle = 'Threshold Selection';
glarethreshold = inputdlg(prompt,dlgtitle,[1 40]);
glarethreshold = str2double(glarethreshold);
glareout(glareout<glarethreshold) = 0;
glareout(~(glareout<glarethreshold)) = 255;
imshowpair(glaretest, glareout, 'montage')
threshchoice = questdlg('Use this value?','Threshold setting',...
                  'Yes','No','No');
              switch threshchoice
              case 'No'
                      thr = 1;
               case 'Yes'
                   thr = 0;
             end
end


%% General Threshold Selection
thr = 1;
threshtest = impmasked;
threshsel = figure('Name','General Thresholding','NumberTitle','off');
title('General Region Thresholding')
imshow(threshtest);
while thr == 1
    genout = threshtest;
prompt = {'Threshold Value (0-255)'};
dlgtitle = 'Threshold Selection';
genthreshold = inputdlg(prompt,dlgtitle,[1 40]);
genthreshold = str2double(genthreshold);
genout(genout<genthreshold) = 0;
genout(~(genout<genthreshold)) = 255;
imshowpair(threshtest, genout, 'montage');
threshchoice = questdlg('Use this value?','Threshold setting',...
                  'Yes','No','No');
              switch threshchoice
              case 'No'
                      thr = 1;
               case 'Yes'
                   thr = 0;
             end
end

%% Function test

[binframe, impframe, glareframe, impbin, glarebin] = sd_frame2bin(v, crop, bwglare, bwimp,...
  glarethreshold, genthreshold);

compfig = figure('Name','Thresholded Composite Image','NumberTitle','off');
imshow(binframe);
