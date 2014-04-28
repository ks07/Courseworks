% Cleanup workspace
clearvars; close all;

% Read the image
f = double(imread('characters/V4.GIF'));

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
