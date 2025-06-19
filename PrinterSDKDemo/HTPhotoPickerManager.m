//
//  HTPhotoPickerManager.m
//  HiTalk
//
//  Created by Xiang He on 2025/3/7.
//  Copyright © 2025 zhenai. All rights reserved.
//

#import "HTPhotoPickerManager.h"
#import <PhotosUI/PhotosUI.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>

@interface HTPhotoPickerManager () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate>

@property (nonatomic, copy) HTPhotoPickerImagePickerCompletionBlock ipCompletionBlock;
@property (nonatomic, copy) HTPhotoPickerCancelBlock cancelBlock;
@property (nonatomic, copy) HTPhotoPickerPhotosCompletionBlock photoCompletionBlock;
@property (nonatomic, copy) HTPhotoPickerErrorBlock errorBlock;

@end

@implementation HTPhotoPickerManager

#pragma mark - Singleton

+ (instancetype)sharedManager {
    static HTPhotoPickerManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HTPhotoPickerManager alloc] init];
    });
    return instance;
}

#pragma mark - UIImagePickerController Methods

- (void)takePhotoFromViewController:(UIViewController *)viewController
                      allowsEditing:(BOOL)allowsEditing
                         completion:(HTPhotoPickerImagePickerCompletionBlock)completion
                            cancel:(HTPhotoPickerCancelBlock)cancel {
    
    // 检查相机权限
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        if (authStatus == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {//相机权限
                if (granted) {
                    NSLog(@"相机权限 Authorized");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera
                                                viewController:viewController
                                                 allowsEditing:allowsEditing
                                                    completion:completion
                                                        cancel:cancel];
                    });
                } else {
                    NSLog(@"相机权限 Denied or Restricted");
                    
                }
            }];
        } else if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
            
        } else{
            
        }
    }
}

- (void)pickPhotoFromViewController:(UIViewController *)viewController
                      allowsEditing:(BOOL)allowsEditing
                         completion:(HTPhotoPickerImagePickerCompletionBlock)completion
                            cancel:(HTPhotoPickerCancelBlock)cancel {
    
    // 检查相册权限
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if (status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary
                                            viewController:viewController
                                             allowsEditing:allowsEditing
                                               completion:completion
                                                  cancel:cancel];
                });
            }
        }];
    }else if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
        
    } else {

    }
}

- (void)presentImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                          viewController:(UIViewController *)viewController
                           allowsEditing:(BOOL)allowsEditing
                             completion:(HTPhotoPickerImagePickerCompletionBlock)completion
                                cancel:(HTPhotoPickerCancelBlock)cancel {
    
    // 保存回调
    self.ipCompletionBlock = completion;
    self.cancelBlock = cancel;
    
    // 检查是否支持该类型的图片选择器
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        if (self.errorBlock) {
            NSError *error = [NSError errorWithDomain:@"HTPhotoPickerErrorDomain"
                                                 code:100
                                             userInfo:@{NSLocalizedDescriptionKey: @"设备不支持该图片源类型"}];
            self.errorBlock(error);
        }
        return;
    }
    
    // 创建图片选择器
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.allowsEditing = allowsEditing;
    picker.delegate = self;
    
    // 设置媒体类型为图片
    picker.mediaTypes = @[(NSString *)kUTTypeImage];
    
    // 显示图片选择器
    [viewController presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    
    // 获取选择的图片
    UIImage *selectedImage = nil;
    
    if (picker.allowsEditing) {
        selectedImage = info[UIImagePickerControllerEditedImage];
    } else {
        selectedImage = info[UIImagePickerControllerOriginalImage];
    }
    
//    if (selectedImage.size.width > self.compressMinLength) {
//        image = [self compressImage:image newWidth:self.compressMinLength];
//    }
//    //恢复默认值
//    self.compressMinLength = kFRCameraUtilsDefaultCompressMinLength;
//    //压缩图片文件大小
//    selectedImage = [self reduceImage:image percent:0.8];
    
    // 关闭选择器
    [picker dismissViewControllerAnimated:YES completion:^{
        // 调用完成回调
        if (self.ipCompletionBlock) {
            self.ipCompletionBlock(selectedImage, info);
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // 关闭选择器
    [picker dismissViewControllerAnimated:YES completion:^{
        // 调用取消回调
        if (self.cancelBlock) {
            self.cancelBlock();
        }
    }];
}

#pragma mark - PHPickerViewController Methods (iOS 14+)

- (void)pickSinglePhotoWithPHPickerFromViewController:(UIViewController *)viewController
                                          completion:(HTPhotoPickerPhotosCompletionBlock)completion
                                             cancel:(HTPhotoPickerCancelBlock)cancel
                                              error:(HTPhotoPickerErrorBlock)error API_AVAILABLE(ios(14)) {
    
    // 保存回调
    self.photoCompletionBlock = completion;
    self.cancelBlock = cancel;
    self.errorBlock = error;
    
    // 创建配置
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = 1; // 限制选择1张图片
    config.filter = [PHPickerFilter imagesFilter]; // 只显示图片
    
    // 创建选择器
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    
    // 显示选择器
    [viewController presentViewController:picker animated:YES completion:nil];
}

- (void)pickMultiplePhotosWithPHPickerFromViewController:(UIViewController *_Nullable)viewController
                                      maxSelectionCount:(NSInteger)maxSelectionCount
                                            completion:(HTPhotoPickerPhotosCompletionBlock)completion
                                               cancel:(HTPhotoPickerCancelBlock)cancel
                                                error:(HTPhotoPickerErrorBlock)error API_AVAILABLE(ios(14)) {
    
    // 保存回调
    self.photoCompletionBlock = completion;
    self.cancelBlock = cancel;
    self.errorBlock = error;
    
    // 创建配置
    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.selectionLimit = maxSelectionCount; // 限制选择数量
    config.filter = [PHPickerFilter imagesFilter]; // 只显示图片
    
    // 创建选择器
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    
    // 显示选择器
    UIViewController *vc = viewController;
    [vc presentViewController:picker animated:YES completion:nil];
}

#pragma mark - PHPickerViewControllerDelegate

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14)) {
    
    // 关闭选择器
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    // 用户取消选择
    if (results.count == 0) {
        if (self.cancelBlock) {
            self.cancelBlock();
        }
        return;
    }
    
    // 单张图片选择
    if (results.count == 1 && self.photoCompletionBlock) {
        PHPickerResult *result = results.firstObject;
        
        if ([result.itemProvider canLoadObjectOfClass:[UIImage class]]) {
            [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
                
                if (error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.errorBlock) {
                            self.errorBlock(error);
                        }
                    });
                    return;
                }
                
                if ([object isKindOfClass:[UIImage class]]) {
                    UIImage *image = (UIImage *)object;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (self.photoCompletionBlock) {
                            self.photoCompletionBlock(@[image], nil);
                        }
                    });
                }
            }];
        }
        return;
    }
    
    // 多张图片选择
    if (results.count > 1 && self.photoCompletionBlock) {
        NSMutableArray *images = [NSMutableArray array];
        NSMutableArray *assets = [NSMutableArray array];
        
        dispatch_group_t group = dispatch_group_create();
        
        for (PHPickerResult *result in results) {
            if ([result.itemProvider canLoadObjectOfClass:[UIImage class]]) {
                dispatch_group_enter(group);
                
                [result.itemProvider loadObjectOfClass:[UIImage class] completionHandler:^(__kindof id<NSItemProviderReading>  _Nullable object, NSError * _Nullable error) {
                    
                    if (error) {
                        dispatch_group_leave(group);
                        return;
                    }
                    
                    if ([object isKindOfClass:[UIImage class]]) {
                        UIImage *image = (UIImage *)object;
                        [images addObject:image];
                        
                        // 获取 PHAsset (如果可用)
                        NSString *localIdentifier = [result.assetIdentifier componentsSeparatedByString:@"/"].lastObject;
                        if (localIdentifier) {
                            PHFetchResult *fetchResult = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
                            PHAsset *asset = fetchResult.firstObject;
                            if (asset) {
                                [assets addObject:asset];
                            }
                        }
                    }
                    
                    dispatch_group_leave(group);
                }];
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            if (self.photoCompletionBlock) {
                self.photoCompletionBlock(images, assets);
            }
        });
    }
}

#pragma mark - Permission Methods


@end 
