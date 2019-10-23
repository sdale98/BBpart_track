function [frameCrop,frameBin, centroids, area, bounding] = bbtrackfr(v, frameno, mask, crop, minsize)
%Crop frame, convert to binary image, detect bbs with two different
%methods
frameCrop = imcrop(read(v, frameno), crop); %loaded frame
bw = imbinarize(rgb2gray(frameCrop), 'adaptive', 'ForegroundPolarity', 'dark',...
    'Sensitivity', 0.1); %adaptively binarize
bw = imcomplement(bw); %invert (BBs are black, need white for filling)
bwnr = imfill(bw, 'holes'); %fill holes
bwnr = bwareaopen(bwnr,minsize); %remove small white regions
bwnr = imcomplement(bwnr); %invert
bwnr = bwareaopen(bwnr,minsize); %remove small black regions
frameBin = bwnr | mask;
frameBin = imcomplement(frameBin); %output binary image!!
frameBin= bwareaopen(frameBin,minsize); %remove small white regions  
% - prevents tracking of partially occluded objects
s = regionprops(frameBin,'centroid');
t = regionprops(frameBin, 'BoundingBox');
u = regionprops(frameBin, 'area');
area = cat(1, u.Area);
centroids = cat(1,s.Centroid);
bounding = cat(1, t.BoundingBox);
end
