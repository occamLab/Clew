//
//  VisualAlignment.h
//  Clew
//
//  Created by Kawin Nikomborirak on 7/9/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface VisualAlignment : NSObject
+ (UIImage *)visualAlignmentImage :(UIImage *)base_image;
+ (NSString *)openCVVersionString;

@end

NS_ASSUME_NONNULL_END
