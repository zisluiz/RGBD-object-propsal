function copyImageRgb = Points2Image(points, imageRgb)
    copyImageRgb = imageRgb;
    for seg = 1 : length(points)
        randomColor = [randi([1 256]), randi([1 256]), randi([1 256])];
    
        for point = 1 : length(points{seg, 1})
            objIndex = points{seg, 1}(point);
            [r,c]=ind2sub(size(copyImageRgb),objIndex);         
            copyImageRgb(r, c, :) = randomColor;
        end
    end  
end