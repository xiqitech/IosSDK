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

/// 同行“最左侧”为 stateLabel，右侧是浓度控件（步进器及标签）
@property (nonatomic, strong, readonly) UIStackView *densityRow;
@property (nonatomic, strong, readonly) UILabel *stateLabel;

/// status 两行：上行字段名、下行实时值（等宽字体更好读）
@property (nonatomic, strong, readonly) UILabel *statusNameLabel;
@property (nonatomic, strong, readonly) UILabel *statusValueLabel;

/// 其他按钮
@property (nonatomic, strong, readonly) UIButton *sendButton;
@property (nonatomic, strong, readonly) UIButton *sendHalfButton;
@property (nonatomic, strong, readonly) UIButton *snapButton;

/// 回调
@property (nonatomic, copy) void(^connectBlock)(BOOL isConnect);
@property (nonatomic, copy) void(^sendBlock)(void);
@property (nonatomic, copy) void(^sendHalfBlock)(void);
@property (nonatomic, copy) void(^snapBlock)(void);
@property (nonatomic, copy, nullable) void(^densityBlock)(NSInteger value);

- (void)updateStatusNames:(NSArray<NSString *> *)names
                   values:(NSArray<NSString *> *)values;

@end

NS_ASSUME_NONNULL_END
