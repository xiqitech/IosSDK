//
//  ImageUtil.h
//  XQ_PrinterSDK
//
//  Created by Xiang He on 2025/4/8.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageUtil : NSObject

+ (UIImage *)rotateImage:(UIImage *)image toRotation:(CGFloat)radians;

+ (UIImage *)grayImage:(UIImage *)image;

+ (NSData *)ditherImage:(UIImage *)image;

+ (UIImage *)imageByResizeToSize:(UIImage *)image size:(CGSize)size;

+ (UIImage *)imageByCropToRect:(UIImage *)image rect:(CGRect)rect;

+ (UIImage *)scaleAndCropImage:(UIImage *)image
                       toWidth:(CGFloat)targetWidth
                      toHeight:(CGFloat)targetHeight;

+ (NSData *)convertImage:(UIImage *)image
         toWidth:(CGFloat)toWidth
        toHeight:(CGFloat)toHeight
              toRotation:(CGFloat)toRotation;
+ (NSData *)convertLabelImage:(UIImage *)image
         toWidth:(CGFloat)toWidth
        toHeight:(CGFloat)toHeight
              toRotation:(CGFloat)toRotation;
@end

NS_ASSUME_NONNULL_END
