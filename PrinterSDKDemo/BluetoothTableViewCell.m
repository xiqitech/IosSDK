// BluetoothTableViewCell.m

#import "BluetoothTableViewCell.h"
#import <Masonry/Masonry.h>

static CGSize const kSizeOfIconImageView = (CGSize){8, 8};
static CGFloat const kLabelLeftMargin = 10;

@interface BluetoothTableViewCell ()
@property (nonatomic, strong) UIImageView *stateImageView;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UILabel *detailLabel;

@property (nonatomic, strong) UIStackView *buttonStackView;
@property (nonatomic, strong) UIButton *connectButton;
@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UIButton *sendHalfButton;
@property (nonatomic, strong) UIButton *snapButton;

@property (nonatomic, strong) UILabel *stateLabel;   // “状态：Idle…”（与浓度同行最左）
@property (nonatomic, strong) UIStepper *stepper;
@property (nonatomic, strong) UILabel *stepperLabel; // “打印浓度设置”

// 新增：2×6 状态表格
@property (nonatomic, strong) UIStackView *statusVStack;     // 垂直：两行
@property (nonatomic, strong) UIStackView *statusNamesRow;   // 第一行：字段名
@property (nonatomic, strong) UIStackView *statusValuesRow;  // 第二行：值
@property (nonatomic, strong) NSArray<UILabel *> *statusNameLabels;
@property (nonatomic, strong) NSArray<UILabel *> *statusValueLabels;
@end

@implementation BluetoothTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(nullable NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        [self setupUI];
    }
    return self;
}

#pragma mark - Events

- (void)clickConnect:(UIButton *)sender { if (self.connectBlock) self.connectBlock(sender.selected); }
- (void)clickSend:(UIButton *)sender { if (self.sendBlock) self.sendBlock(); }
- (void)clickHalfSend:(UIButton *)sender { if (self.sendHalfBlock) self.sendHalfBlock(); }
- (void)clickSnap:(UIButton *)sender { if (self.snapBlock) self.snapBlock(); }
- (void)stepperValueChanged:(UIStepper *)sender {
    if (self.densityBlock) self.densityBlock(sender.value);
}

#pragma mark - UI

- (UILabel *)makeCenterLabel:(UIFont *)font color:(UIColor *)color {
    UILabel *l = [[UILabel alloc] init];
    l.font = font;
    l.textColor = color;
    l.textAlignment = NSTextAlignmentCenter;
    l.numberOfLines = 1;
    return l;
}

- (void)setupUI {
    UIView *superView = self.contentView;

    // 顶部：小圆点 + 名称 + MAC
    [superView addSubview:self.stateImageView];
    [superView addSubview:self.nameLabel];
    [superView addSubview:self.detailLabel];

    // 中间：操作按钮（去掉“状态”按钮）
    self.buttonStackView = [[UIStackView alloc] initWithArrangedSubviews:@[
        self.connectButton, self.snapButton, self.sendButton, self.sendHalfButton
    ]];
    self.buttonStackView.axis = UILayoutConstraintAxisHorizontal;
    self.buttonStackView.spacing = 8;
    self.buttonStackView.alignment = UIStackViewAlignmentCenter;
    self.buttonStackView.distribution = UIStackViewDistributionFillEqually;
    [superView addSubview:self.buttonStackView];

    // 浓度行：stateLabel（最左） + … + stepperLabel + stepper（最右）
    [superView addSubview:self.stateLabel];
    [superView addSubview:self.stepperLabel];
    [superView addSubview:self.stepper];

    // 底部：2×6 状态表格（两行 stack）
    self.statusNamesRow = [[UIStackView alloc] init];
    self.statusValuesRow = [[UIStackView alloc] init];
    for (int i = 0; i < 6; i++) {
        // 名称行
        UILabel *nl = [self makeCenterLabel:[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold]
                                      color:[UIColor darkTextColor]];
        nl.text = @"-";
        // 数值行
        UILabel *vl = [self makeCenterLabel:[UIFont systemFontOfSize:12] color:[UIColor grayColor]];
        vl.text = @"-";

        [self.statusNamesRow addArrangedSubview:nl];
        [self.statusValuesRow addArrangedSubview:vl];
    }
    self.statusNamesRow.axis = UILayoutConstraintAxisHorizontal;
    self.statusNamesRow.alignment = UIStackViewAlignmentFill;
    self.statusNamesRow.distribution = UIStackViewDistributionFillEqually;
    self.statusNamesRow.spacing = 4;

    self.statusValuesRow.axis = UILayoutConstraintAxisHorizontal;
    self.statusValuesRow.alignment = UIStackViewAlignmentFill;
    self.statusValuesRow.distribution = UIStackViewDistributionFillEqually;
    self.statusValuesRow.spacing = 4;

    self.statusVStack = [[UIStackView alloc] initWithArrangedSubviews:@[self.statusNamesRow, self.statusValuesRow]];
    self.statusVStack.axis = UILayoutConstraintAxisVertical;
    self.statusVStack.alignment = UIStackViewAlignmentFill;
    self.statusVStack.distribution = UIStackViewDistributionFillEqually;
    self.statusVStack.spacing = 6;

    // 保存 label 引用
    NSMutableArray *names = [NSMutableArray array];
    NSMutableArray *vals  = [NSMutableArray array];
    for (UIView *v in self.statusNamesRow.arrangedSubviews) [names addObject:(UILabel *)v];
    for (UIView *v in self.statusValuesRow.arrangedSubviews) [vals addObject:(UILabel *)v];
    self.statusNameLabels  = names;
    self.statusValueLabels = vals;

    [superView addSubview:self.statusVStack];

    // ======= 约束 =======
    [self.stateImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(superView).offset(20);
        make.left.equalTo(superView).offset(10);
        make.size.mas_equalTo(kSizeOfIconImageView);
    }];

    [self.nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(superView).offset(8);
        make.left.equalTo(self.stateImageView.mas_right).offset(kLabelLeftMargin);
        make.right.lessThanOrEqualTo(superView).offset(-10);
    }];

    [self.detailLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.nameLabel.mas_bottom).offset(2);
        make.left.equalTo(self.nameLabel);
        make.right.lessThanOrEqualTo(superView).offset(-10);
    }];

    [self.buttonStackView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.detailLabel.mas_bottom).offset(8);
        make.left.equalTo(superView).offset(10);
        make.right.equalTo(superView).offset(-10);
        make.height.mas_equalTo(34);
    }];

    // 浓度同行：stateLabel（左） + stepperLabel + stepper（右）
    [self.stepper mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.buttonStackView.mas_bottom).offset(8);
        make.right.equalTo(superView).offset(-10);
    }];

    [self.stepperLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.stepper.mas_centerY);
        make.right.equalTo(self.stepper.mas_left).offset(-8);
    }];

    [self.stateLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.stepper.mas_centerY);
        make.left.equalTo(superView).offset(10);
        make.right.lessThanOrEqualTo(self.stepperLabel.mas_left).offset(-8);
    }];

    // 2×6 表格在最下方
    [self.statusVStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.stepper.mas_bottom).offset(10);
        make.left.equalTo(superView).offset(10);
        make.right.equalTo(superView).offset(-10);
        make.bottom.equalTo(superView).offset(-10);
        make.height.mas_greaterThanOrEqualTo(44); // 保证两行可见
    }];
}

#pragma mark - Update status grid

- (void)updateStatusNames:(NSArray<NSString *> *)names
                   values:(NSArray<NSString *> *)values {
    // names/values 不足 6 个则用 "-"
    for (NSInteger i = 0; i < 6; i++) {
        NSString *n = (i < names.count) ? names[i] : @"-";
        NSString *v = (i < values.count) ? values[i] : @"-";
        self.statusNameLabels[i].text  = n;
        self.statusValueLabels[i].text = v;
    }
}

#pragma mark - Lazy subviews

- (UIImageView *)stateImageView {
    if (!_stateImageView) {
        _stateImageView = [[UIImageView alloc] init];
        _stateImageView.layer.cornerRadius = kSizeOfIconImageView.width / 2.0;
        _stateImageView.layer.masksToBounds = YES;
        _stateImageView.backgroundColor = [UIColor redColor];
    }
    return _stateImageView;
}
- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [UILabel new];
        _nameLabel.textColor = [UIColor blackColor];
        _nameLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _nameLabel;
}
- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [UILabel new];
        _detailLabel.textColor = [UIColor darkGrayColor];
        _detailLabel.font = [UIFont systemFontOfSize:12];
        _detailLabel.textAlignment = NSTextAlignmentLeft;
    }
    return _detailLabel;
}

- (UIButton *)connectButton {
    if (!_connectButton) {
        _connectButton = [[UIButton alloc] init];
        [_connectButton setTitle:@"连接" forState:UIControlStateNormal];
        [_connectButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_connectButton setTitle:@"断开连接" forState:UIControlStateSelected];
        [_connectButton setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        _connectButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _connectButton.backgroundColor = [UIColor systemGreenColor];
        _connectButton.layer.cornerRadius = 6;
        _connectButton.layer.masksToBounds = YES;
        [_connectButton addTarget:self action:@selector(clickConnect:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _connectButton;
}
- (UIButton *)sendButton {
    if (!_sendButton) {
        _sendButton = [[UIButton alloc] init];
        [_sendButton setTitle:@"选图" forState:UIControlStateNormal];
        [_sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _sendButton.backgroundColor = [UIColor systemBlueColor];
        _sendButton.layer.cornerRadius = 6;
        _sendButton.layer.masksToBounds = YES;
        [_sendButton addTarget:self action:@selector(clickSend:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendButton;
}
- (UIButton *)sendHalfButton {
    if (!_sendHalfButton) {
        _sendHalfButton = [[UIButton alloc] init];
        [_sendHalfButton setTitle:@"半寸" forState:UIControlStateNormal];
        [_sendHalfButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _sendHalfButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _sendHalfButton.backgroundColor = [UIColor systemBlueColor];
        _sendHalfButton.layer.cornerRadius = 6;
        _sendHalfButton.layer.masksToBounds = YES;
        [_sendHalfButton addTarget:self action:@selector(clickHalfSend:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _sendHalfButton;
}
- (UIButton *)snapButton {
    if (!_snapButton) {
        _snapButton = [[UIButton alloc] init];
        [_snapButton setTitle:@"截屏" forState:UIControlStateNormal];
        [_snapButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _snapButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _snapButton.backgroundColor = [UIColor systemBlueColor];
        _snapButton.layer.cornerRadius = 6;
        _snapButton.layer.masksToBounds = YES;
        [_snapButton addTarget:self action:@selector(clickSnap:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _snapButton;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[UILabel alloc] init];
        _stateLabel.backgroundColor = UIColor.clearColor;
        _stateLabel.textColor = UIColor.blackColor;
        _stateLabel.font = [UIFont systemFontOfSize:12];
        _stateLabel.textAlignment = NSTextAlignmentLeft;
        _stateLabel.numberOfLines = 1;
    }
    return _stateLabel;
}
- (UILabel *)stepperLabel {
    if (!_stepperLabel) {
        _stepperLabel = [[UILabel alloc] init];
        _stepperLabel.backgroundColor = UIColor.clearColor;
        _stepperLabel.textColor = UIColor.darkGrayColor;
        _stepperLabel.font = [UIFont systemFontOfSize:12];
        _stepperLabel.textAlignment = NSTextAlignmentRight;
        _stepperLabel.text = @"打印浓度设置";
    }
    return _stepperLabel;
}
- (UIStepper *)stepper {
    if (!_stepper) {
        _stepper = [[UIStepper alloc] initWithFrame:CGRectZero];
        _stepper.minimumValue = 1;
        _stepper.maximumValue = 6;
        _stepper.stepValue = 1;
        _stepper.value = 3;
        [_stepper addTarget:self action:@selector(stepperValueChanged:) forControlEvents:UIControlEventValueChanged];
    }
    return _stepper;
}

@end
