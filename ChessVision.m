close all;
clear;
clc;

%Import the Datasets
originalTrainings = imageDatastore('Chess\Train\', ...
    'IncludeSubfolders',true, ...
    'LabelSource','foldernames');
originalTest = imageDatastore('ChessDUP\Train\', ...
    'IncludeSubfolders',true, ...
    'LabelSource','foldernames');

% To resize the Input
inputSize = [227 227];
originalTrainings.ReadFcn = @(loc)imresize(imread(loc),inputSize);
originalTest.ReadFcn = @(loc)imresize(imread(loc),inputSize);

%Split Dataset into Training and Validation Sets
[imgsTrain,imgsValidation] = splitEachLabel(originalTrainings,0.7,'randomized');

%Improting Pre-Trained Neural Network
net = resnet101;

%Stripping and Redefined Neural Network's Classification and Input Layers
%%%%%%%%%%%for DAG NN%%%%%%%%%%%%%%%%%%%%%
if isa(net,'SeriesNetwork') 
  lgraph = layerGraph(net.Layers); 
else
  lgraph = layerGraph(net);
end 

[learnableLayer,classLayer] = findLayersToReplace(lgraph);
[learnableLayer,classLayer] 

numClasses = numel(categories(imgsTrain.Labels));

if isa(learnableLayer,'nnet.cnn.layer.FullyConnectedLayer')
    newLearnableLayer = fullyConnectedLayer(numClasses, ...
        'Name','new_fc', ...
        'WeightLearnRateFactor',10, ...
        'BiasLearnRateFactor',10);
    
elseif isa(learnableLayer,'nnet.cnn.layer.Convolution2DLayer')
    newLearnableLayer = convolution2dLayer(1,numClasses, ...
        'Name','new_conv', ...
        'WeightLearnRateFactor',10, ...
        'BiasLearnRateFactor',10);
end

lgraph = replaceLayer(lgraph,learnableLayer.Name,newLearnableLayer);

newClassLayer = classificationLayer('Name','new_classoutput');
lgraph = replaceLayer(lgraph,classLayer.Name,newClassLayer);

layer = imageInputLayer([227 227 3],'Name','input');

lgraph = replaceLayer(lgraph,'data', layer); %'input_1' for resnet50; 'data' for googlenet and resnet101

%Freeze Layers
layers = lgraph.Layers;
connections = lgraph.Connections;

layers(1:10) = freezeWeights(layers(1:10));
lgraph = createLgraphUsingConnections(layers,connections);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%Augmentation of Validation and Training
pixelRange = [-30 30];
imagesize = [227 227 3];

imageAugmenter = imageDataAugmenter( ...
    'RandXReflection',true, ...
    'RandXTranslation',pixelRange, ...
    'RandYTranslation',pixelRange);
augimgsTrain = augmentedImageDatastore(imagesize,imgsTrain, ...
    'DataAugmentation',imageAugmenter);

augimgsValidation = augmentedImageDatastore(imagesize,imgsValidation);

%Training, Validation and Results
miniBatchSize = 32;
valFrequency = floor(numel(augimgsTrain.Files)/miniBatchSize);
trainOpt = trainingOptions('sgdm', ...
    'Momentum', 0.9, ...
    'MaxEpochs', 15, ...
    'InitialLearnRate',3e-4, ...
    'Shuffle','every-epoch', ...
    'ValidationData', augimgsValidation, ...
    'ValidationFrequency', valFrequency, ...
    'LearnRateSchedule','piecewise','LearnRateDropFactor',0.2 ,'LearnRateDropPeriod',5,...
    'L2Regularization',0.0005, ...
    'MiniBatchSize', miniBatchSize, ...
    'Verbose', false, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'multi');

trainingChess = trainNetwork(augimgsTrain, lgraph, trainOpt);
%To Save Chess Training State for Use Later in Classificaiton
save trainingChessResnet101
%To Test Trained Netowrk with Testing Images
[YPred, scores] = classify(trainingChess,originalTest);
YTest = originalTest.Labels;
%Outputs Testing Accuracy
accuracy = mean(YPred == YTest)





