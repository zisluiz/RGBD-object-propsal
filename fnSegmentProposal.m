function [seg, seg_GC2D_res, seg_GC3D_res] = fnSegmentProposal(imageRgb, rawDepth, BB, sp_path, imageName)
    clear seg_GC2D seg_GC3D; 
    [h, w] = size(rawDepth);
    
    % fill holes based on color  
    rD = rawDepth;
    rD(isnan(rawDepth)) = 0;
    depth_fill = fill_depth_colorization(imageRgb, double(rD));
    
    pcd = Depth2PCD(depth_fill) * 100;
    
    % GC2D
    disp('Run GrabCut (RGB) ...');
    seg_GC2D = m_mask5GC_cell(imageRgb, BB, true);
    seg_GC2D_res = seg_GC2D;
    
    % GC3D
    disp('Run GrabCut (RGB-D) ...');
    seg_GC3D = m_mask5GC3D_cell(imageRgb, pcd,  BB, true);
    seg_GC3D_res = seg_GC3D;
 
    % load Watershed masks
    var = load(fullfile('cache/sp', imageName, 'WSMasks_c.mat'));
    seg_WS = var.masksWS_cell;
    
    % MS
    K = [300, 500];  MIN = 200;  sigma = 0.5;
    seg_MS = GraphBasedSegmentation(imageRgb, pcd, K, MIN, sigma);
    
    % DP
    var = load(fullfile(sp_path, imageName, 'DPMasks_c.mat'));
    seg_DP = var.masksDP_cell;
    
    % remove duplicated
    seg = RemoveDupGCxD(seg_GC2D, seg_GC3D, [h, w]);
    %clear seg_GC2D seg_GC3D; 
    segCells = cat(1, seg, seg_DP, seg_WS, seg_MS);
    clear seg_DP seg_WS seg_MS seg;
    fprintf('number of segs (before): %d\n', numel(segCells));
    seg_Full = RemoveDupSeg(segCells, [h, w]); 
    fprintf('number of segs (after): %d\n', numel(seg_Full));    
    %save(fullfile(res_path, [imageName, '.mat']), 'seg_Full', '-v7.3');
    %imwrite(seg_Full, [res_segfull_path, '/', imageName, '.png']);
    
    %imwrite(ICopy, [res_segfull_path, '/', imageName, 'ori', '.png']);
    
    seg = Points2Image(seg_Full, imageRgb);
    seg_GC2D_res = Points2Image(seg_GC2D_res, imageRgb);
    seg_GC3D_res = Points2Image(seg_GC3D_res, imageRgb);
end