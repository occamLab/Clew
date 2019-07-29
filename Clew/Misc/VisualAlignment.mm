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
#import <fstream>


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
+ (VisualAlignmentReturn) visualYaw :(NSString *)dir :(UIImage *)image1 :(simd_float4)intrinsics1 :(simd_float4x4)pose1
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
    Eigen::MatrixX2f vectors1_matrix(matches.size(), 2);
    Eigen::MatrixX2f vectors2_matrix(matches.size(), 2);
    std::ofstream vecfile1(std::string([dir UTF8String]) + "/vectors1.txt");
    std::ofstream vecfile2(std::string([dir UTF8String]) + "/vectors2.txt");
    std::ofstream veceigenfile1(std::string([dir UTF8String]) + "/vectorseigen1.txt");
    std::ofstream veceigenfile2(std::string([dir UTF8String]) + "/vectorseigen2.txt");
    int counter = 0;
    for (const auto& match : matches) {
        const auto keypoint1 = keypoints_and_descriptors1.keypoints[match.queryIdx];
        const auto keypoint2 = keypoints_and_descriptors2.keypoints[match.trainIdx];
        const auto normalized1 = normalizePoint(intrinsics1_matrix, keypoint1.pt);
        const auto normalized2 = normalizePoint(intrinsics2_matrix, keypoint2.pt);
        vectors1.push_back(normalized1);
        vectors2.push_back(normalized2);
        
        vecfile1 << normalized1.x << "\t" << normalized1.y << std::endl;
        vecfile2 << normalized2.x << "\t" << normalized2.y << std::endl;
        vectors1_matrix.row(counter) << normalized1.x, normalized1.y;
        vectors2_matrix.row(counter) << normalized2.x, normalized2.y;
        counter++;
//        vectors1.push_back(keypoint1.pt);
//        vectors2.push_back(keypoint2.pt);
        
    }

    const auto yaw = getYaw(std::string([dir UTF8String]), vectors1, vectors2);
//    debug_square_image1 = MatToUIImage(square_image_mat1);
//    debug_square_image2 = MatToUIImage(square_image_mat2);
    UIImage *debug_match_image_ui = MatToUIImage(debug_match_image);
    NSData *debug_png = UIImagePNGRepresentation(debug_match_image_ui);
    [debug_png writeToFile:[dir stringByAppendingPathComponent:@"correspondence.png"] atomically: YES];
    std::ofstream file(std::string([dir UTF8String]) + "/intrinsics.txt");
//
    veceigenfile1 << vectors1_matrix << std::endl;
    veceigenfile2 << vectors2_matrix << std::endl;

    if (file.is_open()) {
        file << "Intrinsics1" << std::endl << intrinsics1_matrix << std::endl;
        file << "Intrinsics2" << std::endl << intrinsics2_matrix << std::endl;
    }
    file.close();
    vecfile1.close();
    vecfile2.close();
    
//    const Eigen::Matrix3f intrintiscs1_eigen = intrinsicsToMatrix(intrinsics1);
//    const auto matches = getMatches(image1, image2);
//
    VisualAlignmentReturn ret;
    ret.yaw = yaw;
    ret.square_rotation1 = rotationToSIMD((Eigen::Matrix3f) square_rotation1);
    ret.square_rotation2 = rotationToSIMD((Eigen::Matrix3f) square_rotation2);
//    ret.correspondences = debug_match_image_ui;
    return ret;
}

@end
