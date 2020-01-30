rgb = imresize(imread('datasets/selection/putkk/rgb/00001.png'), [360 640]);
depth = imresize(imread('datasets/selection/putkk/depth/00001.png'), [360 640]);
seg = imresize(imread('datasets/selection/putkk/gt/00001.png'), [360 640]);

%depthDouble=double(depth)/1000;
%depthDouble=im2double(depth)/10000;
depthDouble=im2double(depth);

%kinectv2 average
topleft = [1 1];
center = [952.6592286 530.7386644];
focal = 1078.68499;

pcloud=DepthtoCloud(depthDouble, topleft, center, focal);                      
ptCloud = pointCloud(pcloud);
ptCloudSingle = pointCloud(single(ptCloud.Location),...
                           'Color',ptCloud.Color,...
                           'Normal',ptCloud.Normal,...
                           'Intensity',ptCloud.Intensity);
                       
normal=pcnormal(pcloud,0.05,8);
normal=fix_normal_orientation( normal, pcloud );

%mat2PCDfile('test.pcd', normal);                       
                       
%pcwrite(ptCloudSingle,'teste.pcd')