//
//  XQDeviceModel.h
//  ZAIssue
//
//  Created by Xiang He on 2025/3/31.
//  Copyright © 2025 MAC. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XQ_Bluetooth_DeviceState : NSObject

// 当前电池电量 1-100
@property (nonatomic, assign) NSInteger  battery;

// 纸仓状态 true-有纸，false-缺纸
@property (nonatomic, assign) BOOL  hasPaper;

// 充电状态• 0 - 未充电• 1 - 充电中• 2 - 充电完成
@property (nonatomic, assign) NSInteger  inCharge;

// 打印头温度状态 true-过热，false-温度正常
@property (nonatomic, assign) BOOL  isHot;

// 低电压警告：• true - 电压不足• false - 电压正常
@property (nonatomic, assign) BOOL  isLowBattery;

// 打印浓度等级(0-6)：• 0 - 最淡• 6 - 最浓
@property (nonatomic, assign) NSInteger  density;

@end

@interface XQ_Bluetooth_DeviceModel : NSObject

// 设备名称
@property (nonatomic, strong) NSString *name;
// 设备UUID
@property (nonatomic, strong) NSString *UUIDDevice;
// 设备MAC
@property (nonatomic, strong) NSString * mac;

@end

NS_ASSUME_NONNULL_END
