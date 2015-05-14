////
////  imagecd.h
////  imagecd
////
////  Created by liveaa on 14-5-14.
////  Copyright (c) 2014年 liveaa. All rights reserved.
////
//
//#ifndef imagecd_imagecd_h
//#define imagecd_imagecd_h
//
///*
// * @imgpath: the path to saved the bin value, not include '/' in the tail.
// * @pixelscolor: the one array for the photo file. 
// * @height: the pixels value in the horizontal.
// * @width: the pixels value in the height.
// * @return: the full path after compressed, NULL pointer once exception.
// */
//char* getImagePath(char* imgpath, unsigned char* pixelscolor, int height, int width);
//
///*
// * @imgpath: the full path contained the jpg file format.
// * @return: the blur checked from return value. Pass once greater than 0.7.
// *
// */
//float checkBlur(char* imgpath);
//
//#endif




#ifndef imagecd_imagecd_h
#define imagecd_imagecd_h

/*
 * @imgpath: the path to saved the bin value, not include '/' in the tail.
 * @pixelscolor: the one array for the photo file.
 * @height: the pixels value in the horizontal.
 * @width: the pixels value in the height.
 * @return: the full path after compressed, NULL pointer once exception.
 */
char* getImagePath(char* imgpath, unsigned char* pixelscolor, int height, int width);

#endif