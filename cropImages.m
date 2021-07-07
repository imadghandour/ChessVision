function croppedBoxes = cropImages(image)
addpath('matching');
I = image;

%I = imresize(I, 0.5);
Ig = rgb2gray(I);

% Get a gaussian kernel for blurring
K = fspecial('gaussian');

% Blur the image
Igf = imfilter(Ig, K);
Igf = imfilter(Igf, K);
Igf = imfilter(Igf, K);

% Detect edges
E = edge(Ig, 'sobel');
se = strel('line',6,90);
se1 = strel('line',6,0);
afterOpening = imdilate(E,se);
afterOpening = imdilate(afterOpening,se1);

% Perform Hough Line transform
[H, T, R] = hough(afterOpening);

% Get top N line candidates from hough accumulator
N = 20;
P = houghpeaks(H, N);

% Get hough line parameters
lines = houghlines(Igf, T, R, P);

coeff =[];

pointInt = [];
% uses InterX:
% https://www.mathworks.com/matlabcentral/fileexchange/22441-curve-intersections,
% to find the intersection between the lines
for k = 1:length(lines)
     xy = [lines(k).point1(1) lines(k).point2(1);lines(k).point1(2) lines(k).point2(2)];
    for l = 1:length(lines)
        if(k~=l)
            xy1 = [lines(l).point1(1) lines(l).point2(1);lines(l).point1(2) lines(l).point2(2)];
            inter = InterX(xy,xy1);
            x = inter(1,:);
            y = inter(2,:);
            if (isempty(x) && isempty(y))
            else
                pointInt = [pointInt; [x y]];
            end
            
        end
    end
end

pointInt = unique(pointInt, 'rows');
k = boundary(pointInt(:,1),pointInt(:,2),1);

corners = findCorners(Ig,0.05,2);
chessboards = chessboardsFromCorners(corners);

board = chessboards{1,1};
k=1;
try
    bboxfinal = [];
    for i=1:size(board,1)-1
        for j=1:size(board,2)-1
            points = [];
            a = board(i,j);
            b = board(i,j+1);
            c = board(i+1,j);
            d = board(i+1,j+1);
            
            points = [points; corners.p(a,:)];
            points = [points; corners.p(b,:)];
            points = [points; corners.p(c,:)];
            points = [points; corners.p(d,:)];
            
            bb = boundingBox(points);
            xmin = bb(1,1);
            ymin = bb(1,3);
            width = bb(1,2)-bb(1,1);
            height = bb(1,4)-bb(1,3);
            bboxfinal = [bboxfinal;[xmin, ymin, width, height]];
            k=k+1;
        end
    end
    
    %extend bounding boxes
    centerPoint = board(4,4);
    centerPoint = corners.p(centerPoint,:);
    cornerPoints = [1 1; 1 7; 7 1; 7 7];
    for j=1:4
        firstEdge = board(cornerPoints(j,1),cornerPoints(j,2));
        firstEdge = corners.p(firstEdge,:);
        orientationCase = 1;
        if(firstEdge(1) < centerPoint(1) && firstEdge(2) < centerPoint(2))
            orientationCase = 3;
            bb2 = [firstEdge(1,1)-(width*1.1),firstEdge(1,2)-(height*1.1),width*1.1,height*1.1];
            bboxfinal = [bboxfinal;bb2];
            k=k+1;
        elseif(firstEdge(1) > centerPoint(1) && firstEdge(2) < centerPoint(2))
            orientationCase = 1;
            bb2 = [firstEdge(1,1),firstEdge(1,2)-(height*1.1),width*1.1,height*1.1];
            bboxfinal = [bboxfinal;bb2];
            k=k+1;
        elseif(firstEdge(1) < centerPoint(1) && firstEdge(2) > centerPoint(2))
            orientationCase = 4;
            bb2 = [firstEdge(1,1)-width,firstEdge(1,2),width*1.1,height*1.1];
            bboxfinal = [bboxfinal;bb2];
            k=k+1;
        elseif(firstEdge(1) > centerPoint(1) && firstEdge(2) > centerPoint(2))
            orientationCase = 2;
            bb2 = [firstEdge(1,1),firstEdge(1,2),width*1.1,height*1.1];
            bboxfinal = [bboxfinal;bb2];
            k=k+1;
        end
        
        switch orientationCase
            case 1
                for i=1:6
                    edgePoint = board(i,1);
                    edgePoint = corners.p(edgePoint,:);
                    bb2 = [edgePoint(1,1)-width,edgePoint(1,2)-(height*1.1),width*1.1,height*1.1];
                    bboxfinal = [bboxfinal;bb2];
                    k=k+1;
                end
            case 2
                for i=7:-1:2
                    edgePoint = board(1,i);
                    edgePoint = corners.p(edgePoint,:);
                    bb2 = [edgePoint(1,1),edgePoint(1,2)-(height*1.1),width*1.1,height*1.1];
                    bboxfinal = [bboxfinal;bb2];
                    k=k+1;
                end
                
            case 3
                for i=1:6
                    edgePoint = board(7,i);
                    edgePoint = corners.p(edgePoint,:);
                    bb2 = [edgePoint(1,1)-width,edgePoint(1,2),width*1.1,height*1.1];
                    bboxfinal = [bboxfinal;bb2];
                    k=k+1;
                end
                
            case 4
                for i=7:-1:2
                    edgePoint = board(i,7);
                    edgePoint = corners.p(edgePoint,:);
                    bb2 = [edgePoint(1,1),edgePoint(1,2),width*1.1,height*1.1];
                    bboxfinal = [bboxfinal;bb2];
                    k=k+1;
                end
        end
    end
    croppedBoxes = bboxfinal;
catch
    display("Could not identify full board,Please Realign");
    croppedBoxes = [];
end
