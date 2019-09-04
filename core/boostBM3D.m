function [denoisedImg, basicImg, denoisedImg_bst, basicImg_bst] = boostBM3D(nImage, cImage, sigma)

SAVE_PATCH_MATCHING_TO_FILE = 0;
LOAD_PATCH_MATCHING_FROM_FILE = 1;

%% Step one: run the original BM3D
% Please make sure to compile the code in folder bm3d_src before running
% this step, see bm3d_src\README.txt for more details. In addition to the
% libpng library and the fftw library, please also add the OpenCV labrary. 
fprintf('\nStep one: running the original BM3D...\n');
[dImage, bImage, psnr] = bm3dOrgMex(nImage, cImage, sigma, 'orgPM.txt', SAVE_PATCH_MATCHING_TO_FILE);
fprintf('BM3D psnr = %f\n', psnr);

denoisedImg = uint8(dImage);
basicImg    = uint8(bImage);
imwrite(uint8(bImage),'imBasic.png');

%% Step two: run our similar patch searching and save the results to files
fprintf('\nStep two: running our Un-reliable Pixel Estimation and clustering-based patch matching!\n');
tic; clusteringSimilarPatchSearching('noisy.png', 'imBasic.png', 'orgPM.txt', sigma, 'ourPM.txt', 'noisy_mod.png'); toc;

%% Step three: run BM3D with our modified patch searching results
fprintf('\nStep three: running BM3D with our modifed PM (patch matching) results!\n');
noisy_mod = double(imread('noisy_mod.png'));
[dImage_bst, bImage_bst, psnr_bst] = bm3dOrgMex(noisy_mod, cImage, sigma, 'ourPM.txt', LOAD_PATCH_MATCHING_FROM_FILE);
denoisedImg_bst = uint8(dImage_bst);
basicImg_bst    = uint8(bImage_bst);
fprintf('BM3D_bst psnr = %f\n', psnr_bst);    

%%
delete orgPM.txt ourPM.txt imBasic.png