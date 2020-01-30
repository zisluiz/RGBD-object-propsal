function [BBox] = fnSuperpixel2Bbox(imageRgb, rawDepth, pCloud, planeMat, imageName, sp_path)

   [h, w, d] = size(imageRgb); 
   
   if ~exist(fullfile(sp_path, imageName), 'dir')
      mkdir(fullfile(sp_path, imageName));
   end

   %% multi-scale graph based segmentations
   % parameters
   K = [100, 300, 500]; MIN = 200; sigma = 0.5;
   
   % collect masks
   masks_cell = GraphBasedSegmentation( imageRgb, pCloud, K, MIN, sigma);
   
   % load plane detections 
   planesMap = planeMat.planesMap;
   planes = planeMat.planes;
   inliers = planeMat.inliers;
   
   % watershed
   rD = rawDepth;
   rD(isnan(rawDepth)) = 0;
   depth_fill = fill_depth_colorization(imageRgb, double(rD));
   masksWS_cell = WatershedSegmentation(imageRgb, rawDepth, depth_fill);
   
   % bounding boxes from non-planar regions
   [bbox_np, ~] = BBfromNPRs(masks_cell, masksWS_cell, planesMap);  
   BB1 = m_rescale_bbox(bbox_np, [h,w], 1.3);
   bbox_np = cat(1, bbox_np, BB1);
   ParSave(fullfile(sp_path, imageName,'WSMasks_c.mat'), masksWS_cell);
   
   % big region proposals from planes
   [isV, isH, isB] = m_classify_planes(planes, pCloud);
   bbox_b = BBfromMPRs(inliers(~isB), pCloud);
   
   % object on vertical and horizontal plane proposals
   tmp = [];
   for j = 1:numel(K)
       [mapColor, ~] = m_segmentWrapper(imageRgb, nan(size(imageRgb)), K(j), MIN, sigma);
       tmp = cat(1, tmp, Label2Mask(mapColor));
   end
   [mapColor, ~] = m_segmentWrapper(imageRgb, nan(size(imageRgb)), 300, 200, 0.2);
   tmp = cat(1, tmp, Label2Mask(mapColor), masksWS_cell);
   [bbox_p, ~ ] = BBfromPRs (tmp, [h, w], inliers);

   
   % hierarchical clustering
   clusterTolerance = [2, 5, 10];
   [bbox_hc, masksHC_cell] = HierClustering(pCloud, clusterTolerance, inliers, isV, isH, isB, imageName);
   BB1 = m_rescale_bbox(bbox_hc, [h,w], 1.3);
   bbox_hc = cat(1, bbox_hc, BB1);
   
   % detected plane proposals
   [bbox_dp, masksDP] = BBfromDPs(inliers, [h, w]);
   masksDP_cell = Mask2Cell(masksDP);
   ParSave(fullfile(sp_path, imageName,'DPMasks_c.mat'), masksDP_cell);
   masksNPR_cell = [];
   

   % all bbox
   BB = cat(1, bbox_np, bbox_b, bbox_p, bbox_hc, bbox_dp);
   validBB = (BB(:,3) > 1) & (BB(:,4) >1); 
   BB = BB(validBB, :);
   area = BB(:,3).*BB(:,4);
   [~, ind] = sort(area, 'descend');
   BB = BB(ind, :);
   [BB, ~] = RemoveDupBbox(BB, 0.98);
   
   BBox = BB;
end

