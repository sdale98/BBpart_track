function [binframe, impframe, glareframe, impbin, glarebin] = sd_frame2bin(v, crop, bw1, bw2,...
   threshold1, threshold2)
%Function to convert RGB video frame to masked/thresholded image. v is
%videoreader for video, crop specifies crop, bw1 and bw2 are binary region
%masks, bw1sw and bw2sw are logical switch operators to specify whether
%mask inverted, threshold1 is threshold for region selected by bw1 (glare) (or
%inversion), threshold2 " (impeller) for bw2. Output binframe is masked and
%thresholded binary image for input frame (note - controlled by timestamp
%using v.CurrentTime, not frame no.)
frame = rgb2gray(readFrame(v)); %read in frame
frame = imcrop(frame, crop); %crop frame
sz = size(frame); %Measure frame size: don't use crop dims as these can be
%inconsistent

bw1n = imcomplement(bw1); %Region outside of glare 

%Normalise threshold values to 1 for imbinarize command:
%threshold1bin = threshold1/255; threshold2bin = threshold2/255;

bw1m = 255*double(bw1); %To add to image to make inside of glare area white
bw1nm = 255*double(bw1n); %To add to image to make outside of glare area white
bw2m = 255*double(bw2); %To add to image to make inside of impeller area white

%Make white + threshold: impeller, glare outside regions
impframe = double(frame)+bw1m + bw2m;%make sel pixels outside of range
impframe(impframe>255)=255; %convert all pixels above range to white
impbin = impframe;
impbin(impframe<threshold2) = 0;
impbin(~(impframe<threshold2)) = 255;
impbin = imbinarize(impbin, 0.5); %threshold + binarize impframe 
impframe = uint8(impframe); %convert back to unit8 for display

%Make white + threshold: impeller, glare inside regions
glareframe =  double(frame)+bw1nm + bw2m;%make sel pixels outside of range
glareframe(glareframe>255)=255; %convert all pixels above range to white
glarebin = glareframe;
glarebin(glareframe<threshold1) = 0;
glarebin(~(glareframe<threshold1)) = 255;
glarebin = imbinarize(glarebin, 0.5); %threshold + binarize impframe
glareframe = uint8(glareframe); % convert back for display

%Produce composite image out
binframe = imcomplement(glarebin) | imcomplement(impbin);
end

