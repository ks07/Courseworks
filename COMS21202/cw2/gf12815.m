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

    sfm = displayMeanFD(s);
    %displayMeanSobelFD(s);
    tfm = displayMeanFD(t);
    %displayMeanSobelFD(t);
    vfm = displayMeanFD(v);
    %displayMeanSobelFD(v);
    
    %dim = size(vfm)
    
    %Pick the box classifiers (x y w h)
    boxes = [
        100 185 150 25; % Left hand horiz
        250 0   50  200;
    ];

    %Draw the boxes on the last diagram
    drawBoxes(boxes);
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