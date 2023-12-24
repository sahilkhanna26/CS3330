#include <stdio.h>
#include <stdlib.h>
#include "defs.h"
#include <smmintrin.h>
#include <immintrin.h>

/* 
 * Please fill in the following team struct 
 */
who_t who = {
    "Hasbulla",           /* Scoreboard name */
    "Sahil Khanna",      /* First member full name */
    "sk5xvh@virginia.edu",     /* First member email address */
};

/*** UTILITY FUNCTIONS ***/

/* You are free to use these utility functions, or write your own versions
 * of them. */

/* A struct used to compute averaged pixel value */
typedef struct {
    unsigned short red;
    unsigned short green;
    unsigned short blue;
    unsigned short alpha;
    unsigned short num;
} pixel_sum;

/* Compute min and max of two integers, respectively */
static int min(int a, int b) { return (a < b ? a : b); }
static int max(int a, int b) { return (a > b ? a : b); }

/* 
 * initialize_pixel_sum - Initializes all fields of sum to 0 
 */
static void initialize_pixel_sum(pixel_sum *sum) 
{
    sum->red = sum->green = sum->blue = sum->alpha = 0;
    sum->num = 0;
    return;
}

/* 
 * accumulate_sum - Accumulates field values of p in corresponding 
 * fields of sum 
 */
static void accumulate_sum(pixel_sum *sum, pixel p) 
{
    sum->red += (int) p.red;
    sum->green += (int) p.green;
    sum->blue += (int) p.blue;
    sum->alpha += (int) p.alpha;
    sum->num++;
    return;
}

/* 
 * assign_sum_to_pixel - Computes averaged pixel value in current_pixel 
 */
static void assign_sum_to_pixel(pixel *current_pixel, pixel_sum sum) 
{
    current_pixel->red = (unsigned short) (sum.red/sum.num);
    current_pixel->green = (unsigned short) (sum.green/sum.num);
    current_pixel->blue = (unsigned short) (sum.blue/sum.num);
    current_pixel->alpha = (unsigned short) (sum.alpha/sum.num);
    return;
}

/* 
 * avg - Returns averaged pixel value at (i,j) 
 */
static pixel avg(int dim, int i, int j, pixel *src) 
{
    pixel_sum sum;
    pixel current_pixel;

    initialize_pixel_sum(&sum);
    for(int jj=max(j-1, 0); jj <= min(j+1, dim-1); jj++) 
	for(int ii=max(i-1, 0); ii <= min(i+1, dim-1); ii++) 
	    accumulate_sum(&sum, src[RIDX(ii,jj,dim)]);

    assign_sum_to_pixel(&current_pixel, sum);
 
    return current_pixel;
}



char naive_smooth_descr[] = "naive_smooth: Naive baseline implementation";
void naive_smooth(int dim, pixel *src, pixel *dst) 
{
   
    for (int i = 0; i < dim; i++)
    for (int j = 0; j < dim; j++)
            dst[RIDX(i,j, dim)] = avg(dim, i, j, src);
}
            
    
char another_smooth_descr[] = "another_smooth_without_AVX: Another version of smooth";
void another_smooth_without_avx(int dim, pixel *src, pixel *dst) 
{
   

    //side 1

    int j_1 = 0;

    for (int i_1 = 1; i_1 <dim-1; i_1++){
         pixel_sum sum;
         pixel current_pixel;

    initialize_pixel_sum(&sum);
    for(int jj=max(j_1-1, 0); jj <= min(j_1+1, dim-1); jj++) 
    for(int ii=max(i_1-1, 0); ii <= min(i_1+1, dim-1); ii++) 
        accumulate_sum(&sum, src[RIDX(ii,jj,dim)]);

    assign_sum_to_pixel(&current_pixel, sum);
 
    
 
         


        dst[RIDX(i_1,j_1, dim)] = current_pixel;

        }

    //side 2 

    int i_2 =0;

    for (int j_2 = 0; j_2 <dim; j_2++){
         pixel_sum sum;
         pixel current_pixel;

        initialize_pixel_sum(&sum);
        for(int jj=max(j_2-1, 0); jj <= min(j_2+1, dim-1); jj++) 
        for(int ii=max(i_2-1, 0); ii <= min(i_2+1, dim-1); ii++) 
        accumulate_sum(&sum, src[RIDX(ii,jj,dim)]);

    assign_sum_to_pixel(&current_pixel, sum);
 
    
 
         


        dst[RIDX(i_2,j_2, dim)] = current_pixel;


        }

    //side 3

    int j_3 = dim-1;
    for (int i_3 = 1; i_3 <dim-1; i_3++){
         pixel_sum sum;
         pixel current_pixel;

        initialize_pixel_sum(&sum);
        for(int jj=max(j_3-1, 0); jj <= min(j_3+1, dim-1); jj++) 
        for(int ii=max(i_3-1, 0); ii <= min(i_3+1, dim-1); ii++) 
        accumulate_sum(&sum, src[RIDX(ii,jj,dim)]);

    assign_sum_to_pixel(&current_pixel, sum);
 
    
 
         


        dst[RIDX(i_3,j_3, dim)] = current_pixel;


        }

    //side 4
    int i_4 =dim-1;

    for (int j_4 = 0; j_4 <dim; j_4++){
        pixel_sum sum;
        pixel current_pixel;

        initialize_pixel_sum(&sum);
        for(int jj=max(j_4-1, 0); jj <= min(j_4+1, dim-1); jj++) 
        for(int ii=max(i_4-1, 0); ii <= min(i_4+1, dim-1); ii++) 
        accumulate_sum(&sum, src[RIDX(ii,jj,dim)]);

        assign_sum_to_pixel(&current_pixel, sum);
 
    
 
         


        dst[RIDX(i_4,j_4, dim)] = current_pixel;


        }



    //center 

    for (int i = 1; i < dim-1; i++){
    for (int j = 1; j < dim-1; j++){

        pixel_sum center_sum;
        pixel center_pixel;

        initialize_pixel_sum(&center_sum);
        accumulate_sum(&center_sum, src[RIDX(i-1,j-1,dim)]);
        accumulate_sum(&center_sum, src[RIDX(i-1,j,dim)]);
        accumulate_sum(&center_sum, src[RIDX(i-1,j+1,dim)]);
        accumulate_sum(&center_sum, src[RIDX(i,j-1,dim)]);
        accumulate_sum(&center_sum, src[RIDX(i,j,dim)]);
        accumulate_sum(&center_sum, src[RIDX(i,j+1,dim)]);
        accumulate_sum(&center_sum, src[RIDX(i+1,j-1,dim)]);
        accumulate_sum(&center_sum, src[RIDX(i+1,j,dim)]);
        accumulate_sum(&center_sum, src[RIDX(i+1,j+1,dim)]);


        assign_sum_to_pixel(&center_pixel, center_sum);


        dst[RIDX(i,j, dim)] = center_pixel;
        
    }
    }
}
           


char another_smooth_descr_with_avx[] = "another_smooth_with_AVX: Another version of smooth";
void another_smooth_with_avx(int dim, pixel *src, pixel *dst) {


    //side 1

    int j_1 = 0;

    for (int i_1 = 1; i_1 <dim-1; i_1++){
         pixel_sum sum;
         pixel current_pixel;

    initialize_pixel_sum(&sum);
    for(int jj=max(j_1-1, 0); jj <= min(j_1+1, dim-1); jj++) 
    for(int ii=max(i_1-1, 0); ii <= min(i_1+1, dim-1); ii++) 
        accumulate_sum(&sum, src[RIDX(ii,jj,dim)]);

    assign_sum_to_pixel(&current_pixel, sum);
 
    
 
         


        dst[RIDX(i_1,j_1, dim)] = current_pixel;

        }

    //side 2 

    int i_2 =0;

    for (int j_2 = 0; j_2 <dim; j_2++){
         pixel_sum sum;
         pixel current_pixel;

        initialize_pixel_sum(&sum);
        for(int jj=max(j_2-1, 0); jj <= min(j_2+1, dim-1); jj++) 
        for(int ii=max(i_2-1, 0); ii <= min(i_2+1, dim-1); ii++) 
        accumulate_sum(&sum, src[RIDX(ii,jj,dim)]);

    assign_sum_to_pixel(&current_pixel, sum);
 
    
 
         


        dst[RIDX(i_2,j_2, dim)] = current_pixel;


        }

    //side 3

    int j_3 = dim-1;
    for (int i_3 = 1; i_3 <dim-1; i_3++){
         pixel_sum sum;
         pixel current_pixel;

        initialize_pixel_sum(&sum);
        for(int jj=max(j_3-1, 0); jj <= min(j_3+1, dim-1); jj++) 
        for(int ii=max(i_3-1, 0); ii <= min(i_3+1, dim-1); ii++) 
        accumulate_sum(&sum, src[RIDX(ii,jj,dim)]);

    assign_sum_to_pixel(&current_pixel, sum);
 
    
 
         


        dst[RIDX(i_3,j_3, dim)] = current_pixel;


        }

    //side 4
    int i_4 =dim-1;

    for (int j_4 = 0; j_4 <dim; j_4++){
        pixel_sum sum;
        pixel current_pixel;

        initialize_pixel_sum(&sum);
        for(int jj=max(j_4-1, 0); jj <= min(j_4+1, dim-1); jj++) 
        for(int ii=max(i_4-1, 0); ii <= min(i_4+1, dim-1); ii++) 
        accumulate_sum(&sum, src[RIDX(ii,jj,dim)]);

        assign_sum_to_pixel(&current_pixel, sum);
 
    
 
         


        dst[RIDX(i_4,j_4, dim)] = current_pixel;


        }



    for (int i = 1; i < dim-1; i++){
    for (int j = 1; j < dim-1; j++){


        __m128i pixel_c = _mm_loadu_si128((__m128i*) &src[RIDX(i, j, dim)]);
        __m128i pixel_tl = _mm_loadu_si128((__m128i*) &src[RIDX(i-1, j-1, dim)]);
        __m128i pixel_t = _mm_loadu_si128((__m128i*) &src[RIDX(i-1, j, dim)]);
        __m128i pixel_tr = _mm_loadu_si128((__m128i*) &src[RIDX(i-1, j+1, dim)]);
        __m128i pixel_l = _mm_loadu_si128((__m128i*) &src[RIDX(i, j-1, dim)]);
        __m128i pixel_r = _mm_loadu_si128((__m128i*) &src[RIDX(i, j+1, dim)]);
        __m128i pixel_bl = _mm_loadu_si128((__m128i*) &src[RIDX(i+1, j-1, dim)]);
        __m128i pixel_b = _mm_loadu_si128((__m128i*) &src[RIDX(i+1, j, dim)]);
        __m128i pixel_br = _mm_loadu_si128((__m128i*) &src[RIDX(i+1, j+1, dim)]);




        __m256i pixel_1 = _mm256_cvtepu8_epi16(pixel_tl);
        __m256i pixel_2 = _mm256_cvtepu8_epi16(pixel_t);
        __m256i pixel_3 = _mm256_cvtepu8_epi16(pixel_tr);
        __m256i pixel_4 = _mm256_cvtepu8_epi16(pixel_l);
        __m256i pixel_5 = _mm256_cvtepu8_epi16(pixel_c);
        __m256i pixel_6 = _mm256_cvtepu8_epi16(pixel_r);
        __m256i pixel_7 = _mm256_cvtepu8_epi16(pixel_bl);
        __m256i pixel_8 = _mm256_cvtepu8_epi16(pixel_b);
        __m256i pixel_9 = _mm256_cvtepu8_epi16(pixel_br);

        __m256i first_values = _mm256_add_epi16(pixel_1, pixel_2);
        __m256i second_values = _mm256_add_epi16(pixel_3, pixel_4);
        __m256i third_values = _mm256_add_epi16(pixel_5, pixel_6);
        __m256i fourth_values = _mm256_add_epi16(pixel_7, pixel_8);
        __m256i value1 = _mm256_add_epi16(pixel_9, first_values);
        __m256i value2 = _mm256_add_epi16(second_values, third_values);
        __m256i value3 = _mm256_add_epi16(value1, fourth_values);
        __m256i result = _mm256_add_epi16(value3, value2);

        unsigned short pixel_elements[16];

        _mm256_storeu_si256((__m256i*) pixel_elements, result);

        pixel smooth_pixel; 

        smooth_pixel.red = (pixel_elements[0]* 7282) >> 16;
        smooth_pixel.green = (pixel_elements[1]* 7282) >> 16;
        smooth_pixel.blue = (pixel_elements[2]* 7282) >> 16;
        smooth_pixel.alpha = (pixel_elements[3]* 7282) >> 16;

        dst[RIDX(i,j,dim)] = smooth_pixel;




    }
}


}

/*********************************************************************
 * register_smooth_functions - Register all of your different versions
 *     of the smooth function by calling the add_smooth_function() for
 *     each test function. When you run the benchmark program, it will
 *     test and report the performance of each registered test
 *     function.  
 *********************************************************************/

void register_smooth_functions() {
    add_smooth_function(&naive_smooth, naive_smooth_descr);
    add_smooth_function(&another_smooth_without_avx, another_smooth_descr);
    add_smooth_function(&another_smooth_with_avx, another_smooth_descr_with_avx);
}
