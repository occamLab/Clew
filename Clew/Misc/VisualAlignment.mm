//
//  VisualAlignment.mm
//  Clew
//
//  Created by Kawin Nikomborirak on 7/9/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

#import "VisualAlignment.h"
#import <opencv2/opencv.hpp>

@implementation VisualAlignment

+ (void) computeRotation :(cv::Mat)base_image :(cv::Mat) new_image {
    
    auto detector = cv::ORB::create();
    std::vector<cv::KeyPoint> keypoints1, keypoints2;
    cv::Mat descriptors1, descriptors2;
    detector->detectAndCompute(base_image, cv::Mat(), keypoints1, descriptors1);
    detector->detectAndCompute(new_image, cv::Mat(), keypoints1, descriptors1);
    
    std::vector<cv::DMatch> matches;
    auto matcher = cv::DescriptorMatcher::create("BruteForce-Hamming");
    matcher->match(descriptors1, descriptors2, matches);
}


+ (NSString *)openCVVersionString {
    
    return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
    
}

@end
