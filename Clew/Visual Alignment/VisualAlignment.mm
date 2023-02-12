//
//  VisualAlignment.m
//  Clew
//
//  Created by Kawin Nikomborirak on 7/9/19.
//  Copyright © 2019 OccamLab. All rights reserved.
//

#include <Eigen/Core>
#include <Eigen/Geometry>
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/features2d.hpp>
#import <opencv2/core/eigen.hpp>
#import "VisualAlignment.h"
#import "VisualAlignmentUtils.hpp"
#import <UIKit/UIKit.h>
#import <fstream>


@implementation VisualAlignment



UIImage *debug_match_image_ui = 0;

+ (nullable UIImage*) getDebugImage {
    return debug_match_image_ui;
}

+ (VisualAlignmentReturn) visualYaw :(UIImage *)image1 :(simd_float4)intrinsics1 :(simd_float4x4)pose1
                    :(UIImage *)image2 :(simd_float4)intrinsics2 :(simd_float4x4)pose2 :(int)downSampleFactor {
    debug_match_image_ui = 0;
    bool useThreePoint = true;
    VisualAlignmentReturn ret;
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
    
    const Eigen::AngleAxisf square_rotation1 = getIdealRotation(pose1_matrix);
    const Eigen::AngleAxisf square_rotation2 = getIdealRotation(pose2_matrix);
    
    ret.square_rotation1 = rotationToSIMD((Eigen::Matrix3f) square_rotation1);
    ret.square_rotation2 = rotationToSIMD((Eigen::Matrix3f) square_rotation2);
    
    const auto square_image_mat1 = warpPerspectiveWithGlobalRotation(image_mat1, intrinsics1_matrix, pose1_matrix.block(0, 0, 3, 3), square_rotation1);
    const auto square_image_mat2 = warpPerspectiveWithGlobalRotation(image_mat2, intrinsics2_matrix, pose2_matrix.block(0, 0, 3, 3), square_rotation2);
    cv::Mat square_image_mat1_resized, square_image_mat2_resized;
    cv::resize(square_image_mat1, square_image_mat1_resized, cv::Size(square_image_mat1.size().width/downSampleFactor, square_image_mat1.size().height/downSampleFactor));
    cv::resize(square_image_mat2, square_image_mat2_resized, cv::Size(square_image_mat2.size().width/downSampleFactor, square_image_mat2.size().height/downSampleFactor));
    
    const auto keypoints_and_descriptors1 = getKeyPointsAndDescriptors(square_image_mat1_resized);
    const auto keypoints_and_descriptors2 = getKeyPointsAndDescriptors(square_image_mat2_resized);

    const auto matches = getMatches(keypoints_and_descriptors1.descriptors, keypoints_and_descriptors2.descriptors);
    
    
    std::vector<cv::Point2f> vectors1, vectors2;
    
    for (const auto& match : matches) {
        const auto keypoint1 = keypoints_and_descriptors1.keypoints[match.queryIdx];
        const auto keypoint2 = keypoints_and_descriptors2.keypoints[match.trainIdx];
        // correct for the downsampling
        vectors1.push_back(downSampleFactor*keypoint1.pt);
        
        // Convert the second keypoint to one with the intrinsics of the first camera.
        Eigen::Vector3f keypoint2vec;
        keypoint2vec << downSampleFactor*keypoint2.pt.x, downSampleFactor*keypoint2.pt.y, 1;
        Eigen::Vector3f keypoint2projected = intrinsics1_matrix * intrinsics2_matrix.inverse() * keypoint2vec;
        vectors2.push_back(cv::Point2f(keypoint2projected(0), keypoint2projected(1)));
    }

    if (useThreePoint) {
        ret.numMatches = matches.size();
        if (matches.size() < 6) {
            ret.is_valid = false;
            ret.yaw = 0;
            return ret;
        }
        std::vector<Eigen::Vector3d> all_rays_image_1, all_rays_image_2;

        for (unsigned int i = 0; i < matches.size(); i++) {
            const auto& match = matches[i];
            const auto keypoint1 = keypoints_and_descriptors1.keypoints[match.queryIdx];
            const auto keypoint2 = keypoints_and_descriptors2.keypoints[match.trainIdx];
            // correct for the downsampling
            Eigen::Vector3f homogeneousKp1(downSampleFactor*keypoint1.pt.x, downSampleFactor*keypoint1.pt.y, 1.0);
            Eigen::Vector3f image_1_ray = intrinsics1_matrix.inverse() * homogeneousKp1;
            all_rays_image_1.push_back(Eigen::Vector3d(image_1_ray.x(), image_1_ray.y(), image_1_ray.z()));
            Eigen::Vector3f homogeneousKp2(downSampleFactor*keypoint2.pt.x, downSampleFactor*keypoint2.pt.y, 1.0);
            Eigen::Vector3f image_2_ray = intrinsics2_matrix.inverse() * homogeneousKp2;
            all_rays_image_2.push_back(Eigen::Vector3d(image_2_ray.x(), image_2_ray.y(), image_2_ray.z()));
        }
        
        // We'll do RANSAC to find the best three points
        Eigen::Matrix3d bestEssential;
        int bestInlierCount = -1;
        double bestInlierResidualSum = -1;

        // to allow us to randomize for RANSAC
        unsigned int* indices = new unsigned int[matches.size()];
        for (unsigned int i = 0; i < matches.size(); i++) {
            indices[i] = i;
        }
        std::map<int, std::vector<float> > centiradQuantization;
        std::map<int, std::vector<cv::Mat> > centiradQuantizationTranslations;

        for (unsigned int trial = 0; trial < 100; trial++) {
            std::random_shuffle(indices, indices+matches.size());
            std::vector<cv::Point2f> vectors1_ransac, vectors2_ransac;
            Eigen::Vector3d rotation_axis = Eigen::Vector3d(0, 1, 0);
            Eigen::Vector3d image_1_rays[3];
            Eigen::Vector3d image_2_rays[3];
            std::vector<Eigen::Quaterniond> soln_rotations;
            std::vector<Eigen::Vector3d> soln_translations;
            for (unsigned int i = 0; i < 3; i++) {
                const auto& match = matches[indices[i]];
                const auto keypoint1 = keypoints_and_descriptors1.keypoints[match.queryIdx];
                const auto keypoint2 = keypoints_and_descriptors2.keypoints[match.trainIdx];
                // correct for the downsampling
                Eigen::Vector3f homogeneousKp1(downSampleFactor*keypoint1.pt.x, downSampleFactor*keypoint1.pt.y, 1.0);
                Eigen::Vector3f image_1_ray = intrinsics1_matrix.inverse() * homogeneousKp1;
                image_1_rays[i] = Eigen::Vector3d(image_1_ray.x(), image_1_ray.y(), image_1_ray.z());
                Eigen::Vector3f homogeneousKp2(downSampleFactor*keypoint2.pt.x, downSampleFactor*keypoint2.pt.y, 1.0);
                Eigen::Vector3f image_2_ray = intrinsics2_matrix.inverse() * homogeneousKp2;
                image_2_rays[i] = Eigen::Vector3d(image_2_ray.x(), image_2_ray.y(), image_2_ray.z());
                vectors1_ransac.push_back(vectors1[indices[i]]);
                vectors2_ransac.push_back(vectors2[indices[i]]);
            }

            theia::ThreePointRelativePosePartialRotation(rotation_axis,
                                                  image_1_rays,
                                                  image_2_rays,
                                                  &soln_rotations,
                                                  &soln_translations);
            for (unsigned int i = 0; i < soln_rotations.size(); i++) {
                const Eigen::Matrix3d relative_rotation = soln_rotations[i].toRotationMatrix();
                Eigen::Matrix3d essential_matrix = CrossProductMatrix(soln_translations[i]) * relative_rotation;
                essential_matrix.normalize();
                int totalInliers = 0;
                double inlierResidualSum = 0.0;
                for (unsigned int j = 0; j < all_rays_image_1.size(); j++) {
                    double pointResidual = abs(all_rays_image_2[j].transpose() * essential_matrix * all_rays_image_1[j]);
                    if (pointResidual < 0.001) { // TODO: this threshold is not correct, we need to figure out how to make this into something consistent (e.g., distance in pixels to epipolar line)
                        totalInliers++;
                        inlierResidualSum += pointResidual;
                    }
                }
                
                // TODO this needs to be tuned in a smarter way (e.g., by running some iterations of RANSAC first and then adapting the threshold as a proportion of the best inlier count
                if (totalInliers > 0.5*all_rays_image_1.size()) {
                    // compute pose for averaging purposes
                    cv::Mat essential_matrixCV;
                    eigen2cv(essential_matrix, essential_matrixCV);
                    cv::Mat dcm_mat, translation_mat;

                    int numInliers = cv::recoverPose(essential_matrixCV, vectors1_ransac, vectors2_ransac, dcm_mat, translation_mat, intrinsics1_matrix(0, 0), cv::Point2f(intrinsics1_matrix(0, 2), intrinsics1_matrix(1, 2)));
                    if (numInliers < 3) {
                        // one of the correspondences is behind the camera
                        continue;
                    }
                    Eigen::Matrix3f dcm;
                    cv2eigen(dcm_mat, dcm);
                    const auto rotated = dcm * Eigen::Vector3f::UnitZ();
                    float yaw = atan2(rotated(0), rotated(2));
                    int quantized = (int) (yaw*100);
                    if (centiradQuantization.find(quantized) == centiradQuantization.end()) {
                        centiradQuantization[quantized] = std::vector<float>();
                        centiradQuantizationTranslations[quantized] = std::vector<cv::Mat>();
                    }
                    centiradQuantization[quantized].push_back(yaw);
                    centiradQuantizationTranslations[quantized].push_back(translation_mat);
                }
                if (bestInlierCount < 0 || totalInliers > bestInlierCount || (totalInliers == bestInlierCount && inlierResidualSum < bestInlierResidualSum)) {
                    bestInlierCount = totalInliers;
                    bestEssential = essential_matrix;
                    bestInlierResidualSum = inlierResidualSum;
                }
            }
        }
        
        float bestConsensusYaw = 0.0;
        cv::Mat bestConsensusTranslation = cv::Mat(3,1, CV_64F, 0.0);
        unsigned long mostQuantized = 0;
        for (std::map<int, std::vector<float> >::iterator i = centiradQuantization.begin(); i != centiradQuantization.end(); ++i) {
            if (i->second.size() > mostQuantized) {
                mostQuantized = i->second.size();
                bestConsensusYaw = 0.0;
                // take the average of all elements in the bucket
                for (std::vector<float>::iterator j = i->second.begin(); j != i->second.end(); ++j) {
                    bestConsensusYaw += *j / mostQuantized;
                }
                bestConsensusTranslation = cv::Mat(3,1, CV_64F, 0.0);
                for (unsigned long j = 0; j < centiradQuantizationTranslations[i->first].size(); j++) {
                    bestConsensusTranslation += centiradQuantizationTranslations[i->first][j];
                }
                bestConsensusTranslation = bestConsensusTranslation / cv::norm(bestConsensusTranslation);
            }
            
        }
        
        cv::Mat debug_match_image;
        cv::drawMatches(square_image_mat1_resized, keypoints_and_descriptors1.keypoints, square_image_mat2_resized, keypoints_and_descriptors2.keypoints, matches, debug_match_image);
        debug_match_image_ui = MatToUIImage(debug_match_image);
        cv::Mat bestEssentialCV;
        eigen2cv(bestEssential, bestEssentialCV);
        cv::Mat dcm_mat, translation_mat;

        int numInliers = cv::recoverPose(bestEssentialCV, vectors1, vectors2, dcm_mat, translation_mat, intrinsics1_matrix(0, 0), cv::Point2f(intrinsics1_matrix(0, 2), intrinsics1_matrix(1, 2)));
        Eigen::Matrix3f dcm;
        cv2eigen(dcm_mat, dcm);
        const auto rotated = dcm * Eigen::Vector3f::UnitZ();
        const float yaw = atan2(rotated(0), rotated(2));
        float residualAngle = abs(yaw) - acos((dcm.trace() - 1)/2);
        ret.yaw = mostQuantized > 0 ? bestConsensusYaw : yaw;
        ret.residualAngle = residualAngle;
        ret.tx = mostQuantized > 0 ? bestConsensusTranslation.at<double>(0, 0) : translation_mat.at<double>(0, 0);
        ret.ty = mostQuantized > 0 ? bestConsensusTranslation.at<double>(0, 1) : translation_mat.at<double>(0, 1);
        ret.tz = mostQuantized > 0 ? bestConsensusTranslation.at<double>(0, 2) : translation_mat.at<double>(0, 2);
        ret.is_valid = numInliers >= 6;
        ret.numInliers = numInliers;
        delete[] indices;
        return ret;
    } else {
        ret.numMatches = vectors1.size();
        if (matches.size() < 10) {
            ret.is_valid = false;
            ret.yaw = 0;
            return ret;
        }
        ret.is_valid = true;
        const auto yaw = getYaw(vectors1, vectors2, intrinsics1_matrix, ret.numInliers, ret.residualAngle, ret.tx, ret.ty, ret.tz);

        ret.yaw = yaw;
        std::cout << "ret.yaw " << ret.yaw << std::endl;
        return ret;
    }
}

+ (int) numFeatures :(UIImage *)image {
    cv::Mat mat;
    UIImageToMat(image, mat);
    cv::cvtColor(mat, mat, cv::COLOR_RGB2GRAY);
    const auto keypoints_and_descriptors = getKeyPointsAndDescriptors(mat);
    return keypoints_and_descriptors.keypoints.size();
}

+ (int) numMatches :(UIImage *)image1 :(UIImage *)image2 {
    cv::Mat mat1, mat2;
    UIImageToMat(image1, mat1);
    UIImageToMat(image2, mat2);
    cv::cvtColor(mat1, mat1, cv::COLOR_RGB2GRAY);
    cv::cvtColor(mat2, mat2, cv::COLOR_RGB2GRAY);
    const auto keypoints_and_descriptors1 = getKeyPointsAndDescriptors(mat1);
    const auto keypoints_and_descriptors2 = getKeyPointsAndDescriptors(mat2);
    
    const auto matches = getMatches(keypoints_and_descriptors1.descriptors, keypoints_and_descriptors2.descriptors);
    return matches.size();
}

@end
