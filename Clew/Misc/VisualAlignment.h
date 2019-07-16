//
//  VisualAlignment.h
//  Clew
//
//  Created by Kawin Nikomborirak on 7/9/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#import <opencv2/opencv.hpp>

NS_ASSUME_NONNULL_BEGIN

@interface VisualAlignment : NSObject
+ (float) visualYaw :(UIImage *)base_image :(float)base_focal_length :(float)base_ppx :(float)base_ppy
                          :(UIImage *)new_image :(float)new_focal_length :(float)new_ppx :(float)new_ppy;
@end

NS_ASSUME_NONNULL_END
