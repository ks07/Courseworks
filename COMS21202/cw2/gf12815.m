function gf12815()
    % Cleanup workspace
    clearvars; close all;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%% FOURIER ANALYSIS %%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % To extract features, read all images for each character.
    sFiles = dir('characters/S*.GIF');
    tFiles = dir('characters/T*.GIF');
    vFiles = dir('characters/V*.GIF');

    s = [];
    t = [];
    v = [];

    % Add each image contents as another 'layer'
    for sFile = sFiles'
        s = cat(3,s,double(imread(strcat('characters/', sFile.name))));
    end
    for tFile = tFiles'
        t = cat(3,t,double(imread(strcat('characters/', tFile.name))));
    end
    for vFile = vFiles'
        v = cat(3,v,double(imread(strcat('characters/', vFile.name))));
    end

    % Display the mean Fourier Domain of each character type.
    sfm = displayMeanFD(s);
    %displayMeanSobelFD(s);
    tfm = displayMeanFD(t);
    %displayMeanSobelFD(t);
    vfm = displayMeanFD(v);
    %displayMeanSobelFD(v);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%% FEATURE SELECTION %%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Pick the box features (x y w h)
    boxes = [
    %    300, 1,   40,  180; % Top vert
        310, 40,   20,  120; % Top vert
    %    310, 100,   20,  30; % Top vert
    %    100, 100, 100, 60; % Diag
    %    230, 150, 60, 45; % Diag
    %    240, 160, 30, 25; % Diag
    %    165, 10 , 90 , 40; % Top-left S
        145, 120, 90, 50; % V capture
    ];

    %Draw the boxes on the last figure
    drawBoxes(boxes);

    % Perform fft on all images of each type.
    sf = ftStack(s);
    tf = ftStack(t);
    vf = ftStack(v);
    
    % Display every FFT to visually inspect reasons for classification.
    %dispStack(log(sf + 1));
    %dispStack(log(tf + 1));
    %dispStack(log(vf + 1));

    % Get the values of each feature for each image.
    box1 = boxes(1,:);
    box2 = boxes(2,:);
    
    sBox1Sum = sumBoxMag(box1, sf);
    tBox1Sum = sumBoxMag(box1, tf);
    vBox1Sum = sumBoxMag(box1, vf);
    sBox2Sum = sumBoxMag(box2, sf);
    tBox2Sum = sumBoxMag(box2, tf);
    vBox2Sum = sumBoxMag(box2, vf);

    % Concatenate the various box sums into a matrix
    training = [
        sBox1Sum(:), sBox2Sum(:);
        tBox1Sum(:), tBox2Sum(:);
        vBox1Sum(:), vBox2Sum(:);
    ];

    % Get the number of each character we have.
    [~, ~, sCount] = size(s);
    [~, ~, tCount] = size(t);
    [~, ~, vCount] = size(v);

    % Get the list of the corresponding classes.
    group = [
        repmat('s', sCount, 1); % Copies the character to match the values
        repmat('t', tCount, 1);
        repmat('v', vCount, 1);
    ];

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%% K - NEAREST NEIGHBOUR CLASSIFICATION %%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Define how many neighbours to use.
    k = 5;
    
    % Use k-nearest-neighbour classification to classify 
    classified = knnclassify(training,training,group,k);
    
    % Print the classification of points and the counts of each.
    disp('Training:');
    disp(classified);
    disp('  per class total (s,t,v):');
    displayClassCount(classified);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%% DECISION BOUNDARIES %%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %figure; scatter(training(:,1),training(:,2));
    %training = log(training);
    %max(training);
    %figure; scatter(training(:,1),training(:,2));
    
    % Generate a list of regular points on 2D grid. Determine limits from
    % the training data.
    axisLimit = 1.5 * max(training(:));
    stepSize = axisLimit / 1000;
    
    axisPoints = 0:stepSize:axisLimit;
    [xMesh, yMesh] = meshgrid(axisPoints);
    mesh = [xMesh(:), yMesh(:)];

    % Classify every point in the mesg
    meshGroups = knnclassify(mesh,training,group,k);
    
    % Display the decision boundaries via a scatter.
    figure; gscatter(xMesh(:), yMesh(:), meshGroups);
    
    % Plot the training data over the decision boundaries.
    hold on; gscatter(training(:,1), training(:,2), classified, 'kkk', 'x.o', 5, 'off', 'Box1', 'Box2');
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%% NEW TEST DATA %%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Load new test data files
    sTestFiles = dir('test_chars/S*.GIF');
    tTestFiles = dir('test_chars/T*.GIF');
    vTestFiles = dir('test_chars/V*.GIF');

    tests = [];

    % Add each image contents as another 'layer'
    for sFile = sTestFiles'
        tests = cat(3,tests,double(imread(strcat('test_chars/', sFile.name))));
    end
    for tFile = tTestFiles'
        tests = cat(3,tests,double(imread(strcat('test_chars/', tFile.name))));
    end
    for vFile = vTestFiles'
        tests = cat(3,tests,double(imread(strcat('test_chars/', vFile.name))));
    end
    
    % Perform fft on all test images.
    testsF = ftStack(tests);
    
    % Get the values of each feature for each image.
    testsBox1Sum = sumBoxMag(boxes(1,:), testsF);
    testsBox2Sum = sumBoxMag(boxes(2,:), testsF);
    
    % Join the two box sums and classify.
    testPoints = [testsBox1Sum(:), testsBox2Sum(:)];
    testGroups = knnclassify(testPoints,training,group,k);
    
    % Display the classification of the test data.
    disp('Tests:');
    disp(testGroups);
    
    % Display every FFT to visually inspect reasons for classification.
    %dispStack(log(testsF + 1));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%% A B CLASSIFICATION %%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Load A and B
    ab = double(imread('characters/A1.GIF'));
    ab = cat(3,ab,double(imread('characters/B1.GIF')));
    
    % Perform fft on all test images.
    abF = ftStack(ab);

    % Get the values of each feature for each image.
    abBox1Sum = sumBoxMag(boxes(1,:), abF);
    abBox2Sum = sumBoxMag(boxes(2,:), abF);
    
    % Join the two box sums and classify.
    abPoints = [abBox1Sum(:), abBox2Sum(:)];
    abGroups = knnclassify(abPoints,training,group,k);
    
    % Display the classification of the A and B characters.
    disp('A & B:');
    disp(abGroups);
    
    % Display every FFT to visually inspect reasons for classification.
    %dispStack(log(abF + 1));
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% ALTERNATIVE CLASSIFIER %%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Create a decision tree using our training data.
    tree = classregtree(training,group);
    
    % Classify the training points using the tree. (These should all be
    % correct.)
    treeClassified = eval(tree,training);
    
    % See how decision tree classifies the test data and A & B
    treeTestC = eval(tree,testPoints);
    treeABC = eval(tree,abPoints);
    
    % Display the classification of all data using the tree.
    disp('Decision Tree Training:');
    disp(treeClassified);
    disp('Decision Tree Tests:');
    disp(treeTestC);
    disp('Decision Tree Tests:');
    disp(treeABC);
    
    % Display the tree
    view(tree);
    
    % Visualise the decision boundaries
    treeMeshGroups = eval(tree,mesh);
    figure; gscatter(xMesh(:), yMesh(:), treeMeshGroups);
    hold on; gscatter(testsBox1Sum(:), testsBox2Sum(:), treeTestC, 'kkk', 'x.o', 5, 'off', 'Box1', 'Box2');
end

% Shows all images in a stack, in new figures. Remember to log magnitude
% before passing in if showing FFT.
function dispStack(imMat)
    [~, ~, pages] = size(imMat);
    
    for i=1:pages,
        figure; imagesc(imMat(:,:,i)); axis off; colorbar; colormap gray;
    end
end

% Averages a 3D matrix and displays the fourier domain.
function Magq = displayMeanFD(imMat)
    % Mean the images
    f = mean(imMat,3);

    % Calculate the fourier transforms of the raw image
    z = fft2(f);
    q = fftshift(z);
    Magq = abs(q);
    %Phaseq = angle(q);

    % Display the log of the fourier space
    figure; imagesc(log(Magq+1)); axis off; colorbar; colormap gray;
end

% Averages a 3D matrix, performs Sobel edge detection, and displays both
% the raw output and the fourier domain.
function Magq = displayMeanSobelFD(imMat)
    % Mean the images
    f = mean(imMat,3);
    
    % Use Sobel edge detection to filter the image
    % Define the two convolution matrices
    fx = double([-1 0 1; -2 0 2; -1 0 1]);
    fy = double([1 2 1; 0 0 0; -1 -2 -1]);
    % Calculate the 2D convolution of the image
    gx = conv2(f,fx)/8;
    gy = conv2(f,fy)/8;
    % Combine the two outputs into magnitude and angle matrices
    mag = sqrt((gx).^2+(gy).^2);
    %ang = atan(gy./gx);
    % Display the edge detection magnitude matrix
    figure; imagesc(mag); axis off; colormap gray;

    % Calculate the fourier transform of the filtered image magnitude
    z = fft2(mag);
    q = fftshift(z);
    Magq = abs(q);
    %Phaseq = angle(q);
    
    % Display the log of the fourier space
    figure; imagesc(log(Magq+1)); axis off; colorbar; colormap gray;
end

% Draws the box classifiers over an image.
function drawBoxes(posDims)
    [rows, ~] = size(posDims);
    
    for i=1:rows,
        rectangle('position', posDims(i,:), 'facecolor', 'r', 'edgecolor', 'r');
    end
end

% Performs the FFT on all the images in a 3D matrix, returning magnitude
function fts = ftStack(imMat)
    [~, ~, pages] = size(imMat);
    fts = [];
    
    for i=1:pages,
        % Calculate the fourier transforms of the raw image
        z = fft2(imMat(:,:,i));
        q = fftshift(z);
        Magq = abs(q);
        %Phaseq = angle(q);
        fts = cat(3,fts,Magq);
    end
end

% Sums the absolute magnitudes of each box.
function magSum = sumBoxMag(box, imMat)
    % Get the positions of the box boundaries
    x1 = box(1);
    y1 = box(2);
    x2 = x1 + box(3);
    y2 = y1 + box(4);
    
    % Cut out the points of the box from all images
    area = imMat(y1:y2,x1:x2,:);
    % Sum in the first 2 dimensions.
    magSum = sum(sum(area,1),2);
end

% Displays the occurrences of each element in the list. (Output in
% alphabetical order)
function displayClassCount(classified)
    disp(histc(classified,unique(classified)));
end
