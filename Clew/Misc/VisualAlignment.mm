//
//  VisualAlignment.mm
//  Clew
//
//  Created by Kawin Nikomborirak on 7/9/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

#import "VisualAlignment.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/features2d.hpp>
#import <opencv2/core/eigen.hpp>
#import <Eigen/Core>
#import <UIKit/UIKit.h>


@implementation VisualAlignment

/**
 Deduce the yaw between two images.
 
 - returns: The yaw in radians between the pictures assuming portrait orientation.
 
 - parameters:
    - base_image: The image the returned yaw is relative to.
    - base_focal_length: The focal length of the camera used to take the base image.
    - base_ppx: The x coordinate of the base image's principle point.
    - base_ppy: The y coordinate of the base image's principle point.
     - new_image: The image the returned yaw rotates to.
     - new_focal_length: The focal length of the camera used to take the new image.
     - new_ppx: The x coordinate of the new image's principle point.
     - new_ppy: The y coordinate of the new image's principle point.
 */
+ (float) visualYaw :(UIImage *)base_image :(float)base_focal_length :(float)base_ppx :(float)base_ppy
                                   :(UIImage *)new_image :(float)new_focal_length :(float)new_ppx :(float)new_ppy {
    
    // Convert the UIImages to cv::Mats
    cv::Mat base_mat, new_mat;
    UIImageToMat(base_image, base_mat);
    UIImageToMat(new_image, new_mat);
    cv::cvtColor(base_mat, base_mat, cv::COLOR_RGB2GRAY);
    cv::cvtColor(new_mat, new_mat, cv::COLOR_RGB2GRAY);
    
    // Get feature matches
    const float ratio = 0.6;
    auto feature_descriptor = cv::AKAZE::create();
    std::vector<cv::KeyPoint> base_keypoints, new_keypoints;
    cv::Mat base_descriptors, new_descriptors;
    
    feature_descriptor->detectAndCompute(base_mat, cv::Mat(), base_keypoints, base_descriptors);
    feature_descriptor->detectAndCompute(new_mat, cv::Mat(), new_keypoints, new_descriptors);
    
    auto matcher = cv::BFMatcher();
    std::vector<std::vector<cv::DMatch>> matches;
    std::vector<cv::DMatch> good_matches;
    
    matcher.knnMatch(base_descriptors, new_descriptors, matches, 2);
    
    for (const auto& match : matches)
        if (match[0].distance < ratio * match[1].distance)
            good_matches.push_back(match[0]);
    
    
    
    cv::Mat match_img;
    cv::drawMatches(base_mat, base_keypoints, new_mat, new_keypoints, good_matches, match_img);
    
    // The following image is for use with the debugger to visualize the found matches.
    auto matchImage = MatToUIImage(match_img);
    
    // Order the matched points and turn them into vectors with z = 1
    std::vector<cv::Point2f> base_key_vectors, new_key_vectors;
    cv::Point2f temp_vector;
    for (const auto& match : good_matches) {
        const auto base_keypoint = base_keypoints[match.queryIdx];
        const auto new_keypoint = new_keypoints[match.trainIdx];
        base_key_vectors.push_back(cv::Point2f((base_keypoint.pt.x - base_ppx) / base_focal_length,
                                               (base_keypoint.pt.y - base_ppy) / base_focal_length));
        new_key_vectors.push_back(cv::Point2f((new_keypoint.pt.x - new_ppx) / new_focal_length,
                                              (new_keypoint.pt.y - new_ppy) / new_focal_length));
    }
    
    const auto essential_mat = cv::findEssentialMat(base_key_vectors, new_key_vectors);
    
    cv::Mat dcm_mat, translation_mat;
    cv::recoverPose(essential_mat, base_key_vectors, new_key_vectors, dcm_mat, translation_mat);
    
    // Get the relative yaw between the two images.
    // Since the image is taken in portrait mode, yaw is actually a rotation around the x axis.
    Eigen::Matrix3f dcm;

    cv2eigen(dcm_mat, dcm);
    // Usually dcm.eulerAngles(0, 1, 2) would get the euler angles.
    // However, eulerAngles is not available for the architecture so rotating a unit vector is done instead.
    const auto rotated = dcm * Eigen::Vector3f::UnitY();

    const auto yaw = atan2(rotated(2), rotated(1));

    return yaw;
}

@end
