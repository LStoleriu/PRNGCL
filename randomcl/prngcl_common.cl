/******************************************************************************
 * @file     prngcl_common.cl
 * @author   Vadim Demchik <vadimdi@yahoo.com>
 * @version  1.1.1
 *
 * @brief    [PRNGCL library]
 *           common module for all PRNG implementations
 *           contains precision selection, etc.
 *
 *
 * @section  CREDITS
 *
 *   Vadim Demchik and Alexey Gulov,
 *   "Increasing precision of uniform pseudorandom number generators",
 *   arXiv: 1402.xxxx [xx.xx].
 *
 *
 * @section  LICENSE
 *
 * Copyright (c) 2013, 2014 Vadim Demchik
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 *
 *    Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 *****************************************************************************/

#ifndef PRNGCL_COMMON_CL
#define PRNGCL_COMMON_CL

#define GID_SIZE    (get_global_size(0) * get_global_size(1) * get_global_size(2))
#define GID         (get_global_id(0) + get_global_id(1) * get_global_size(0) + get_global_id(2) * get_global_size(0) * get_global_size(1))

#define hgpu_single  float
#define hgpu_single2 float2
#define hgpu_single3 float3
#define hgpu_single4 float4

#if defined(cl_khr_fp64)

#define hgpu_double     double
#define hgpu_double2    double2
#define hgpu_double3    double3
#define hgpu_double4    double4

//#define PRNG_SKIP_CHECK     // if defined = skip uniformity checking in double precision

#if defined(cl_amd_fp64)    // AMD extension available?
	#pragma OPENCL EXTENSION cl_amd_fp64 : enable
#elif defined(cl_khr_fp64)  // Khronos extension available?
	#pragma OPENCL EXTENSION cl_khr_fp64 : enable
#endif

#ifndef PRNG_PRECISION
#define PRNG_PRECISION   0       // single precision by default
#endif

#if ((PRNG_PRECISION==0)||(PRNG_PRECISION==1))
#define PRECISION_SINGLE            // define single precision
#elif (PRNG_PRECISION==2)
#define PRECISION_DOUBLE            // define double precision
#endif

#ifdef PRECISION_DOUBLE
#define hgpu_float   hgpu_double
#define hgpu_float2  hgpu_double2
#define hgpu_float3  hgpu_double3
#define hgpu_float4  hgpu_double4
#else
#define hgpu_float   float
#define hgpu_float2  float2
#define hgpu_float3  float3
#define hgpu_float4  float4
#endif

inline hgpu_double4 hgpu_uint4_2_double4(uint4 x){
    hgpu_double4 result;
    result.x = (double) x.x;
    result.y = (double) x.y;
    result.z = (double) x.z;
    result.w = (double) x.w;

    return result;
}

inline hgpu_double hgpu_uint_to_double(uint rnd1, uint rnd2, uint rnd_min, uint rnd_max, double k){
    hgpu_double result = (rnd1 + k * rnd2 - (rnd_min + k * rnd_max)) / ((rnd_max - rnd_min) * (1.0 - k));
    return result;
}

inline hgpu_double4 hgpu_uint4_to_double4(uint4 rnd1, uint4 rnd2, uint rnd_min, uint rnd_max, double k){
    hgpu_double4 result;
    hgpu_double4 drnd1 = hgpu_uint4_2_double4(rnd1);
    hgpu_double4 drnd2 = hgpu_uint4_2_double4(rnd2);
    double a1 = (rnd_min + k * rnd_max);
    double a2 = ((rnd_max - rnd_min) * (1.0 - k));
        result.x = (drnd1.x + k * drnd2.x - a1) / a2;
        result.y = (drnd1.y + k * drnd2.y - a1) / a2;
        result.z = (drnd1.z + k * drnd2.z - a1) / a2;
        result.w = (drnd1.w + k * drnd2.w - a1) / a2;
        return result;
}

inline hgpu_double hgpu_float_to_double(float rnd1, float rnd2, double rnd_min, double rnd_max, double k){
    double a1 = (rnd_max - rnd_min);
    double a2 = trunc((a1-2.0*k) / k) + a1;
        return (trunc((rnd1-rnd_min-k) / k) + rnd2 - rnd_min) / a2 * (1.0-k*k);
}

inline hgpu_double2 hgpu_float4_to_double2(float4 rnd, double rnd_min, double rnd_max, double k){
    hgpu_double2 result;
    double a1 = (rnd_max - rnd_min);
    double a2 = trunc((a1-2.0*k) / k) + a1;
        result.x = (trunc((rnd.x-rnd_min-k) / k) + rnd.y - rnd_min) / a2 * (1.0-k*k);
        result.y = (trunc((rnd.z-rnd_min-k) / k) + rnd.w - rnd_min) / a2 * (1.0-k*k);
        return result;
}

inline hgpu_double4 hgpu_float4_to_double4(float4 rnd1, float4 rnd2, double rnd_min, double rnd_max, double k){
    hgpu_double4 result;
    double a1 = (rnd_max - rnd_min);
    double a2 = trunc((a1-2.0*k) / k) + a1;
        result.x = (trunc((rnd1.x-rnd_min-k) / k) + rnd2.x - rnd_min) / a2 * (1.0-k*k);
        result.y = (trunc((rnd1.y-rnd_min-k) / k) + rnd2.y - rnd_min) / a2 * (1.0-k*k);
        result.z = (trunc((rnd1.z-rnd_min-k) / k) + rnd2.z - rnd_min) / a2 * (1.0-k*k);
        result.w = (trunc((rnd1.w-rnd_min-k) / k) + rnd2.w - rnd_min) / a2 * (1.0-k*k);
        return result;
}

#else

#define hgpu_float   float
#define hgpu_float2  float2
#define hgpu_float3  float3
#define hgpu_float4  float4

#endif

inline float4 hgpu_uint4_to_float4(uint4 x){
    float4 result;
    result.x = (float) x.x;
    result.y = (float) x.y;
    result.z = (float) x.z;
    result.w = (float) x.w;

    return result;
}

typedef union _Uint_and_Float   // Uint <---> Float converter
{
    uint uint_value;
    float float_value;
} Uint_and_Float;

#endif
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                     
                                                                                                                                                      
