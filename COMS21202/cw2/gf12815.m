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
    
    %dim = size(vfm)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%% FEATURE SELECTION %%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Pick the box features (x y w h)
    boxes = [
    %    1,   185, 250, 25; % Left hand horiz
        300, 1,   40,  180; % Top vert
        100, 100, 100, 60; % Horiz
    ];

    %Draw the boxes on the last figure
    drawBoxes(boxes);

    % Perform fft on all images of each type.
    sf = ftStack(s);
    tf = ftStack(t);
    vf = ftStack(v);

    % Get the values of each feature for each image.
    sBox1Sum = sumBoxMag(boxes(1,:), sf);
    tBox1Sum = sumBoxMag(boxes(1,:), tf);
    vBox1Sum = sumBoxMag(boxes(1,:), vf);
    sBox2Sum = sumBoxMag(boxes(2,:), sf);
    tBox2Sum = sumBoxMag(boxes(2,:), tf);
    vBox2Sum = sumBoxMag(boxes(2,:), vf);

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

    % Use k-nearest-neighbour classification to classify 
    classified = knnclassify(training,training,group,2);
    
    % Print the total for each resultant class 
    displayClassCount(classified);
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
    area = imMat(x1:x2,y1:y2,:);
    % Sum in the first 2 dimensions.
    magSum = sum(sum(area,1),2);
end

function displayClassCount(classified)
    disp(histc(classified,unique(classified)));
end
