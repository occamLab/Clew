//
//  NSObject+ARFrameStatusAdapter.h
//  Clew
//
//  Created by Paul Ruvolo on 7/22/22.
//  Copyright © 2022 OccamLab. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ARKit/ARKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ARFrameStatusAdapter : NSObject

+(void)adjustTrackingStatus:(ARFrame *)frame;

@end

NS_ASSUME_NONNULL_END
