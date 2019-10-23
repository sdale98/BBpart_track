function [frameCrop,frameBin, centers, radii, centroids] = bbtrack(v, mask, crop)
%Crop frame, convert to binary image, detect bbs with two different
%methods
frameCrop = imcrop(readFrame(v), crop); %loaded frame
bw = imbinarize(rgb2gray(frameCrop), 'adaptive', 'ForegroundPolarity', 'dark',...
    'Sensitivity', 0.1); %adaptively binarize
bw = imcomplement(bw); %invert (BBs are black, need white for filling)
bwnr = imfill(bw, 'holes'); %fill holes
bwnr = bwareaopen(bwnr,200); %remove small white regions
bwnr = imcomplement(bwnr); %invert
bwnr = bwareaopen(bwnr,200); %remove small black regions
frameBin = bwnr | mask;
frameBin = imcomplement(frameBin); %output binary image!!
[centers,radii] = imfindcircles(frameBin,[30 50],'ObjectPolarity','bright',...
    'Sensitivity',0.96);
s = regionprops(frameBin,'centroid');
centroids = cat(1,s.Centroid);
end

