//
//  ImageUtils.h
//  printersdk
//
//  Created by hutao on 2025/10/15.
//

#ifndef ImageUtils_h
#define ImageUtils_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageUtils : NSObject

+ (UIImage *)rotateImage:(UIImage *)image toRotation:(CGFloat)radians;

+ (UIImage *)grayImage:(UIImage *)image;

+ (NSData *)ditherImage:(UIImage *)image;

+ (UIImage *)imageByResizeToSize:(UIImage *)image size:(CGSize)size;

+ (UIImage *)imageByCropToRect:(UIImage *)image rect:(CGRect)rect;

+ (UIImage *)scaleAndCropImage:(UIImage *)image
                       toWidth:(CGFloat)targetWidth
                      toHeight:(CGFloat)targetHeight;

+(NSData *)convertImageToBinData:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END


#endif /* ImageUtils_h */
