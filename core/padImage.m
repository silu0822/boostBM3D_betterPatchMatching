function [image_b, h, w] = padImage(image, padSize)
if(size(image,3)==3)
    image = rgb2gray(image);
end
image   = double(image);  
image_b = padarray(image,[padSize,padSize],'symmetric','both');
[h,w]   = size(image);