function similarPatchClustering(basicImage, ...
                                upeBasicImage, ...
                                outputPatchMatchingFileName, ...
                                sim_ind, bdr, nWien)
%optimization based similar patch searching using clustering
%   Input:
%       basicImage: basically denoised image in BM3D
%       upeBasicImage: modified basicaImage by UPE, will used in our 
%           clustering-based patch searching
%       outputPatchMatchingFileName: filename to save our patch searching
%           results
%       sim_ind: similar patch indices by original BM3d patch matching
%       bdr: boundary length used for padding
%       h: image height
%       w: image width
%       nWien: patch size used in BM3D denoising and our patch searching
%
%   Version: 2019-08-20
%   Authors: Si Lu (lusi@pdx.edu)
%
%   References:
%   [1] Lu, Si. "Good Similar Patches for Image\nDenoising.", IEEE Winter 
%       Conference on Applications of Computer Vision (WACV). IEEE, 2019
%   Licence   : GPL v3+, see GPLv3.txt

%% Initialization
[basicImage_b, h, w] = padImage(basicImage, bdr);
[upeBasicImage_b, ~, ~] = padImage(upeBasicImage, bdr);
%basicImage_b    = padarray(basicImage,[16,16],'symmetric','both');  %add boundary to imag
%upeBasicImage_b = padarray(upeBasicImage,[16,16],'symmetric','both');  %add boundary to imag
Ref_N           = size(sim_ind,1); % number of referene patches
nWien2          = nWien*nWien;
n_sim           = 32;              % default similar patch number in BM3D
max_CN          = 4;               % max cluster number
[Gx,Gy]         = gradient(basicImage_b);
MagG            = (Gx.^2+Gy.^2).^0.5;
feature100      = zeros(100,nWien2);
fid             = fopen(outputPatchMatchingFileName,'w+');
CurrIndexes     = zeros(100,1);

%% similar patch clustering
for i=1:Ref_N
    Ind           = sim_ind(i,1);
    [Ref_i,Ref_j] = convert_cord(w,Ind,bdr);
    gradientMean  = mean(mean(MagG(Ref_i+bdr:Ref_i+bdr-1+nWien, Ref_j+bdr:Ref_j+bdr-1+nWien)));
    SimNum        = 0;
    for k = 1:100
        Ind=sim_ind(i,k);
        [I,J]=convert_cord(w,Ind,bdr);

        if(I<=h&&J<=w&&Ind>0)
            II     = I + bdr; 
            JJ     = J + bdr;
            SimNum = SimNum+1;
            CurrIndexes(SimNum,1) = Ind;
            feature100(SimNum,:)  = (reshape(upeBasicImage_b(II:II+nWien-1,JJ:JJ+nWien-1),[nWien2,1]))';
        end
    end   
    rng('default');
    rng(1);
    if(SimNum<=2)
        CN = 1;
    else
        validFeature = feature100(1:SimNum,:);
        Lamda        = adaptiveLambda(gradientMean);
        M            = size(feature100,2);
        N            = SimNum;
        min_MDL      = 1000000000;
        
        for CNK = 1:max_CN
            [label,ctrs] = kmeanspp(validFeature', CNK);  label=label';
            dataTerm = 0;
            for lk = 1:SimNum
                cur_lable = label(lk,1);
                cur_patch = validFeature(lk,:);
                cur_dif   = cur_patch'-ctrs(:,cur_lable);
                dataTerm  = dataTerm + sum(cur_dif.^2);
            end
            
            L = CNK *(1+  M + (M+1)*M/2)-1;
            smooth_term = Lamda * L*log(N*M);
            
            cur_MDL = dataTerm+smooth_term;
            if(cur_MDL < min_MDL)
                min_MDL     = cur_MDL;
                final_label = label;
                CN          = CNK;
            end
        end
    end
    if(CN>1)
        label      = final_label; 
        refLabel   = label(1,1);      % class of the reference patch
        tmpMask    = (label==refLabel);  
        simPatchCt = sum(tmpMask(:));   % number of similar patches in current cluster
        final_N    = min(n_sim, similarPatchNumCompute(simPatchCt));
        
        % To make sure we have enough similar patches as output. If not
        % enough, iteratively reduce the number of class by 1 until we
        % found enough similar patches
        currClusterNumber = CN;
        while(final_N<=2)&&(currClusterNumber>1)
            currClusterNumber = currClusterNumber-1;
            label             = kmeanspp(validFeature', currClusterNumber);  label=label';
            refLabel          = label(1,1);
            tmpMask           = (label==refLabel);
            simPatchCt        = sum(tmpMask(:));
            final_N           = min(n_sim, similarPatchNumCompute(simPatchCt));
        end
        fprintf(fid,'%i %i ',1,final_N);
        k=0;
        Ct=0;
        while Ct < final_N
            k=k+1;
            if(label(k,1)==refLabel)
                Ct = Ct+1;          
                fprintf(fid,'%i ', CurrIndexes(k,1));
            end
        end       
    else
        fprintf(fid,'%i ',0);
    end
    fprintf(fid,'\r\n');   
end
fclose(fid);