/**
 * NormmixpdfSlowGPU.cu
 * Author:       Vilius Narbutas
 * Date:         2013
 * Description:  This program implements GPU version of 'for' loop in 
 *          normmixpdf_slow. 
 * Compilation:  nvcc -arch=sm_20 -ptx NormmixpdfSlowGPU.cu
 * Requirements: Graphics card that supports >2x architecture.
 *
 * Notes:        These functions support only 1D data arrays at the moment.
 **
 */

//#define _USE_MATH_DEFINES
#include <cmath>

// This program implements GPU version of normmixpdf_slow.
__global__ void NormmixpdfSlowGPU(double *p, double const *cov, 
        double const *mu, double const *w, double const *x, 
        double const dn, double const a, double const size_x)
{
    int id_x = threadIdx.x;
    int id_y = blockIdx.y;
    
    for (int i = id_x*1000+id_y; i < size_x; i+=1000)
    {
        double dx = 0;
        dx = x[i] - mu[id_x];
        p[i] = w[id_x] * (1/(a*sqrt(cov[id_x])))*exp (-0.5*dx*dx/(cov[id_x]+dn));
    }
}