//
//  ViewController.m
//  PrinterSDKDemo
//
//  Created by Xiang He on 2025/4/2.
//

#import "ViewController.h"
#import "BluetoothTableViewCell.h"
#import <Masonry/Masonry.h>
#import <extobjc.h>
#import "HTPhotoPickerManager.h"
@import printersdk;


static NSString* const kTableViewCellReuseIdentifier = @"kTableViewCellReuseIdentifier";

@interface ViewController () <UITableViewDataSource, UITableViewDelegate, PrinterDelegate>

@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) Printer *printer;
@property (nonatomic, strong) NSMutableArray<DiscoveredDevice *> *devices;
// 优先 mac（标准化）去重，退化到 id
@property (nonatomic, strong) NSMutableDictionary<NSString *, DiscoveredDevice *> *deviceIndex;
// 实时状态缓存 key = 标准化 mac（无 mac 时用 id）
@property (nonatomic, strong) NSMutableDictionary<NSString *, PrinterStatus *> *latestStatusByKey;

@end

@implementation ViewController

#pragma mark - Helpers

static inline void vc_runOnMain(void (^block)(void)) {
    if (NSThread.isMainThread) { block(); }
    else { dispatch_async(dispatch_get_main_queue(), block); }
}

// 转小写不带分隔符
- (NSString *)normalizeMac:(NSString *)mac {
    if (mac.length == 0) return @"";
    NSString *s = [[mac stringByReplacingOccurrencesOfString:@":" withString:@""]
                   stringByReplacingOccurrencesOfString:@"-" withString:@""];
    return s.lowercaseString;
}
- (NSString *)keyForDevice:(DiscoveredDevice *)d {
    NSString *m = [self normalizeMac:d.mac];
    return (m.length ? m : (d.id ?: @""));
}
- (NSString *)keyForMacOrId:(NSString *)mac did:(NSString *)did {
    NSString *m = [self normalizeMac:mac];
    return (m.length ? m : (did ?: @""));
}

- (NSString *)stateText:(PrinterState)state {
    switch (state) {
        case PrinterStateDisconnected: return @"状态：Disconnected";
        case PrinterStateConnected: return   @"状态：Connected";
        case PrinterStateIdle: return        @"状态：Idle（已握手）";
        case PrinterStatePrinting: return    @"状态：Printing";
        case PrinterStatePrintingCompleted: return @"状态：PrintingCompleted";
        case PrinterStatePrintingPaused: return @"状态：PrintingPaused";
        case PrinterStateError: return       @"状态：Error";
    }
}

- (NSString *)statusNameLine {
    // 上行字段名（固定）
    return @"battery  hasPaper  inCharge  isHot  lowBatt  density";
}
- (NSString *)statusValueLineFrom:(PrinterStatus *)s {
    if (!s) return @"";
    // 下行实时值（与上行字段同顺序）
    return [NSString stringWithFormat:@"%ld        %d         %ld        %d       %d        %ld",
            (long)s.battery, s.hasPaper, (long)s.inCharge, s.isHot, s.isLowBattery, (long)s.density];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.printer = [[Printer alloc] initWithContext:nil];
    self.printer.delegate = self;
    self.devices = [NSMutableArray array];
    self.deviceIndex = [NSMutableDictionary dictionary];
    self.latestStatusByKey = [NSMutableDictionary dictionary];
    
    UIView *superView = self.view;
    superView.backgroundColor = [UIColor whiteColor];
    [superView addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(superView.mas_safeAreaLayoutGuideTop);
        make.bottom.equalTo(superView.mas_safeAreaLayoutGuideBottom);
        make.left.right.equalTo(superView);
    }];
    [superView addSubview:self.startButton];
    
    [self.startButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(superView).offset(-10);
        make.right.equalTo(superView).offset(-12);
        make.size.mas_equalTo(CGSizeMake(160, 46));
    }];
    
    [superView addSubview:self.activityIndicator];
    [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(superView);
    }];
}

- (void)clickStart:(UIButton *)sender {
    [self.activityIndicator startAnimating];
    [self.devices removeAllObjects];
    [self.deviceIndex removeAllObjects];
    [self.latestStatusByKey removeAllObjects];
    [self.tableView reloadData];
    [self.printer startScanWithTimeout:3.0];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
    });
}

#pragma mark - PrinterDelegate

- (void)printerDidDiscoverDevice:(DiscoveredDevice *)device {
    vc_runOnMain(^{
        NSString *key = [self keyForDevice:device];
        DiscoveredDevice *old = self.deviceIndex[key];
        
        if (old) {
            NSUInteger idx = [self.devices indexOfObjectIdenticalTo:old];
            if (idx != NSNotFound) {
                self.devices[idx] = device;
                self.deviceIndex[key] = device;
                NSIndexPath *ip = [NSIndexPath indexPathForRow:idx inSection:0];
                [self.tableView reloadRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationNone];
            } else {
                [self.devices addObject:device];
                self.deviceIndex[key] = device;
                [self.tableView reloadData];
            }
        } else {
            [self.devices addObject:device];
            self.deviceIndex[key] = device;
            NSIndexPath *ip = [NSIndexPath indexPathForRow:self.devices.count - 1 inSection:0];
            [self.tableView insertRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationFade];
        }
    });
}

- (void)printerDidChangeState:(PrinterState)state fromOldState:(PrinterState)oldState {
    vc_runOnMain(^{
        [self.tableView reloadData];
    });
}

- (void)printerDidReportStatus:(PrinterStatus *)status {
    vc_runOnMain(^{
        NSString *connMacNorm = [self normalizeMac:[self.printer getMac]];
        NSString *key = (connMacNorm.length ? connMacNorm : @"");
        if (key.length) {
            self.latestStatusByKey[key] = status;
        }
        __block NSIndexPath *ipToReload = nil;
        [self.devices enumerateObjectsUsingBlock:^(DiscoveredDevice * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *k = [self keyForDevice:obj];
            if ([k isEqualToString:key]) {
                ipToReload = [NSIndexPath indexPathForRow:idx inSection:0];
                *stop = YES;
            }
        }];
        if (ipToReload) {
            [self.tableView reloadRowsAtIndexPaths:@[ipToReload] withRowAnimation:UITableViewRowAnimationNone];
        } else {
            [self.tableView reloadData];
        }
    });
}

- (void)printerDidFinishPrint:(PrintResult *)result {
    NSLog(@"Print finished: success=%d, error=%@", result.success, result.errorMessage);
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return 1; }
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section { return self.devices.count; }

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BluetoothTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellReuseIdentifier];
    // 白底 + 不可选
    self.tableView.backgroundColor = UIColor.whiteColor;
    cell.backgroundColor = UIColor.whiteColor;
    cell.contentView.backgroundColor = UIColor.whiteColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    DiscoveredDevice *model = self.devices[indexPath.row];

    // 标题/副标题（显示 MAC，不显示 id）
    cell.nameLabel.text = (model.name.length ? model.name : @"未知设备");
    cell.nameLabel.textColor = UIColor.blackColor;
    cell.detailLabel.text = (model.mac.length ? model.mac : @"未知 MAC");
    cell.detailLabel.textColor = [UIColor darkGrayColor];

    // 连接状态 & 按钮选中态
    NSString *connMacNorm = [self normalizeMac:[self.printer getMac]];
    NSString *thisMacNorm = [self normalizeMac:model.mac];
    BOOL sameDevice = (thisMacNorm.length && [thisMacNorm isEqualToString:connMacNorm]);
    BOOL connectedLike =
        sameDevice &&
        (self.printer.state == PrinterStateIdle ||
         self.printer.state == PrinterStatePrinting ||
         self.printer.state == PrinterStatePrintingPaused ||
         self.printer.state == PrinterStatePrintingCompleted);

    cell.connectButton.selected = connectedLike;
    cell.stateImageView.backgroundColor = connectedLike ? UIColor.systemGreenColor : UIColor.systemRedColor;
    cell.stateImageView.layer.cornerRadius = cell.stateImageView.bounds.size.height * 0.5;
    cell.stateImageView.layer.masksToBounds = YES;

    // 连接/断开回调
    @weakify(self);
    cell.connectBlock = ^(BOOL isConnectSelected) {
        @strongify(self);
        if (isConnectSelected) {
            [self.printer disconnect];
        } else {
            [self.printer connectById:model.id];
        }
    };

    // 状态文本（与浓度同行最左）
    cell.stateLabel.text = [self stateText:self.printer.state];

    // 2×6 表格：上名称、下当前值（都居中）
    NSArray<NSString *> *names = @[@"battery", @"hasPaper", @"inCharge", @"isHot", @"lowBatt", @"density"];
    PrinterStatus *st = self.latestStatusByKey[[self keyForDevice:model]];
    NSArray<NSString *> *vals;
    if (st) {
        vals = @[
            [NSString stringWithFormat:@"%ld", (long)st.battery],
            st.hasPaper ? @"1" : @"0",
            [NSString stringWithFormat:@"%ld", (long)st.inCharge],
            st.isHot ? @"1" : @"0",
            st.isLowBattery ? @"1" : @"0",
            [NSString stringWithFormat:@"%ld", (long)st.density]
        ];
    } else {
        vals = @[@"-", @"-", @"-", @"-", @"-", @"-"];
    }
    [cell updateStatusNames:names values:vals];

    // 发送类按钮
    cell.sendBlock = ^{
        @strongify(self);
        [[HTPhotoPickerManager sharedManager] pickSinglePhotoWithPHPickerFromViewController:self
                                                                                completion:^(NSArray<UIImage *> * _Nullable images, NSArray * _Nullable assets) {
            UIImage *image = images.firstObject;
            if (!image) return;
            image = [ImageUtils scaleAndCropImage:image toWidth:384 toHeight:0];
            NSData* buffer = [ImageUtils ditherImage:image];
            [self.printer printWithBuffer:buffer];
        } cancel:nil error:nil];
    };
    cell.sendHalfBlock = ^{
        @strongify(self);
        UIImage *image = [UIImage imageNamed:@"half_test_1"];
        if (!image) { NSLog(@"图片 half_test_1 未找到"); return; }
        image = [ImageUtils scaleAndCropImage:image toWidth:384 toHeight:0];
        NSData* buffer = [ImageUtils convertImageToBinData:image];
        [self.printer printWithBuffer:buffer];
    };
    cell.snapBlock = ^{
        @strongify(self);
        UIImage *image = [self imageFromView:self.view];
        image = [ImageUtils scaleAndCropImage:image toWidth:384 toHeight:0];
        NSData* buffer = [ImageUtils ditherImage:image];
        [self.printer printWithBuffer:buffer];
    };

    // 浓度调节
    cell.densityBlock = ^(NSInteger value) {
        @strongify(self);
        [self.printer setDensity:value];
    };

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // 名称两行 + 按钮行 + 浓度同行 + status 两行
    return 210;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Snapshot helpers

- (UIImage *)imageFromView:(UIView *)view {
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = UIScreen.mainScreen.scale;
    format.opaque = view.isOpaque;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:view.bounds.size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        [view.layer renderInContext:context.CGContext];
    }];
}

#pragma mark - Lazies

- (UIButton *)startButton {
    if (!_startButton) {
        _startButton = ({
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:@"开启蓝牙扫描" forState:UIControlStateNormal];
            [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
            button.backgroundColor = UIColor.systemBlueColor;
            button.layer.cornerRadius = 8;
            button.layer.masksToBounds = YES;
            [button addTarget:self action:@selector(clickStart:) forControlEvents:UIControlEventTouchUpInside];
            button;
        });
    }
    return _startButton;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = ({
            UITableView *tableView = [UITableView new];
            tableView.backgroundColor = UIColor.whiteColor;
            tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            tableView.showsVerticalScrollIndicator = NO;
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            tableView.dataSource = self;
            tableView.delegate   = self;
            [tableView registerClass:[BluetoothTableViewCell class]
              forCellReuseIdentifier:kTableViewCellReuseIdentifier];
            tableView;
        });
    }
    return _tableView;
}

- (UIActivityIndicatorView *)activityIndicator {
    if (!_activityIndicator) {
        _activityIndicator = ({
            UIActivityIndicatorView *view =
            [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
            view.color = UIColor.redColor;
            view;
        });
    }
    return _activityIndicator;
}

@end
