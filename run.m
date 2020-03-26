% propose object segments for each RGB-D image in SUN RGB-D dataset.
% zhuo deng
% 09/02/2015

addpath('ext/toolbox_nyu_depth_v2');
addpath('src/planeDet');
addpath('ext/m_Grabcut');
addpath('ext/m_Grabcut_3D');
addpath('ext/EGBS3D');
addpath('ext/YAEL');
addpath('src/segmentations');
addpath('features');
addpath('src/vis');
addpath('src/util');

if ~exist('results', 'dir')
   mkdir('results')
end

sp_path = 'cache/sp';
if ~exist(sp_path, 'dir')
   mkdir(sp_path);
end

fid = fopen(strcat('results/run_', num2str(posixtime(datetime('now')) * 1e6), '.txt'), 'wt');
fprintf(fid, '=== Start time: %s\n', datestr(datetime('now')));

datasetdir = 'datasets/selection';
images = [dir(fullfile(datasetdir,'**/rgb/*.jpg')); dir(fullfile(datasetdir,'**/rgb/*.png'))];
images = images(~[images.isdir]);  %remove folders from list
filesCount = 0;
scaleImage = 2;

pid = int16(feature('getpid'));

tStart = datetime('now');

%parpool(4);
%parfor k = 1:length(images), 4
for k = 1:length(images)
    imageRgb = images(k);
    display(strcat('Processing image ', imageRgb.name));
    
    imageRgbFolders = strsplit(imageRgb.folder, '/');
    datasetName = imageRgbFolders{end-1};
    
    datasetPath = strjoin(imageRgbFolders(1:end-1), '/');
    depthFileName = strrep(imageRgb.name, 'jpg', 'png');
    imageName = strrep(depthFileName, '.png','');
    
    % Load image and other information
    imageRgbOriginal = imread(strcat(imageRgb.folder, '/', imageRgb.name));
    imageDepthOriginal = imread(strcat(datasetPath, '/depth/', depthFileName));

    if datasetName == "active_vision" || datasetName == "putkk"
        imageRgbOriginal = imcrop(imageRgbOriginal, [240 1 1439 1080]);
        imageDepthOriginal = imcrop(imageDepthOriginal, [240 1 1439 1080]);
    end

    rgb = imresize(imageRgbOriginal, size(imageRgbOriginal(:,:,1))/scaleImage, 'nearest'); 
    depth = imresize(imageDepthOriginal, size(imageDepthOriginal(:,:,1))/scaleImage, 'nearest');    
    
    depthDouble=im2double(depth);
    %depthDouble=im2double(depth)/10000;
    %depthDouble=im2double(depth);

    %kinectv2 average
    if datasetName == "active_vision" || datasetName == "putkk"
        topleft = [0 0];
        center = [953 531];
        focal = 1078.7;    
    else
        topleft = [0 0];
        center = [540 540];
        focal = 759.681;    
    end

    [pcloud, distance] = DepthtoCloud(depthDouble, topleft, center, focal);  
    
    %option 1
    %depthDouble=double(depth)/1000;
    %depthDouble=im2double(depth);
    %pcloud=DepthtoCloud(depthDouble);
    
    % option 2 - fill holes based on color  
    %rD = depth;
    %rD(isnan(depth)) = 0;
    %depth_fill = fill_depth_colorization(rgb, double(rD));    
    %pcloud = Depth2PCD(depth_fill) * 100;    
    
    [planeMat, planeRgb] = fnPlaneSegmentation(pcloud, depth);
    [status,cmdout] = unix(strcat('top -n 1 -p ', num2str(pid)));
    fprintf(fid, "%s\n", cmdout);
    
    BBox = fnSuperpixel2Bbox(rgb, depth, pcloud, planeMat, imageName, sp_path);
    [status,cmdout] = unix(strcat('top -n 1 -p ', num2str(pid)));
    fprintf(fid, "%s\n", cmdout);
    
    seg = fnSegmentProposal(rgb, depth, BBox, sp_path, imageName);    
    [status,cmdout] = unix(strcat('top -n 1 -p ', num2str(pid)));
    fprintf(fid, "%s\n", cmdout);
    
    if ~exist(strcat('results/', datasetName), 'dir')
       mkdir(strcat('results/', datasetName));
    end    
    
    imwrite(seg, strcat('results/', datasetName, '/', depthFileName));
    filesCount = filesCount + 1;
    fprintf('Processed file %d\n', filesCount);
end

tEnd = datetime('now');
tElapsed = between(tStart, tEnd);

fprintf(fid, "=== Total image predicted: %d\n", filesCount);
fprintf(fid, "=== Seconds per image: %d\n", (seconds(time(tElapsed)) / filesCount));
fprintf(fid, '=== End time: %s\n', datestr(datetime('now')));
fclose(fid);

fprintf('done\n');
