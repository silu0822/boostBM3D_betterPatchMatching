function [upeImg, upeBasicImg] = upePipeline(noisyImage, ...
                                             basicImage, ...
                                             sim_ind, ...
                                             bdr, nWien)

%optimization unreliable pixel estimation
%   Input:
%       noisyImage: input noisy image to be denoised
%       basicImage: basically denoised image in BM3D
%       sim_ind: similar patch indices by original BM3d patch matching
%       bdr: boundary length used for padding
%       nWien: patch size used in BM3D denoising and our patch searching
%   Output:
%       upeImg: modified input noisy image
%       upeBasicImg: modified basically denoised image
%
%   Version: 2019-08-20
%   Authors: Si Lu (lusi@pdx.edu)
%
%   References:
%   [1] Lu, Si. "Good Similar Patches for Image\nDenoising.", IEEE Winter 
%       Conference on Applications of Computer Vision (WACV). IEEE, 2019

[noisyImage_b, h, w]  = padImage(noisyImage, bdr);
[basicImage_b, ~, ~]  = padImage(basicImage, bdr);
Ref_N                 = size(sim_ind,1);       % number of referene patches
nWien2                = nWien*nWien;
simThr                = 625*nWien*nWien;
feature100            = zeros(100,nWien2);
feature100N           = zeros(100,nWien2);
upeOutput_WeightSum   = zeros(h,w);
upeOutput_WeightImage = zeros(h,w);
for i=1:Ref_N
    Indices       = sim_ind(i,:);
    [Ref_i,Ref_j] = convert_cord(w,Indices(1,1),bdr);

    % Similar patch data collection
    SimNum = 0;
    for k = 1:100
        [I,J] = convert_cord(w,Indices(1,k),bdr);  
        if(I<=h&&J<=w&&Indices(1,1)>0)
            II=I+bdr; JJ=J+bdr;
            SimNum   = SimNum+1;
            tmpPatch = reshape( basicImage_b(II:II+nWien-1,JJ:JJ+nWien-1), [nWien2,1]);
            feature100(SimNum,:)  = (tmpPatch');
            feature100N(SimNum,:) = (reshape( noisyImage_b(II:II+nWien-1,JJ:JJ+nWien-1), [nWien2,1]) )';
            if(k==1); 
                Ref_Patch=tmpPatch';
            else
                Patch_dif=(tmpPatch'-Ref_Patch).^2;
                if(sum(Patch_dif(:))>simThr); break; end
            end            
        end
    end

    % Unreliable pixel estimation
    if(SimNum<10)
        % If too few valid patches, keep it unchange: set all weight to 1
        upePatch  = feature100(1,:)';
        upePatchW = ones(size(upePatch));
    else
        % Otherwise, perform un-reliable pixel estimation
        [upePatch, upePatchW] = unreliablePixelEstimation(feature100N(1:SimNum,:));
    end
    
    % Aggregate the modified patches back to image
    mod_patch = reshape(upePatch',[nWien,nWien]);
    mod_flag  = reshape(upePatchW',[nWien,nWien]);
    sm_i      = 0;
    for III=Ref_i:min(h,Ref_i+nWien-1)
        sm_i = sm_i+1;
        sm_j = 0;
        for JJJ=Ref_j:min(w,Ref_j+nWien-1)
            sm_j = sm_j + 1;
            if(mod_flag(sm_i,sm_j)>10)
                upeOutput_WeightImage(III,JJJ) = upeOutput_WeightImage(III,JJJ) + mod_flag(sm_i,sm_j);
                upeOutput_WeightSum(III,JJJ)   = upeOutput_WeightSum(III,JJJ)   + mod_flag(sm_i,sm_j) * mod_patch(sm_i,sm_j);
            end
        end
    end
end

% Post processing: only modify input noisy pixel if:
% 1) The diff between the upe modified image and the input iamge is large enough
% 2) The weight is large enough: This means the pixel has been modified 
%    according to enough amount of similar pixels.
% 3) We also randomly choose some pixels to be unchanged to avoid
%    over-smoothing, leading to singular matrix problem in later BM3D
%    denoising
initUpeImage = upeOutput_WeightSum./(upeOutput_WeightImage+0.000001);
randImge     = rand(size(initUpeImage));
contrW       = (upeOutput_WeightImage>100).* (randImge>0.2).* ...
               ( ( ( (basicImage>=128).*((initUpeImage - basicImage) >=  2.0) ) + ...
                   ( (basicImage<=128).*((initUpeImage - basicImage) <= -2.0) ) ) >0 );

upeImg = contrW .* initUpeImage + (1-contrW).*noisyImage;
upeBasicImg = contrW .* initUpeImage + (1-contrW).*basicImage;