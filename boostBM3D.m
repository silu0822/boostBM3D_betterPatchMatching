function [denoisedImg, denoisedImg_bst, basicImg_bst] = boostBM3D(nImage, cImage, sigma)
% This is the boosted BM3D code in our WACV 2019 paper: "Good Similar 
% Patches for Image\nDenoising."
%
% References:
%   [1] Lu, Si. "Good Similar Patches for Image\nDenoising.", IEEE Winter 
%       Conference on Applications of Computer Vision (WACV). IEEE, 2019

SAVE_PATCH_MATCHING_TO_FILE = 0;
LOAD_PATCH_MATCHING_FROM_FILE = 1;

%% Step one: run the original BM3D 
fprintf('Step 1: running the original BM3D...\n');
[dImage, bImage, psnr] = BM3D_core(nImage, cImage, sigma, 'orgPM.txt', SAVE_PATCH_MATCHING_TO_FILE);
fprintf('BM3D psnr = %f\n', psnr);

denoisedImg = uint8(dImage);

%% Step two: run our similar patch searching and save the results to files
fprintf('\nStep 2: running our patch matching!\n');
noisy_mod = clusteringPatchSearching(nImage, bImage, sigma, 'orgPM.txt', 'ourPM.txt');

%% Step three: run BM3D with our modified patch searching results
fprintf('\nStep 3: running BM3D with our patch matching results!\n');
[dImage_bst, bImage_bst, psnr_bst] = BM3D_core(noisy_mod, cImage, sigma, 'ourPM.txt', LOAD_PATCH_MATCHING_FROM_FILE);

denoisedImg_bst = uint8(dImage_bst);
basicImg_bst    = uint8(bImage_bst);
fprintf('BM3D_bst psnr = %f\n', psnr_bst);    

%%
delete orgPM.txt ourPM.txt %imBasic.png noisy_mod.png