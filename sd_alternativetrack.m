%Alternative approach to particle tracking

%23/10/19: need to fix definition of length scales esp in x direction to
%prevent distortion
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
frame = (readFrame(v));

%% Measure Length Scale + Position Indicators
thr =1;
%Horizontal
while thr == 1
dimfigx = figure('Name','Select Horizontal 5cm Line Along Surface','NumberTitle','off');
xdimcheck = imshow(frame);
xdiml = drawline;
xpos = xdiml.Position;
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
dimfigy = figure('Name','Select centreline','NumberTitle','off');
ydimcheck = imshow(frame);
ydiml = drawline;
ypos = ydiml.Position;
ychoice = questdlg('Use this selection?',' Centreline Setting',...
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


%So xpos allows dimensioning of coord system + finding surface
%Location of top by averaging y positions of ends of xline
toploc = mean2(xpos(:, 2)); 
centerloc = mean2(ypos(:, 1));
%Finding number of pixels relating to 5cm from xline, yline
fivel = pdist2(xpos(1, :), xpos(2, :),'euclidean');
%fively = pdist2(ypos(1, :), ypos(2, :),'euclidean');

%% Select Crop Area + Define Dimensioned Coordinates

fi = figure('Name','Crop Selection','NumberTitle','off');
              hold on
              

 imcheck1 = imshow(frame);
  [~, crop] = imcrop(imcheck1);
                      crop = round(crop);
                      
%find co-ords of all four corner points
topleft = [crop(1), crop(2)];
topright = [crop(1) + crop(3), crop(2)];
bottomleft = [crop(1), crop(2) + crop(4)];
bottomright = [crop(1) + crop(3), crop(2) + crop(4)];

%Distance between surface and top of crop box (used for dimensioning later)

ltop =abs(5*( (toploc - crop(1))/fivel));

%Distance between left of crop box and centerline

lcenterL = abs(5*( (centerloc - crop(2))/fivel));

%Distance between right of crop box and centerline;

lcenterR = abs(5*( (centerloc - (crop(1)+crop(3)))/fivel));

%Setting of dimensioned coordinate system

xWorldLimits = [(-lcenterL), lcenterR];

 yWorldLimits  = [ ltop,( ltop+ (5*(cropsz(1)/fivel)))];

dimcoords = imref2d(size(frameCrop), xWorldLimits, yWorldLimits);

%Surface line
surfaceline1 = [0, toploc]; surfaceline2 = [v.Width, toploc];
line([surfaceline1(1), surfaceline2(1)], [surfaceline1(2), surfaceline2(2)],...
    'Color','red','LineWidth',2);

%Centerline

centerline1 = [centerloc, 0]; centerline2 = [centerloc, v.Height];
line([centerline1(1), centerline2(1)], [centerline1(2), centerline2(2)],...
    'Color','red','LineWidth',2);

%draw the rectangle
line([topleft(1) topright(1)],[topleft(2) topright(2)],'Color','red','LineWidth',2);
line([topleft(1) bottomleft(1)],[topleft(2) bottomleft(2)],'Color','red','LineWidth',2);
line([topright(1) bottomright(1)],[topright(2) bottomright(2)],'Color','red','LineWidth',2);
line([bottomleft(1) bottomright(1)],[bottomleft(2) bottomright(2)],'Color','red','LineWidth',2);

%% Cropping example image

startCrop = imcrop(readFrame(v), crop);
cropsz = size(startCrop); %measure crop

%% Select impeller ROI
thr = 1;
while thr == 1
roiselimp =  figure('Name','Impeller ROI Selection','NumberTitle','off');
img = imshow(startCrop);
roiimp = drawpolygon; %draw polygon region; %draw ROI for impeller
impchoice = questdlg('Use this region?','Impeller ROI setting',...
                  'Yes','No','Yes');
              switch impchoice
              case 'No'
                  close(roiselimp);
               case 'Yes'
                  maskimp = poly2mask(roiimp.Position(:,1), roiimp.Position(:, 2), cropsz(1), cropsz(2)); 
                   close(roiselimp);
                   thr = 0;
             end
end



%%  Object tracking and heatmap population
v.CurrentTime = timestart;
videoPlayer = vision.VideoPlayer('Name', 'Region Detections', 'Position',...
    [0 0 cropsz(1) cropsz(2)]);
numframes = (timeend-timestart)*framerate;
framestart = framerate*timestart;
frameend = framerate*timeend;
particles = cell(numframes, 3); %output cell array for particle tracking data
counter = 1; %counter for filling cell array
heatmap = zeros(cropsz(1), cropsz(2));
prog = waitbar(0, 'Processing...', 'Name', 'Progress');
for frameno = framestart:frameend
       [frameCrop,frameBin, centroids, area, bounding] = bbtrackfr(v, frameno, ...
        maskimp, crop, 600);
    heatmap = heatmap+double(frameBin); %builds heatmap by adding binary frames
    RGB = insertShape(frameCrop,'Rectangle',bounding);
    videoFrame = RGB;
  videoPlayer(videoFrame);
  particles{counter, 1} = centroids;
  particles{counter, 2} = area;
  particles{counter, 3} = bounding;
  v.CurrentTime = v.CurrentTime + (frameno/framerate);
  waitbar(counter/numframes);
  counter = counter+1;
end
release(videoPlayer);
close(prog)

%%  Production of heatmap and display with dimensioning
heatmax = max(heatmap(:));
heatmap = uint8((heatmap./heatmax)*255); %converts heatmap to grayscale image
htfig = figure('Name', 'Heatmap', 'NumberTitle', 'off');
htimg = imshow(heatmap, dimcoords);
truesize;
colormap(jet(256));
cl = colorbar;
cl.Label.String = 'Particle Density (as greyscale intensity)';
cl.Label.Interpreter = 'Latex';
cl.Label.FontSize = 14;
cl.TickLabelInterpreter = 'Latex';
axis on, grid on
tit = title('\textbf{Heatmap}', 'interpret', 'latex');
xlabel('$$\mbox{Distance from Centre, }cm$$', 'interpreter', 'latex')
ylabel('$$\mbox{Distance from Surface, }cm$$', 'interpreter', 'latex')
set(gca,'fontsize',14, 'linewidth',3, 'TickLabelInterpreter','latex', 'YColor','k')







