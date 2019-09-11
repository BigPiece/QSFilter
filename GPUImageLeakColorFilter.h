//
//  GPUImageLeakColorFilter.h
//  QSCamera
//
//  Created by qws on 2018/12/13.
//  Copyright © 2018 qws. All rights reserved.
//

#import "GPUImage.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPUImageLeakColorFilter : GPUImageFilter
@property (nonatomic, assign) float iGlobalTime;

@end

NS_ASSUME_NONNULL_END
