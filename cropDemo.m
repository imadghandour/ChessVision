close all;
clear all;
clc;

net = load('trainingChessResnet101.mat')
resize = [227 227];
% cam = webcam('EpocCam Camera');
% preview(cam);
% for idx = 1:500
%     I = snapshot(cam);
%     I = imresize(I, 0.5);
%     crops = cropImages(I);
%     imshow(I);
%     if isempty(crops)
%     %display("Board not Detected");
%         continue;
%     else
%         for i=1:size(crops,1)
%             dimensions = crops(i,:);
%             dimensions(1) = ceil(dimensions(1));
%             dimensions(2) = ceil(dimensions(2));
%             dimensions(3) = ceil(dimensions(3));
%             dimensions(4) = ceil(dimensions(4));
%             iCrop = imcrop(I, dimensions);
%             iCrop = imresize(iCrop, resize);
%             class = classify(net.trainingChess, iCrop);
%             class = string(class);
%             %imshow(iCrop);
%             drawrectangle('Label',class, 'Position',dimensions);
%         end
%     end
% end
I = imread('IMG_6790.jpg');
I = imresize(I, 0.5);
I = cropChessBoard(I);
crops = cropImages(I);
imshow(I);
if isempty(crops)
    display("Board not Detected");
    %continue;
else
    for i=1:size(crops,1)
        dimensions = crops(i,:);
        dimensions(1) = ceil(dimensions(1));
        dimensions(2) = ceil(dimensions(2));
        dimensions(3) = ceil(dimensions(3));
        dimensions(4) = ceil(dimensions(4));
        iCrop = imcrop(I, dimensions);
        iCrop = imresize(iCrop, resize);
        class = classify(net.trainingChess, iCrop);
        class = string(class);
        %imshow(iCrop);
        drawrectangle('Label',class, 'Position',dimensions);
    end
end

%clear('cam');