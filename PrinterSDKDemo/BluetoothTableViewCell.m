//
//  BluetoothTableViewCell.m
//  ZAIssue
//
//  Created by hexiang on 2024/10/14.
//  Copyright © 2024 MAC. All rights reserved.
//

#import "BluetoothTableViewCell.h"
#import <Masonry/Masonry.h>

static CGSize const kSizeOfIconImageView = (CGSize){8, 8};
static CGFloat const kLabelLeftMargin = 10;

@interface BluetoothTableViewCell ()
{
    
}
@property (nonatomic, strong) UIImageView *stateImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIStackView *buttonStackView;
@property (nonatomic, strong) UIButton *connectButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *snapButton;
@property (nonatomic, strong) UIButton *sendHalfButton;
@property (nonatomic, strong) UIButton *stateButton;

@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UIStepper *stepper;
@property (nonatomic, strong) UILabel *stepperLabel;

@end

@implementation BluetoothTableViewCell

#pragma mark - Public Interface

#pragma mark - Life Cycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

#pragma mark - Event Response

- (void)clickConnect:(UIButton *)sender {
    if (self.connectBlock) {
        self.connectBlock(sender.selected);
    }
}

- (void)clickSend:(UIButton *)sender {
    if (self.sendBlock) {
        self.sendBlock();
    }
}

- (void)clickSnap:(UIButton *)sender {
    if (self.snapBlock) {
        self.snapBlock();
    }
}

- (void)clickHalfSend:(UIButton *)sender {
    if (self.sendHalfBlock) {
        self.sendHalfBlock();
    }
}

- (void)clickState:(UIButton *)sender {
    if (self.stateBlock) {
        self.stateBlock();
    }
}

- (void)stepperValueChanged:(UIStepper *)sender {
    self.stepperLabel.text = @(sender.value).stringValue;
    if (self.densityBlock) {
        self.densityBlock(sender.value);
    }
}

#pragma mark - Private Methods

- (void)setupUI {
    self.stepper = [[UIStepper alloc] initWithFrame:CGRectZero];
    self.stepper.minimumValue = 1;
    self.stepper.maximumValue = 6;
    self.stepper.stepValue = 1;
    self.stepper.value = 3;
    [self.stepper addTarget:self action:@selector(stepperValueChanged:) forControlEvents:UIControlEventValueChanged];

    UIView *superView = self.contentView;

    [superView addSubview:self.stateImageView];
    [superView addSubview:self.nameLabel];
    [superView addSubview:self.detailLabel];
    [superView addSubview:self.stepper];
    [superView addSubview:self.stepperLabel];
    [superView addSubview:self.stateLabel];

    // 👇 按钮放入 StackView
    self.buttonStackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.connectButton,
        self.snapButton,
        self.sendButton,
        self.sendHalfButton,
        self.stateButton
    ]];
    self.buttonStackView.axis = UILayoutConstraintAxisHorizontal;
    self.buttonStackView.spacing = 8;
    self.buttonStackView.alignment = UIStackViewAlignmentCenter;
    self.buttonStackView.distribution = UIStackViewDistributionFillEqually;

    [superView addSubview:self.buttonStackView];

    // 🔧 布局约束
    [self.stateImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(superView).offset(20);
        make.left.equalTo(superView).offset(10);
        make.size.mas_equalTo(kSizeOfIconImageView);
    }];

    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(superView).offset(8);
        make.left.equalTo(self.stateImageView.mas_right).offset(kLabelLeftMargin);
    }];

    [self.detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(2);
        make.left.equalTo(self.nameLabel);
    }];

    [self.buttonStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.detailLabel.mas_bottom).offset(8);
        make.left.equalTo(superView).offset(10);
        make.right.equalTo(superView).offset(-10);
        make.height.mas_equalTo(34);
    }];

    [self.stepper mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.buttonStackView.mas_bottom).offset(8);
        make.right.equalTo(superView).offset(-10);
    }];

    [self.stepperLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.stepper);
        make.right.equalTo(self.stepper.mas_left).offset(-10);
    }];

    [self.stateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.stepper.mas_bottom).offset(10);
        make.left.equalTo(superView).offset(10);
        make.right.equalTo(superView).offset(-10);
        make.height.mas_equalTo(40);
    }];

    [self.stateLabel setContentHuggingPriority:0 forAxis:UILayoutConstraintAxisHorizontal];
}

#pragma mark - Setter or Getter

- (UIImageView *)stateImageView {
    if (!_stateImageView) {
        _stateImageView = ({
            UIImageView *imageView = [[UIImageView alloc] init];
            imageView.layer.cornerRadius = kSizeOfIconImageView.width / 2.0f;
            imageView.layer.masksToBounds = YES;
            imageView.backgroundColor = [UIColor redColor];
            imageView;
        });
    }
    return _stateImageView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = ({
            UILabel *label = [UILabel new];
            label.textColor = [UIColor greenColor];
            label.font = [UIFont systemFontOfSize:15];
            label.textAlignment = NSTextAlignmentLeft;
            label;
        });
    }
    return _nameLabel;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = ({
            UILabel *label = [UILabel new];
            label.textColor = [UIColor greenColor];
            label.font = [UIFont systemFontOfSize:12];
            label.textAlignment = NSTextAlignmentLeft;
            label;
        });
    }
    return _detailLabel;
}

- (UIButton *)connectButton {
    if (!_connectButton) {
        _connectButton = ({
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:@"连接" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setTitle:@"断开" forState:UIControlStateSelected];
            [button setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
            
            button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
            button.backgroundColor = [UIColor greenColor];
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = 3;
            [button addTarget:self action:@selector(clickConnect:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    return _connectButton;
}

- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = ({
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:@"选图" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
            button.backgroundColor = [UIColor greenColor];
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = 3;
            [button addTarget:self action:@selector(clickSend:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    return _sendButton;
}


- (UIButton *)snapButton {
    if (!_snapButton) {
        _snapButton = ({
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:@"截屏" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
            button.backgroundColor = [UIColor greenColor];
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = 3;
            [button addTarget:self action:@selector(clickSnap:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    return _snapButton;
}

- (UIButton *)sendHalfButton {
    if (!_sendHalfButton) {
        _sendHalfButton = ({
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:@"半寸" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
            button.backgroundColor = [UIColor greenColor];
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = 3;
            [button addTarget:self action:@selector(clickHalfSend:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    return _sendHalfButton;
}


- (UIButton *)stateButton {
    if (!_stateButton) {
        _stateButton = ({
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:@"状态" forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
            button.backgroundColor = [UIColor greenColor];
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = 3;
            [button addTarget:self action:@selector(clickState:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    return _stateButton;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.backgroundColor = [UIColor clearColor];
            label.textColor = [UIColor blueColor];
            label.font = [UIFont systemFontOfSize:12];
            label.textAlignment = NSTextAlignmentLeft;
            label.numberOfLines = 0;
            label.preferredMaxLayoutWidth = [UIScreen mainScreen].bounds.size.width - 2 * 10;
            label;
        });
    }
    return _stateLabel;
}

- (UILabel *)stepperLabel {
    if (!_stepperLabel) {
        _stepperLabel = ({
            UILabel *label = [[UILabel alloc] init];
            label.backgroundColor = [UIColor clearColor];
            label.textColor = [UIColor redColor];
            label.font = [UIFont systemFontOfSize:12];
            label.textAlignment = NSTextAlignmentLeft;
            label.text = @"打印浓度设置";
            label;
        });
    }
    return _stepperLabel;
}

@end
