function croppedBoard = cropChessBoard(image)
% Read in image
I = image;

% Convert to grayscale
Ig = rgb2gray(I);

% Get a gaussian kernel for blurring
K = fspecial('gaussian',[10 10],3);

% Blur the image
Igf = imfilter(Ig, K);
Igf = imfilter(Igf, K);
Igf = imfilter(Igf, K);

[counts,x] = imhist(Igf,10);
T = otsuthresh(counts);
BW = imbinarize(Igf,T);

HSV = rgb2hsv(I);
h = HSV(:,:,1);
s = HSV(:,:,2);
v = HSV(:,:,3);

cform = makecform('srgb2lab');
lab_he = applycform(I,cform);

l = lab_he(:,:,1);
a = lab_he(:,:,2);
b = lab_he(:,:,3);

ab = double(s);
nrows = size(ab,1);
ncols = size(ab,2);
ab = reshape(ab,nrows*ncols,1);

nColors = 2;
% repeat the clustering 3 times to avoid local minima
[cluster_idx, cluster_center] = kmeans(ab,nColors,'distance','sqeuclidean', ...
                                      'Replicates',10);

pixel_labels = reshape(cluster_idx,nrows,ncols);
segmented_images = cell(1,2);
rgb_label = repmat(pixel_labels,[1 1 3]);

for k = 1:nColors
    color = I;
    color(rgb_label ~= k) = 0;
    segmented_images{k} = color;
end

% Blur the image
Igf = medfilt2(Igf);
% figure, imshow(I), title('original image');

BWs = Igf;
[~, threshold] = edge(Igf, 'sobel');
fudgeFactor = .6;
BWs = edge(Igf,'sobel', threshold * fudgeFactor);

se90 = strel('line', 5, 45);
se0 = strel('line', 5, 90);

BWsdil = imdilate(BWs, [se90 se0]);
BWdfill = imfill(BWsdil, 'holes');
BWnobord = imclearborder(BWdfill, 4);

seD = strel('diamond',1);
BWfinal = imerode(BWnobord,seD);
BWfinal = imerode(BWfinal,seD);
BWfinal = BWfinal*255;
if(cluster_center(2,1)<0.1)
    sg_img = segmented_images{2};
else
    sg_img = segmented_images{1};
end
for i=1:size(Igf,1)
    for j=1:size(Igf,2)
        if BWfinal(i,j)==0
            sg_img(i,j,1)=0;
            sg_img(i,j,2)=0;
            sg_img(i,j,3)=0;
        end
    end
end

sg_img_g = rgb2gray(sg_img);
BW = imbinarize(sg_img_g,'adaptive','ForegroundPolarity','dark','Sensitivity',0.4);

se = strel('disk',4);
afterOpening = imopen(BW,se);
afterOpening = imerode(afterOpening,se);

sg_img_g = rgb2gray(sg_img);
BW = imbinarize(sg_img_g,'adaptive','ForegroundPolarity','dark','Sensitivity',0.4);

se = strel('disk',7);
se1 = strel('line',6,60);
afterOpening = imopen(BW,se);
afterOpening = imdilate(afterOpening,se);

BW = edge(Ig,'sobel', 0.4);

stats = regionprops('table',afterOpening,'BoundingBox');
bb = stats.BoundingBox;

largestBoxWidth = 0;
largestBoxHeight = 0;
largestBox=[0 0 0 0];
for i=1:size(bb,1)
    if(bb(i,3)>largestBoxWidth && bb(i,4) > largestBoxHeight)
        largestBoxWidth=bb(i,3);
        largestBoxHeight=bb(i,4);
        largestBox=bb(i,:);
    end
end

largestBox(1) = largestBox(1)-(largestBox(1)*0.01);
largestBox(2) = largestBox(2)+(largestBox(2)*0.01);
largestBox(3) = largestBox(3)*1.03;
largestBox(4) = largestBox(4)*1.03;
%rectangle('Position', largestBox,'EdgeColor','r', 'LineWidth', 1);
%title('Detected Bounding Box');
%croppedBoard = imcrop(I,largestBox);
croppedBoard = largestBox;