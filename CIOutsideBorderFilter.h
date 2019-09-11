//
//  CIOutsideOBorderFilter.h
//  Taker
//
//  Created by qws on 2018/5/24.
//  Copyright © 2018年 com.pepsin.fork.video_taker. All rights reserved.
//

#import <CoreImage/CoreImage.h>

#define Shader_stringize(str) @#str

@interface CIOutsideBorderFilter : CIFilter
@property (nonatomic, strong) CIImage *inputImage;          //原图
@property (nonatomic, assign) CVPixelBufferRef outputDepthMap;
@property (nonatomic, strong) CIVector *inputFocusPoint; //normalize
@property (nonatomic, strong) CIVector *inputBorderEdge; //非归一化，top left bototm right

@end
