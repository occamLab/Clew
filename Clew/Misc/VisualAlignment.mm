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

+ (void) computeRotation :(cv::Mat)base_image :(cv::Mat) new_image :(double) focal_length :(cv::Point2d) principle_point {
    
    auto detector = cv::AKAZE::create();
    std::vector<cv::KeyPoint> keypoints1, keypoints2;
    cv::Mat descriptors1, descriptors2;
    detector->detectAndCompute(base_image, cv::Mat(), keypoints1, descriptors1);
    detector->detectAndCompute(new_image, cv::Mat(), keypoints1, descriptors1);
    
    std::vector<cv::DMatch> matches;
    auto matcher = new cv::BFMatcher(cv::NORM_HAMMING, true);
    matcher->match(descriptors1, descriptors2, matches);
    
    std::vector<cv::Point2d> selected_points1, selected_points2;
    
    for (int i = 0; i < matches.size(); i++) {
        selected_points1.push_back(keypoints1[matches[i].queryIdx].pt);
        selected_points2.push_back(keypoints2[matches[i].queryIdx].pt);
    }
    
    auto essential_mat = cv::findEssentialMat(selected_points1, selected_points2, focal_length, principle_point, cv::RANSAC, 0.999, 1, cv::Mat());
    
    cv::Mat rotation, translation;
    
    cv::recoverPose(essential_mat, selected_points1, selected_points2, rotation, translation, focal_length, principle_point, cv::Mat());
}


+ (NSString *)openCVVersionString {
    
    return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
    
}

@end
