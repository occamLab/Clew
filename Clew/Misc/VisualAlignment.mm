//
//  VisualAlignment.mm
//  Clew
//
//  Created by Kawin Nikomborirak on 7/9/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

#import "VisualAlignment.h"
#import "VisualAlignmentUtils.hpp"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/features2d.hpp>
#import <opencv2/core/eigen.hpp>
#import <Eigen/Core>
#import <Eigen/Geometry>
#import <UIKit/UIKit.h>


@implementation VisualAlignment

/**
 Deduce the yaw between two images.
 
 - returns: The yaw in radians between the pictures assuming portrait orientation.
 
 - parameters:
    - image1: The image the returned yaw is relative to.
    - intrinsics1: The camera intrinsics used to take image1 in the format [fx, fy, ppx, ppy].
    - pose1: The pose of the camera in the arsession used to take the first image.
    - image2: The image the returned yaw rotates to.
    - intrinsics2: The camera intrinsics used to take image2 in the format [fx, fy, ppx, ppy].
    - pose2: The pose of the camera in the arsession used to take the second image.
 */
+ (VisualAlignmentReturn) visualYaw :(UIImage *)image1 :(simd_float4)intrinsics1 :(simd_float4x4)pose1
                    :(UIImage *)image2 :(simd_float4)intrinsics2 :(simd_float4x4)pose2 {
    
    // Convert the UIImages to cv::Mats and rotate them.
    cv::Mat image_mat1, image_mat2;
    UIImageToMat(image1, image_mat1);
    UIImageToMat(image2, image_mat2);

    cv::cvtColor(image_mat1, image_mat1, cv::COLOR_RGB2GRAY);
    cv::rotate(image_mat1, image_mat1, cv::ROTATE_90_CLOCKWISE);
    cv::cvtColor(image_mat2, image_mat2, cv::COLOR_RGB2GRAY);
    cv::rotate(image_mat2, image_mat2, cv::ROTATE_90_CLOCKWISE);
    
    Eigen::Matrix3f intrinsics1_matrix_unrotated = intrinsicsToMatrix(intrinsics1);
    Eigen::Matrix3f intrinsics2_matrix_unrotated = intrinsicsToMatrix(intrinsics2);
    
    // Since the image was rotated clockwise, we have to swap entries in the intrinsic matrices as well.
    // I use matrix multiplication for this.
    Eigen::Matrix3f swap_matrix;
    swap_matrix << 0, 1, 0, 1, 0, 0, 0, 0, 1;
    
    Eigen::Matrix3f intrinsics1_matrix = swap_matrix * intrinsics1_matrix_unrotated * swap_matrix;
    Eigen::Matrix3f intrinsics2_matrix = swap_matrix * intrinsics2_matrix_unrotated * swap_matrix;
    
    intrinsics1_matrix(0, 2) = image_mat1.cols - intrinsics1_matrix(0, 2);
    intrinsics2_matrix(0, 2) = image_mat2.cols - intrinsics2_matrix(0, 2);
    
    const Eigen::Matrix4f pose1_matrix = poseToMatrix(pose1);
    const Eigen::Matrix4f pose2_matrix = poseToMatrix(pose2);
    
    const Eigen::AngleAxisf square_rotation1 = squareImageRotation(pose1_matrix);
    const Eigen::AngleAxisf square_rotation2 = squareImageRotation(pose2_matrix);
    Eigen::Matrix3f test1 = (Eigen::Matrix3f) square_rotation1;
    Eigen::Matrix3f test2 = (Eigen::Matrix3f) square_rotation2;
    
    const auto square_image_mat1 = squareImageGlobalRotation(image_mat1, intrinsics1_matrix, pose1_matrix.block(0, 0, 3, 3), square_rotation1);
    const auto square_image_mat2 = squareImageGlobalRotation(image_mat2, intrinsics2_matrix, pose2_matrix.block(0, 0, 3, 3), square_rotation2);

    auto debug_square_image1 = MatToUIImage(square_image_mat1);
    auto debug_square_image2 = MatToUIImage(square_image_mat2);
//    auto debug_square_image1 = MatToUIImage(square_image_mat1);
//    auto debug_square_image2 = MatToUIImage(square_image_mat2);

    const auto keypoints_and_descriptors1 = getKeyPointsAndDescriptors(square_image_mat1);
    const auto keypoints_and_descriptors2 = getKeyPointsAndDescriptors(square_image_mat2);

    const auto matches = getMatches(keypoints_and_descriptors1.descriptors, keypoints_and_descriptors2.descriptors);

    cv::Mat debug_match_image;
    cv::drawMatches(square_image_mat1, keypoints_and_descriptors1.keypoints, square_image_mat2, keypoints_and_descriptors2.keypoints, matches, debug_match_image);
    std::vector<cv::Point2f> vectors1, vectors2;


    cv::Point2f temp_vector;
    for (const auto& match : matches) {
        const auto keypoint1 = keypoints_and_descriptors1.keypoints[match.queryIdx];
        const auto keypoint2 = keypoints_and_descriptors2.keypoints[match.trainIdx];
//        vectors1.push_back(cv::Point2f((keypoint1.pt.x - intrinsics1_matrix(0, 2)) / intrinsics1_matrix(0, 0),
//                                               (keypoint1.pt.y - intrinsics1_matrix(1, 2)) / intrinsics1_matrix(1, 1)));
//        vectors2.push_back(cv::Point2f((keypoint2.pt.x - intrinsics2_matrix(0, 2)) / intrinsics2_matrix(0, 0),
//                                       (keypoint2.pt.y - intrinsics2_matrix(1, 2)) / intrinsics2_matrix(1, 1)));
        vectors1.push_back(keypoint1.pt);
        vectors2.push_back(keypoint2.pt);
    }

    const auto yaw = getYaw(vectors1, vectors2);
    debug_square_image1 = MatToUIImage(square_image_mat1);
    debug_square_image2 = MatToUIImage(square_image_mat2);
    auto debug_match_image_ui = MatToUIImage(debug_match_image);
//    const Eigen::Matrix3f intrintiscs1_eigen = intrinsicsToMatrix(intrinsics1);
//    const auto matches = getMatches(image1, image2);
//
    VisualAlignmentReturn ret;
    ret.yaw = yaw;
    ret.square_rotation1 = rotationToSIMD((Eigen::Matrix3f) square_rotation1);
    ret.square_rotation2 = rotationToSIMD((Eigen::Matrix3f) square_rotation2);
    return ret;
}

@end
