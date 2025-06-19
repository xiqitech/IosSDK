//
//  HTPhotoPickerManager.h
//  HiTalk
//
//  Created by Xiang He on 2025/3/7.
//  Copyright © 2025 zhenai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^HTPhotoPickerImagePickerCompletionBlock)(UIImage * _Nullable image, NSDictionary * _Nullable info);
typedef void(^HTPhotoPickerCancelBlock)(void);
typedef void(^HTPhotoPickerPhotosCompletionBlock)(NSArray<UIImage *> * _Nullable images, NSArray * _Nullable assets);
typedef void(^HTPhotoPickerErrorBlock)(NSError * _Nullable error);

@interface HTPhotoPickerManager : NSObject

+ (instancetype)sharedManager;

#pragma mark - UIImagePickerController 相关方法

/**
 * 使用 UIImagePickerController 从相机拍照
 * @param viewController 用于展示相机的视图控制器
 * @param allowsEditing 是否允许编辑
 * @param completion 完成回调
 * @param cancel 取消回调
 */
- (void)takePhotoFromViewController:(UIViewController *)viewController
                      allowsEditing:(BOOL)allowsEditing
                         completion:(HTPhotoPickerImagePickerCompletionBlock)completion
                            cancel:(HTPhotoPickerCancelBlock)cancel;

/**
 * 使用 UIImagePickerController 从相册选择图片
 * @param viewController 用于展示相册的视图控制器
 * @param allowsEditing 是否允许编辑
 * @param completion 完成回调
 * @param cancel 取消回调
 */
- (void)pickPhotoFromViewController:(UIViewController *)viewController
                      allowsEditing:(BOOL)allowsEditing
                         completion:(HTPhotoPickerImagePickerCompletionBlock)completion
                            cancel:(HTPhotoPickerCancelBlock)cancel;

#pragma mark - PHPickerViewController 相关方法 (iOS 14+)

/**
 * 使用 PHPickerViewController 从相册选择单张图片
 * @param viewController 用于展示相册的视图控制器
 * @param completion 完成回调
 * @param cancel 取消回调
 * @param error 错误回调
 */
- (void)pickSinglePhotoWithPHPickerFromViewController:(UIViewController *)viewController
                                          completion:(HTPhotoPickerPhotosCompletionBlock)completion
                                             cancel:(_Nullable HTPhotoPickerCancelBlock)cancel
                                              error:(_Nullable HTPhotoPickerErrorBlock)error API_AVAILABLE(ios(14));

/**
 * 使用 PHPickerViewController 从相册选择多张图片
 * @param viewController 用于展示相册的视图控制器
 * @param maxSelectionCount 最大选择数量
 * @param completion 完成回调
 * @param cancel 取消回调
 * @param error 错误回调
 */
- (void)pickMultiplePhotosWithPHPickerFromViewController:(UIViewController *_Nullable)viewController
                                      maxSelectionCount:(NSInteger)maxSelectionCount
                                            completion:(HTPhotoPickerPhotosCompletionBlock)completion
                                               cancel:(HTPhotoPickerCancelBlock)cancel
                                                error:(HTPhotoPickerErrorBlock)error API_AVAILABLE(ios(14));

@end

NS_ASSUME_NONNULL_END 
