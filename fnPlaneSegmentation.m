function [planeMat,planeRgb] = fnPlaneSegmentation(pcloud,rawDepth)
   % plane detection
   % Note: pcd should have cm unit as input
   planeMat = PlanesDet(pcloud, rawDepth);   
   planeRgb = Label2Rgb(planeMat.planesMap);
end