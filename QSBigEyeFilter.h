//
//  QSBigEyeFilter.h
//  QSCamera
//
//  Created by qws on 2019/3/21.
//  Copyright © 2019 qws. All rights reserved.
//

#import "GPUImageFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface QSBigEyeFilter : GPUImageFilter
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) CGFloat scaleRatio;
@property (nonatomic, assign) CGPoint leftEyeCenterPosition;
@property (nonatomic, assign) CGPoint rightEyeCenterPosition;

@end

NS_ASSUME_NONNULL_END
