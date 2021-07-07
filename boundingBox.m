function box = boundingBox(points)
% compute extreme x and y values
xmin = min(points(:,1));
xmax = max(points(:,1));
ymin = min(points(:,2));
ymax = max(points(:,2));
box = [xmin xmax ymin ymax];
