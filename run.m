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
    rgb = imresize(imageRgbOriginal, size(imageRgbOriginal(:,:,1))/3); 
    imageDepthOriginal = imread(strcat(datasetPath, '/depth/', depthFileName));
    depth = imresize(imageDepthOriginal, size(imageDepthOriginal(:,:,1))/3);
    
    %option 1
    %depthDouble=double(depth)/1000;
    depthDouble=im2double(depth);
    pcloud=DepthtoCloud(depthDouble);
    
    % option 2 - fill holes based on color  
    %rD = depth;
    %rD(isnan(depth)) = 0;
    %depth_fill = fill_depth_colorization(rgb, double(rD));    
    %pcloud = Depth2PCD(depth_fill) * 100;    
    
    [planeMat, planeRgb] = fnPlaneSegmentation(pcloud, depth);
    
    BBox = fnSuperpixel2Bbox(rgb, depth, pcloud, planeMat, imageName, sp_path);

    seg = fnSegmentProposal(rgb, depth, BBox, sp_path, imageName);    

    if ~exist(strcat('results/', datasetName), 'dir')
       mkdir(strcat('results/', datasetName));
    end    
    
    imwrite(seg, strcat('results/', datasetName, '/', depthFileName));
    filesCount = filesCount + 1;
end

tEnd = datetime('now');
tElapsed = between(tStart, tEnd);

fprintf(fid, "=== Total image predicted: %d\n", filesCount);
fprintf(fid, "=== Seconds per image: %d\n", (seconds(time(tElapsed)) / filesCount));
fprintf(fid, '=== End time: %s\n', datestr(datetime('now')));
fclose(fid);

fprintf('done\n');
