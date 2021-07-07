close all;
clear all;
clc;
frames=0;
net = load('trainingChessResnet101.mat')
resize = [227 227];
% m = mobiledev;
% cam = camera(m, 'back');
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
obj = VideoReader("IMG_7189.MOV");
%video = obj.read();

videoSize = obj.NumFrames;
x = 1;
boardCrop=[];
BCrop=[];
crops=[];
classTable={};
while (x < videoSize)
    frames = frames+1;
    I = read(obj,[x,x]);
    %I = imresize(I, 0.5);
    if (x< 2)
        boardCrop = cropChessBoard(I);
        BCrop = imcrop(I, boardCrop);
        crops = cropImages(BCrop);
        for i=1:size(crops,1)
            dimensions = crops(i,:);
            iCrop = imcrop(BCrop, dimensions);
            iCrop = imresize(iCrop, resize);
            class = classify(net.trainingChess, iCrop);
            classTable{i} = string(class);
            %drawrectangle('Label',class, 'Position',dimensions);
            x = x + 1;
        end
    else
        BCrop = imcrop(I, boardCrop);
        for i=1:size(crops,1)
            dimensions = crops(i,:);
            iCrop = imcrop(BCrop, dimensions);
            iCrop = imresize(iCrop, resize);
            class = classify(net.trainingChess, iCrop);
            classTable{i} = string(class);
            %drawrectangle('Label',class, 'Position',dimensions);
            x = x + 1;
        end
    end
    imshow(BCrop);
    for i=1:size(crops,1)
        dimen = crops(i,:);
        dimen(1) = dimen(1);
        dimen(2) = dimen(2);
        dimen(3) = dimen(3);
        dimen(4) = dimen(4);
        test1 = dimen(1)+(dimen(3)/2);
        test2 = dimen(2)+(dimen(4)/2);
        text(test1,test2,classTable{i},'Color','red','FontSize',14)
    end
end
%clear('cam');