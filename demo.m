% This is the demo to run our boosted BM3D in our WACV 2019 paper: 
% "Good Similar Patches for Image\nDenoising."
%
% References:
%   [1] Lu, Si. "Good Similar Patches for Image\nDenoising.", IEEE Winter 
%       Conference on Applications of Computer Vision (WACV). IEEE, 2019
%
% To compile `BM3D_core.mexwin64` in folder mexSrc:
% 1. Install fftw libary (http://fftw.org/) into folder `./fftw-3.3.4-dll64`
% 2. Copy libfftw3f-3.dll to the root folder
% 3. Go to folder mexSrc in MATLAB and compile:
%    "mex -llibfftw3f-3 -L./fftw-3.3.4-dll64 -I./fftw-3.3.4-dll64
%    -I./localLib BM3D_core.cpp bm3d.cpp lib_transforms.cpp utilities.cpp 
%    mt19937ar.c"
% Tested on (1) Windows 7, MATLAB 2012b, with compiler VS2008 SP1
%           (2) Windows 7, MATLAB 2015b, with a MinGW-w64 compiler
%
% To run, go back to the root folder, run "demo.m"

close all hidden;
clear all;
clc;

%% Setup
addpath('core\', 'util\', 'mexSrc\');
sigma  = 100;
cImage = double(imread('clean.png'));
nImage = double(imread('noisy.png'));

%% boost BM3D denoising
[denoisedImg, denoisedImg_bst, basicImg_bst] = boostBM3D(nImage, cImage, sigma);

%% save the results
imwrite(uint8(denoisedImg),'denoised.png');
imwrite(uint8(denoisedImg_bst),'denoised_bst.png');