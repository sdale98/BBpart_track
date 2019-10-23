%% Advance to middle image, adaptively mask threshold etc then plot objects

v.CurrentTime = (timestart + timeend)/2;
[frameCrop,frameBin, centers, radii, centroids] = bbtrack(v, maskimp, crop);
%call function which outputs cropped frame, masked + thresholded + noise
%reduced frame frameBin, centers + radii of detected circles, centroids of
%detected regions

%Show example figures:

figure('Name','Plotted Image e.g.','NumberTitle','off');
imshow(frameCrop);
axis on
hold on
i = plot(centroids(:,1),centroids(:,2),'b*');
j = plot(centers(:, 1), centers(:, 2), 'r+');
l=legend('Region Centroids','Circle Centers');
set(l,'fontsize',14,'Interpreter','latex', 'location', 'southoutside')

figure('Name','Masked Image e.g.','NumberTitle','off');
imshow(frameBin);
axis on
hold on
i = plot(centroids(:,1),centroids(:,2),'b*');
j = plot(centers(:, 1), centers(:, 2), 'r+');
l=legend('Region Centroids','Circle Centers');
set(l,'fontsize',14,'Interpreter','latex', 'location', 'southoutside')

%% Y setting
