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

datasetdir = 'datasets/selection';
images = [dir(fullfile(datasetdir,'**/rgb/*.jpg')); dir(fullfile(datasetdir,'**/rgb/*.png'))];
images = images(~[images.isdir]);  %remove folders from list
filesCount = 0;
scaleImage = 2;

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
        imageRgbOriginal = imcrop(imageRgbOriginal, [420 1 1079 1080]);
        imageDepthOriginal = imcrop(imageDepthOriginal, [420 1 1079 1080]);
    end

    rgb = imresize(imageRgbOriginal, size(imageRgbOriginal(:,:,1))/scaleImage); 
    depth = imresize(imageDepthOriginal, size(imageDepthOriginal(:,:,1))/scaleImage);    
    
    depthDouble=im2double(depth);
    %depthDouble=im2double(depth)/10000;
    %depthDouble=im2double(depth);

    %kinectv2 average
    focal = 1078.68499;
    topleft = [1 1];
    center = [952.6592286 530.7386644];

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
    
    BBox = fnSuperpixel2Bbox(rgb, depth, pcloud, planeMat, imageName, sp_path);

    [seg, seg_GC2D, seg_GC3D] = fnSegmentProposal(rgb, depth, BBox, sp_path, imageName);    

    if ~exist(strcat('tests/', datasetName), 'dir')
       mkdir(strcat('tests/', datasetName));
    end    
    
    imwrite(seg, strcat('tests/', datasetName, '/', imageName, '_seg.png'));
    imwrite(seg_GC2D, strcat('tests/', datasetName, '/', imageName, '_seg_GC2D.png'));
    imwrite(seg_GC3D, strcat('tests/', datasetName, '/', imageName, '_seg_GC3D.png'));
    imwrite(planeRgb, strcat('tests/', datasetName, '/', imageName, '_plane.png'));
    imwrite(rgb, strcat('tests/', datasetName, '/', imageName, '_ori.png'));
    filesCount = filesCount + 1;
    fprintf('Processed file %d\n', filesCount);
end

fprintf('done\n');
