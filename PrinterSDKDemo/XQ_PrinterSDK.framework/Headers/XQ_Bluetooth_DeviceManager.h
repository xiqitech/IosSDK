//
//  FDBluetoothManager.h
//  ZAIssue
//
//  Created by Xiang He on 2025/3/29.
//  Copyright © 2025 MAC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class XQ_Bluetooth_DeviceModel;
@class XQ_Bluetooth_DeviceState;

typedef void(^scanCompleteBlock)(NSError * __nullable error, NSArray<XQ_Bluetooth_DeviceModel *> *lists);
typedef void(^connectCompleteBlock)(NSError * __nullable error);

@interface XQ_Bluetooth_DeviceManager : NSObject

/// 设备恢复回调
@property (nonatomic, strong) scanCompleteBlock restoreBlock;

/// 配置是否启用日志
/// - Parameter debug: true-开启， false-关闭
+ (void)configDebugModel:(BOOL)debug;

/// 开启蓝牙扫描
/// - Parameter block: 扫描回调返回设备列表
- (void)startScan:(scanCompleteBlock)block;

/// 停止扫描（内部默认扫描时间3s）
- (void)stopScan;

/// 连接扫描到的设备
/// - Parameters:
///   - UUIDDevice: 根据扫描结果提供的设备UUID数据传入
///   - block: 连接回调
- (void)connect:(NSString *)UUIDDevice block:(__nullable connectCompleteBlock)block;

/// 断开设备连接
/// - Parameter UUIDDevice: 设备UUID
- (void)disConnect:(NSString *)UUIDDevice;

/// 发送数据
/// - Parameters:
///   - UUIDDevice: 发送到具体的设备(需要已经建立连接)
///   - data: 需要发送的数据
- (NSError *)sendData:(NSString *)UUIDDevice image:(UIImage *)image block:(void (^)(BOOL success, NSString* msg))block;

/// 打印
/// - Prameters:
///   - UUIDDevice: 发送到具体的设备(需要已经建立连接)
///   - data: 二值数据
- (void)print:(NSString *)UUIDDevice buffer:(NSData *)buffer block:(void (^)(BOOL success, NSString* msg))block;

/// 设置设备打印浓度
/// - Parameters:
///   - UUIDDevice: 设备UUID
///   - density: 浓度值 0 - 6
- (void)setDensity:(NSString *)UUIDDevice density:(NSInteger)density;

/// 获取设备状态信息
/// - Parameter UUIDDevice: 设备UUID
- (XQ_Bluetooth_DeviceState *)getDeviceState:(NSString *)UUIDDevice;

/// 设备状态回调设置
/// - Parameters:
///   - UUIDDevice: 设备UUID
///   - block: 状态回调
- (void)setDeviceStatusCallback:(NSString *)UUIDDevice block:(void (^)(XQ_Bluetooth_DeviceState *state))block;


@end

NS_ASSUME_NONNULL_END
