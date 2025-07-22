//
//  ImageUtil.m
//  XQ_PrinterSDK
//
//  Created by Xiang He on 2025/4/8.
//

#import "ImageUtil.h"
#import <ImageIO/ImageIO.h>

@implementation ImageUtil

+ (UIImage *)rotateImage:(UIImage *)image toRotation:(CGFloat)radians {
    size_t width = (size_t)CGImageGetWidth(image.CGImage);
    size_t height = (size_t)CGImageGetHeight(image.CGImage);
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0., 0., width, height), CGAffineTransformMakeRotation(radians));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)newRect.size.width,
                                                 (size_t)newRect.size.height,
                                                 8,
                                                 (size_t)newRect.size.width * 4,
                                                 colorSpace,
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;
    
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGContextTranslateCTM(context, +(newRect.size.width * 0.5), +(newRect.size.height * 0.5));
    CGContextRotateCTM(context, radians);
    
    CGContextDrawImage(context, CGRectMake(-(width * 0.5), -(height * 0.5), width, height), image.CGImage);
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage *img = [UIImage imageWithCGImage:imgRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imgRef);
    CGContextRelease(context);
    return img;
}

+ (UIImage *)imageByResizeToSize:(UIImage *)image size:(CGSize)size {
    if (size.width <= 0 || size.height <= 0) return nil;
    UIGraphicsBeginImageContextWithOptions(size, NO, image.scale);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage *)imageByCropToRect:(UIImage *)image rect:(CGRect)rect {
    rect.origin.x *= image.scale;
    rect.origin.y *= image.scale;
    rect.size.width *= image.scale;
    rect.size.height *= image.scale;
    if (rect.size.width <= 0 || rect.size.height <= 0) return nil;
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
    CGImageRelease(imageRef);
    return newImage;
}

+ (UIImage *)grayImage:(UIImage *)image {
    //NSLog(@"start gray iamge...");
    CGImageRef imgRef = image.CGImage;
    size_t width = CGImageGetWidth(imgRef);
    size_t height = CGImageGetHeight(imgRef);
    
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    UInt32 *pixels = (UInt32 *)calloc(width*height, sizeof(UInt32));
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, 4*width, colorSpaceRef, kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
    for (int y=0; y<height; y++) {
        for (int x=0; x<width; x++) {
            //计算平均值重新存储像素点-直接操作像素点
            uint8_t *rgbPixel = (uint8_t *)&pixels[y*width+x];
            UInt8 alpha = rgbPixel[0];
            if (alpha < 10) {
                rgbPixel[0] = 0xFF;
                rgbPixel[1] = 0xFF;
                rgbPixel[2] = 0xFF;
                rgbPixel[3] = 0xFF;
            } else {
                uint32_t gray = rgbPixel[1]*0.3+rgbPixel[2]*0.59+rgbPixel[3]*0.11;
                rgbPixel[1] = gray;
                rgbPixel[2] = gray;
                rgbPixel[3] = gray;
            }
        }
    }
    
    CGImageRef finalRef = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpaceRef);
    free(pixels);
    return [UIImage imageWithCGImage:finalRef scale:image.scale orientation:UIImageOrientationUp];
}

+ (NSData *)ditherImage:(UIImage *)image {
    // Get the data from the UIImage
    CGImageRef inputCGImage = image.CGImage;
    CGDataProviderRef provider = CGImageGetDataProvider(inputCGImage);
    NSData *data = CFBridgingRelease(CGDataProviderCopyData(provider));
    
    const unsigned char *dataPtr = [data bytes];
    size_t width = CGImageGetWidth(inputCGImage);
    size_t height = CGImageGetHeight(inputCGImage);
    size_t bytesPerRow = CGImageGetBytesPerRow(inputCGImage);
    
    // 创建一个用于存储灰度值的缓冲区
    NSMutableData *grayscaleData = [NSMutableData dataWithLength:width * height];
    unsigned char *grayscaleDataPtr = [grayscaleData mutableBytes];
    
    // 遍历像素并转换为灰度
    for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // 计算当前像素的索引
            size_t pixelIndex = y * bytesPerRow + x * 4; // 4个字节为一个像素：ARGB
            
            // 由于是灰度图像，R、G、B的值是相同的，这里我们取红色通道的值
            unsigned char grayValue = dataPtr[pixelIndex + 1]; // +1是因为A是第一个字节，R是第二个字节
            
            // 将灰度值存储到缓冲区
            grayscaleDataPtr[y * width + x] = grayValue;
        }
    }
    
    // Apply Floyd-Steinberg dithering algorithm
    for (size_t y = 0; y < height; y++) {
        for (size_t x = 0; x < width; x++) {
            size_t i = y * width + x; // 使用宽度而不是bytesPerRow
            UInt8 oldPixel = grayscaleDataPtr[i];
            UInt8 newPixel = oldPixel > 122 ? 255 : 0;
            grayscaleDataPtr[i] = newPixel;
            int quantError = oldPixel - newPixel;
            
            if (x + 1 < width) {
                grayscaleDataPtr[i + 1] = (UInt8)MIN(255, MAX(0, grayscaleDataPtr[i + 1] + (7 * quantError) / 16));
            }
            if (x > 0 && y + 1 < height) {
                grayscaleDataPtr[i + width - 1] = (UInt8)MIN(255, MAX(0, grayscaleDataPtr[i + width - 1] + (3 * quantError) / 16));
            }
            if (y + 1 < height) {
                grayscaleDataPtr[i + width] = (UInt8)MIN(255, MAX(0, grayscaleDataPtr[i + width] + (5 * quantError) / 16));
            }
            if (x + 1 < width && y + 1 < height) {
                grayscaleDataPtr[i + width + 1] = (UInt8)MIN(255, MAX(0, grayscaleDataPtr[i + width + 1] + (1 * quantError) / 16));
            }
        }
    }
    
    return [self convertToBinData:grayscaleDataPtr width:width height:height];
}

+ (UIImage *)scaleAndCropImage:(UIImage *)image
                       toWidth:(CGFloat)targetWidth
                      toHeight:(CGFloat)targetHeight {
    // 计算按比例缩放后的高度
    CGFloat scaledHeight = floor(targetWidth / image.size.width * image.size.height);
    CGSize scaledSize = CGSizeMake(targetWidth, scaledHeight);
    
    // 开始图形上下文
    UIGraphicsBeginImageContextWithOptions(scaledSize, NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh); // 设置高质量插值
    [image drawInRect:CGRectMake(0, 0, scaledSize.width, scaledSize.height)];
    
    // 从当前上下文中获取缩放后的图像
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // 如果缩放后的高度大于目标高度，需要裁剪图像
    if (targetHeight > 10 && scaledHeight > targetHeight) {
        CGFloat yOffset = (scaledHeight - targetHeight) / 2; // 计算裁剪的 y 偏移量
        CGRect cropRect = CGRectMake(0, yOffset, targetWidth, targetHeight);
        
        // 根据新的尺寸裁剪图像
        CGImageRef imageRef = CGImageCreateWithImageInRect([scaledImage CGImage], cropRect);
        UIImage *croppedImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationUp];
        CGImageRelease(imageRef);
        NSLog(@"scacle image width:%f, height:%f", croppedImage.size.width, croppedImage.size.height);
        
        return croppedImage;
    }
    
    NSLog(@"scacle image width:%f, height:%f", scaledImage.size.width, scaledImage.size.height);
    // 如果不需要裁剪，则返回缩放后的图像
    return scaledImage;
}

+ (NSData *)convertImage:(UIImage *)image
                 toWidth:(CGFloat)toWidth
                toHeight:(CGFloat)toHeight
              toRotation:(CGFloat)toRotation
{
    if (!image) {
        //reject(@"image_conversion_error", @"Could not convert base64 string to UIImage", nil);
        return nil;
    }
    
    // 检查旋转角度是否为0，或者是否大于360度
    if (toRotation != 0) {
        // 将角度转换为弧度
        CGFloat radians = toRotation * M_PI / 180;
        // 确保旋转角度在0到2π之间
        radians = fmod(radians, 2 * M_PI);
        // 旋转图片
        image = [ImageUtil rotateImage:image toRotation:radians];
        if (!image) {
            //reject(@"image_conversion_error", @"Could not rotate image", nil);
            return nil;
        }
    }
    
    // 缩放并裁剪图片
    image = [ImageUtil scaleAndCropImage:image toWidth:toWidth toHeight:toHeight];
    //image = [ImageUtil scaleAndCropImage:image toWidth:toWidth toHeight:toHeight];
    if (!image) {
        //reject(@"image_conversion_error", @"Could not convert scaled cropped image", nil);
        return nil;
    }
    
    // 转换图片为灰度图
    image = [ImageUtil grayImage:image];
    if (!image) {
        //reject(@"image_conversion_error", @"Could not convert image to grayscale", nil);
        return nil;
    }
    
    // 这个函数里面会新建一个图片，传递出来会被释放
    NSData *binaryData  = [ImageUtil ditherImage:image];
    
    return binaryData;
}

+ (NSData *)convertToBinData:(unsigned char *)grayscaleData
                                   width:(size_t)width
                                  height:(size_t)height {
    NSUInteger pixelCount = width * height;
    NSUInteger bitmapLength = (pixelCount + 7) / 8;
    NSMutableData *binaryBitmapData = [NSMutableData dataWithLength:bitmapLength];
    unsigned char *bitmapBytes = (unsigned char *)binaryBitmapData.mutableBytes;
    memset(bitmapBytes, 0, bitmapLength);

    for (NSUInteger i = 0; i < pixelCount; i++) {
        if (grayscaleData[i] < 122) {
            NSUInteger byteIndex = i / 8;
            NSUInteger bitIndex = 7 - (i % 8);
            bitmapBytes[byteIndex] |= (1 << bitIndex);
        }
    }
    return binaryBitmapData;
}

+ (NSData *)convertImageToBinData:(UIImage *)image {
    if (!image || !image.CGImage) return nil;

    CGImageRef cgImage = image.CGImage;
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    size_t bytesPerRow = width * 4;

    // 准备像素缓存（RGBA）
    UInt32 *pixels = (UInt32 *)calloc(width * height, sizeof(UInt32));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, bytesPerRow,
                                                 colorSpace, kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);

    // 生成二值图数据缓冲区（1bpp）
    NSUInteger totalPixels = width * height;
    NSUInteger binLength = (totalPixels + 7) / 8;
    NSMutableData *binaryData = [NSMutableData dataWithLength:binLength];
    uint8_t *binPtr = (uint8_t *)binaryData.mutableBytes;
    memset(binPtr, 0, binLength);

    for (NSUInteger i = 0; i < totalPixels; i++) {
        uint8_t *rgba = (uint8_t *)&pixels[i];
        uint8_t gray = rgba[1]; // R==G==B, 所以取 R 即可
        if (gray < 122) {
            NSUInteger byteIndex = i / 8;
            NSUInteger bitIndex = 7 - (i % 8);
            binPtr[byteIndex] |= (1 << bitIndex);
        }
    }

    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    return binaryData;
}

+ (NSData *)convertLabelImage:(UIImage *)image
                      toWidth:(CGFloat)toWidth
                     toHeight:(CGFloat)toHeight
                   toRotation:(CGFloat)toRotation
{
    if (!image || !image.CGImage) {
        return nil;
    }

    // ⬅️ 缩放 + 裁剪
    image = [ImageUtil scaleAndCropImage:image toWidth:toWidth toHeight:toHeight];
    if (!image) return nil;
    
    // ⬅️ 旋转处理（如有需要）
    if (toRotation != 0) {
        CGFloat radians = toRotation * M_PI / 180;
        radians = fmod(radians, 2 * M_PI);
        image = [ImageUtil rotateImage:image toRotation:radians];
        if (!image) return nil;
    }

    // ⬅️ 灰度处理
    image = [ImageUtil grayImage:image];
    if (!image) return nil;

    // ⬅️ 直接进行二值压缩（不使用 Floyd-Steinberg）
    return [ImageUtil convertImageToBinData:image];
}


@end
