% Cleanup workspace
clearvars; close all;

% To extract features, read all images for each character.
sFiles = dir('characters/S*.GIF');
tFiles = dir('characters/T*.GIF');
vFiles = dir('characters/V*.GIF');

s = [];
t = [];
v = [];

for sFile = sFiles'
    disp(sFile.name)
    s = cat(3,s,double(imread(strcat('characters/', sFile.name))));
end
for tFile = tFiles'
    disp(sFile.name)
    t = cat(3,t,double(imread(strcat('characters/', tFile.name))));
end
for vFile = vFiles'
    disp(sFile.name)
    v = cat(3,v,double(imread(strcat('characters/', vFile.name))));
end

% Read the image
f = mean(s,3);
%f = s(:,:,2);

% Calculate the fourier transforms of the raw image
z = fft2(f);
q = fftshift(z);
Magq = abs(q);
Phaseq = angle(q);

% Display the log of the fourier space
imagesc(log(abs(q)+1)); axis off; colorbar; colormap gray;

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
Phaseq = angle(q);
% Display the log of the fourier space
figure; imagesc(log(abs(q)+1)); axis off; colorbar; colormap gray;




% Read the image
f = mean(t,3);
%f = s(:,:,2);

% Calculate the fourier transforms of the raw image
z = fft2(f);
q = fftshift(z);
Magq = abs(q);
Phaseq = angle(q);

% Display the log of the fourier space
figure; imagesc(log(abs(q)+1)); axis off; colorbar; colormap gray;

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
Phaseq = angle(q);
% Display the log of the fourier space
figure; imagesc(log(abs(q)+1)); axis off; colorbar; colormap gray;




% Read the image
f = mean(v,3);
%f = s(:,:,2);

% Calculate the fourier transforms of the raw image
z = fft2(f);
q = fftshift(z);
Magq = abs(q);
Phaseq = angle(q);

% Display the log of the fourier space
figure; imagesc(log(abs(q)+1)); axis off; colorbar; colormap gray;

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
Phaseq = angle(q);
% Display the log of the fourier space
figure; imagesc(log(abs(q)+1)); axis off; colorbar; colormap gray;
