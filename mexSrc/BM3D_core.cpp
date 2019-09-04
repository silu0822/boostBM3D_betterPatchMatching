/** --------------------------- **/
/** - BM3D C++ implementation - **/
/** --------------------------- **/
/**
 * Author: Si Lu, Portland State University
 *
 * Description: This is a personal implementation based on an a previously 
 * released public domain software authored by Marc Lebrun in his paper
 * "An analysis and implementation of the bm3d image denoising method" in 
 * Image Processing On Line, 2012. Refer to this paper for algorithm details.
 *
 * How to compile:
 * To compile BM3D_core.mexwin64 in folder mexSrc:
 * 1. Install fftw libary (http://fftw.org/) into folder `./fftw-3.3.4-dll64`
 * 2. Copy libfftw3f-3.dll to the root folder
 * 3. Go to folder `mexSrc/` in MATLAB and compile use:
 *    "mex -llibfftw3f-3 -L./fftw-3.3.4-dll64 -I./fftw-3.3.4-dll64
 *    -I./localLib BM3D_core.cpp bm3d.cpp lib_transforms.cpp utilities.cpp 
 *    mt19937ar.c"
 **/

#include <mex.h>
#include <stdio.h>
#include <math.h>
#include <float.h>
#include <vector>
#include <numeric>
#include <cmath>
#include <iostream>
#include "matrix.h"

#include "bm3d.h"
#include "utilities.h"

#define YUV       0
#define YCBCR     1
#define OPP       2
#define RGB       3
#define DCT       4
#define BIOR      5
#define HADAMARD  6
#define NONE      7
#define SAVE_PATCH_MATCHING_TO_FILE 0
#define LOAD_PATCH_MATCHING_FROM_FILE 1
#define NUMBER_OF_SIMILAR_PATCH_CANDIDATE 100

// usage: [dImage, bImage, psnr] = BM3D_core(nImage, cImage, sigma, patchMatching_filename,save_or_load_patchMatching);

void mexFunction(int nlhs, mxArray *plhs[],          // output
                 int nrhs, const mxArray *prhs[])    // input
{
    const mwSize* dims;
    double *rawNoisyImage, *rawCleanImage;
    
    // Argument checking
    if (nlhs!=3 || nrhs != 5) {
        mexErrMsgTxt("Three output arguments and three input arguments are required.");
        mexErrMsgTxt("An example: BM3D_core(nImage, cImage, sigma, 'orgPM.txt', SAVE_PATCH_MATCHING_TO_FILE);");
    }
	
	// load input
    int numElements        = (int)mxGetNumberOfElements(prhs[0]);
    dims                   = mxGetDimensions(prhs[0]) ;
    rawNoisyImage          = (double*)mxGetData(prhs[0]) ;//mxGetData returns a void pointer, so cast it
	rawCleanImage          = (double*)mxGetData(prhs[1]) ;//mxGetData returns a void pointer, so cast it
    const unsigned width   = dims[1]; 
    const unsigned height  = dims[0]; // Note: first dimension provided is height and second is width
	const unsigned chnls   = 1;       // currently onyl support grayscale images
    const int imageSize    = width * height;

    std::vector<float> img_noisy(imageSize,0);
	std::vector<float> img_clean(imageSize,0);
	std::vector<float> img_basic(imageSize,0);
	std::vector<float> img_denoised(imageSize,0);

	// reading data from column-major MATLAB matrics to row-major C matrices
    // (i.e perform transpose)
    int x, y, ii;
    for(x = 0, ii = 0; x < (int)width; x++)
    {
        for(y = 0; y < (int)height; y++)
        {
            int i = (int)(y*width+x);
            img_noisy[i]    = (float)(rawNoisyImage[ii]);
			img_clean[i]    = (float)(rawCleanImage[ii]);
            ii++;
        }
    }

	//! Variables initialization
	const float    fSigma  = mxGetScalar(prhs[2]);
	const bool     useSD_1 = true;
	const bool     useSD_2 = false;
	const unsigned tau_2D_hard = BIOR;
	const unsigned tau_2D_wien = DCT;
	const unsigned color_space = YUV;
	
	//! Get the PM file name
	char *pmFileName;
	int   buflen,status;
	/* Get the length of the input string. */
    buflen = (mxGetM(prhs[3]) * mxGetN(prhs[3])) + 1;
	/* Allocate memory for input and output strings. */
    pmFileName = (char*)(mxCalloc(buflen, sizeof(char)));
	status = mxGetString(prhs[3], pmFileName, buflen);
    if (status != 0) 
      mexWarnMsgTxt("Not enough space. String is truncated.");
  
	const unsigned pmIOState = (unsigned)(mxGetScalar(prhs[4]));

	if (run_bm3d(fSigma, img_noisy, img_basic, img_denoised, width, height, chnls,
                 useSD_1, useSD_2, tau_2D_hard, tau_2D_wien, color_space, pmFileName, pmIOState)!= EXIT_SUCCESS)
        return;

	mxFree(pmFileName);
	float psnr=0, rmse=0;
	if(compute_psnr(img_clean, img_denoised, &psnr, &rmse) != EXIT_SUCCESS)
        return;

	// output
    double *dImage, *bImage;
    plhs[0] = mxCreateNumericMatrix(height,width,mxDOUBLE_CLASS,mxREAL);
	dImage = (double*)mxGetData(plhs[0]);
	plhs[1] = mxCreateNumericMatrix(height,width,mxDOUBLE_CLASS,mxREAL);
    bImage = (double*)mxGetData(plhs[1]);
	
	// copying data from row-major C matrix to column-major MATLAB matrix (i.e. perform transpose)
    for(x = 0, ii = 0; x < width; x++)
    {
        for(y = 0; y < height; y++)
        {
            int i0 = y*width+x;
            dImage[ii] = img_denoised[i0];
			bImage[ii] = img_basic[i0];
            ii++;
        }
    }
	
	plhs[2] = mxCreateNumericMatrix(1,1,mxDOUBLE_CLASS,mxREAL);
    double *bm3dPSNR = (double*)mxGetData(plhs[2]);//gives a void*, cast it to int*
    *bm3dPSNR = psnr;
}