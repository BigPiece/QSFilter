//
//  QSThinFaceFilter.h
//  QSCamera
//
//  Created by qws on 2019/3/19.
//  Copyright © 2019 qws. All rights reserved.
//

#import "GPUImageFilter.h"

NS_ASSUME_NONNULL_BEGIN

@interface QSThinFaceFilter : GPUImageFilter
@property (nonatomic, assign) CGFloat strength;
@property (nonatomic, strong) NSArray<NSValue *> *landMarks;
@end

NS_ASSUME_NONNULL_END
