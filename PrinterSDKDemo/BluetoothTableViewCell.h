//
//  BluetoothTableViewCell.h
//  ZAIssue
//
//  Created by hexiang on 2024/10/14.
//  Copyright © 2024 MAC. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BluetoothTableViewCell : UITableViewCell

@property (nonatomic, strong, readonly) UIImageView *stateImageView;
@property (nonatomic, strong, readonly) UILabel *nameLabel;
@property (nonatomic, strong, readonly) UILabel *detailLabel;
@property (nonatomic, strong, readonly) UIButton *connectButton;
@property (nonatomic, strong, readonly) UILabel *stateLabel;

@property (nonatomic, strong) void(^connectBlock)(BOOL isConnect);
@property (nonatomic, strong) void(^sendBlock)(void);
@property (nonatomic, strong) void(^snapBlock)(void);
@property (nonatomic, strong) void(^sendHalfBlock)(void);
@property (nonatomic, strong) void(^stateBlock)(void);
@property (nonatomic, strong) void(^densityBlock)(NSInteger value);

@end

NS_ASSUME_NONNULL_END
