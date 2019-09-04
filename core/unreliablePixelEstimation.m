function [modifiedPatch,patchWeight]=unreliablePixelEstimation(features)

%Implementation of our un-reliable pixel estimation, work for each
%reference noisy patch, we collect 100 similar patches and apply our UPE
%   Input:
%       features: (100,nWien2) feature
%   Output:
%       modifiedPatch: modified reference patch, represented as (p^2,1) vector
%       patchWeight: weight for each pixel in `modifiedPatch`, larger means
%       more confident.
%
%   Version: 2019-08-20
%   Authors: Si Lu (lusi@pdx.edu)
%
%   References:
%   [1] Lu, Si. "Good Similar Patches for Image\nDenoising.", IEEE Winter 
%       Conference on Applications of Computer Vision (WACV). IEEE, 2019
%   Licence   : GPL v3+, see GPLv3.txt

[patchNum,pixelNum,~] = size(features);
modifiedPatch         = zeros(pixelNum,1);
patchWeight           = zeros(pixelNum,1);
thr2                  = round(patchNum/2*0.8);
max_pixel_value_num   = 20;
lamda                 = 2;
for i0 = 1:pixelNum
    tmp_ith_pixels = features(:,i0);
    tmp_ith_pixels = sort(tmp_ith_pixels);

    x_mean = median(tmp_ith_pixels);
    x_std  = std(tmp_ith_pixels);

    x_left  = max(0,round(x_mean-lamda*x_std));
    x_right = min(255,round(x_mean+lamda*x_std));

    BlackNum = sum(tmp_ith_pixels<=x_left);
    WhiteNum = sum(tmp_ith_pixels>=x_right);
    
    a = min(round(patchNum/2)-1,max(1,max(BlackNum,WhiteNum)));
    
    if(BlackNum >= thr2)
        remained_pixels   = x_left;
        patchWeight(i0,1) = thr2;
    elseif(WhiteNum >= thr2)
        remained_pixels   = x_right;
        patchWeight(i0,1) = thr2;
    elseif((BlackNum > max_pixel_value_num && BlackNum < thr2)||...
           (WhiteNum > max_pixel_value_num && WhiteNum < thr2))&&...
           (a>10)
        remained_pixels   = tmp_ith_pixels(a:patchNum-a,1);        
        patchWeight(i0,1) = a;
    else
        remained_pixels   = tmp_ith_pixels;
        patchWeight(i0,1) = 0;
    end

    modifiedPatch(i0,1) = mean(remained_pixels);
end

