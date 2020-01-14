function [seg] = fnSegmentProposal(imageRgb, rawDepth, BB, sp_path, imageName)
    [h, w] = size(rawDepth);
    
    % fill holes based on color  
    rD = rawDepth;
    rD(isnan(rawDepth)) = 0;
    depth_fill = fill_depth_colorization(imageRgb, double(rD));
    
    pcd = Depth2PCD(depth_fill) * 100;
    
    % GC2D
    disp('Run GrabCut (RGB) ...');
    seg_GC2D = m_mask5GC_cell(imageRgb, BB, true);
    
    % GC3D
    disp('Run GrabCut (RGB-D) ...');
    seg_GC3D = m_mask5GC3D_cell(imageRgb, pcd,  BB, true);
 
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
    clear seg_GC2D seg_GC3D; 
    segCells = cat(1, seg, seg_DP, seg_WS, seg_MS);
    clear seg_DP seg_WS seg_MS seg;
    fprintf('number of segs (before): %d\n', numel(segCells));
    seg_Full = RemoveDupSeg(segCells, [h, w]); 
    fprintf('number of segs (after): %d\n', numel(seg_Full));    
    %save(fullfile(res_path, [imageName, '.mat']), 'seg_Full', '-v7.3');
    %imwrite(seg_Full, [res_segfull_path, '/', imageName, '.png']);
    
    %imwrite(ICopy, [res_segfull_path, '/', imageName, 'ori', '.png']);
    
    for seg = 1 : length(seg_Full)
        randomColor = [randi([1 256]), randi([1 256]), randi([1 256])];
    
        for point = 1 : length(seg_Full{seg, 1})
            objIndex = seg_Full{seg, 1}(point);
            [r,c]=ind2sub(size(imageRgb),objIndex);         
            imageRgb(r, c, :) = randomColor;
        end
    end  
        
    seg = imageRgb;

end

