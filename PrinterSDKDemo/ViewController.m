//
//  ViewController.m
//  PrinterSDKDemo
//
//  Created by Xiang He on 2025/4/2.
//

#import "ViewController.h"
#import "BluetoothTableViewCell.h"
#import <XQ_PrinterSDK/XQ_PrinterSDK.h>
#import <Masonry/Masonry.h>
#import <extobjc.h>
#import "HTPhotoPickerManager.h"
#import "ImageUtil.h"

static NSString* const kTableViewCellReuseIdentifier = @"kTableViewCellReuseIdentifier";
@interface ViewController ()<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) XQ_Bluetooth_DeviceManager *manager;

@property (nonatomic, strong) NSArray<XQ_Bluetooth_DeviceModel *> *devices;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [XQ_Bluetooth_DeviceManager configDebugModel:YES];
    self.manager = [XQ_Bluetooth_DeviceManager new];
    @weakify(self);
    self.manager.restoreBlock = ^(NSError * _Nullable error, NSArray<XQ_Bluetooth_DeviceModel *> * _Nonnull lists) {
        @strongify(self);
        self.devices = lists;
        [self.tableView reloadData];
    };
    // Do any additional setup after loading the view.
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
        make.right.equalTo(superView);
        make.size.mas_equalTo(CGSizeMake(100, 50));
    }];
    
    [superView addSubview:self.activityIndicator];
    [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(superView);
    }];
}

- (void)clickStart:(UIButton *)sender {
    
    [self.activityIndicator startAnimating];
    @weakify(self);
    [self.manager startScan:^(NSError * _Nullable error, NSArray<XQ_Bluetooth_DeviceModel *> * _Nonnull lists) {
        @strongify(self);
        [self.activityIndicator stopAnimating];
        self.devices = lists;
        [self.tableView reloadData];
    }];
}

#pragma mark -- UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.devices.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    BluetoothTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTableViewCellReuseIdentifier];
    
    XQ_Bluetooth_DeviceModel *model = self.devices[indexPath.row];

    cell.nameLabel.text = (model.name.length ? model.name : @"未知" );
    cell.detailLabel.text = model.UUIDDevice;
    
    NSString *uuid = model.UUIDDevice;
    @weakify(self);
    cell.connectBlock = ^(BOOL isConnect) {
        @strongify(self);
        if (isConnect) {
            [self.manager disConnect:uuid];
            BluetoothTableViewCell *findCell = [self getCellByID:uuid];
            if (nil != findCell) {
                findCell.stateImageView.backgroundColor = [UIColor redColor];
                findCell.connectButton.selected = NO;
            }
            
        } else {
            [self.manager connect:uuid block:^(NSError * _Nullable error) {
                BluetoothTableViewCell *findCell = [self getCellByID:uuid];
                if (nil != findCell) {
                    findCell.stateImageView.backgroundColor = (nil == error ? [UIColor greenColor] : [UIColor redColor]);
                    findCell.connectButton.selected = (nil == error);
                }
            }];
        }
    };
    
    cell.sendBlock = ^{
        @strongify(self);
        [[HTPhotoPickerManager sharedManager] pickSinglePhotoWithPHPickerFromViewController:self completion:^(NSArray<UIImage *> * _Nullable images, NSArray * _Nullable assets) {
            UIImage *image = [images firstObject];
            float width = 384.0f;
            CGFloat scale = image.size.width / image.size.height;
            CGFloat height = width / scale;
            NSData *data = [ImageUtil convertImage:image toWidth:width toHeight:(NSInteger)height toRotation:0];
            
            [self.manager print:model.UUIDDevice buffer:data block:^(BOOL success, NSString *msg) {
                if (success) {
                    NSLog(@"发送成功: %@", msg);
                } else {
                    NSLog(@"发送失败: %@", msg);
                }
            }];

        } cancel:nil error:nil];
    };
    
    cell.sendHalfBlock = ^{
        @strongify(self);

        // 从 app bundle 中加载 half_test_1.png
        UIImage *image = [UIImage imageNamed:@"half_test_1"];
        if (!image) {
            NSLog(@"图片 half_test_1 未找到");
            return;
        }

        [self.manager printHalfLabel:model.UUIDDevice image:image block:^(BOOL success, NSString *msg) {
            if (success) {
                NSLog(@"发送成功: %@", msg);
            } else {
                NSLog(@"发送失败: %@", msg);
            }
        }];
    };
    
    cell.snapBlock = ^{
        @strongify(self);
        UIImage *image = [self imageFromView:self.view];
        [self.manager sendData:model.UUIDDevice image:image block:^(BOOL success, NSString *msg) {
            if (success) {
                NSLog(@"发送成功: %@", msg);
            } else {
                NSLog(@"发送失败: %@", msg);
            }
        }];
    };
    
    cell.stateBlock = ^{
        @strongify(self);
        XQ_Bluetooth_DeviceState *state = [self.manager getDeviceState:model.UUIDDevice];
        NSString *text = [state debugDescription];
        BluetoothTableViewCell *findCell = [self getCellByID:uuid];
        if (nil != findCell) {
            findCell.stateLabel.text = text;
        }
        
    };
    
    cell.densityBlock = ^(NSInteger value) {
        @strongify(self);
        [self.manager setDensity:uuid density:value];
    };
    
    return cell;
}

- (BluetoothTableViewCell *)getCellByID:(NSString *)uuid {
    __block NSInteger index = -1;
    [self.devices enumerateObjectsUsingBlock:^(XQ_Bluetooth_DeviceModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.UUIDDevice isEqualToString:uuid]) {
            index = idx;
            *stop = YES;
        }
    }];
    if (-1 == index) {
        return nil;
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    BluetoothTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    return cell;
}

- (UIImage *)imageFromView:(UIView *)view {
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = [UIScreen mainScreen].scale;
    format.opaque = view.isOpaque;

    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:view.bounds.size format:format];
    
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        [view.layer renderInContext:context.CGContext];
    }];
    
    return image;
}

- (void)captureHighQualityImageFromView:(UIView *)view completion:(void (^)(UIImage *image))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGSize targetSize = view.bounds.size;
        CGFloat scale = [UIScreen mainScreen].scale;

        UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
        format.scale = scale;
        format.opaque = view.isOpaque;

        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:targetSize format:format];

        UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                // 使用更准确的截图方式，适用于复杂 UI（动画、透明、模糊等）
                [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
            });
        }];

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(image);
            });
        }
    });
}

#pragma mark -- UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 180;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIButton *)startButton {
    if (!_startButton) {
        _startButton = ({
            UIButton *button = [[UIButton alloc] init];
            [button setTitle:@"开启蓝牙扫描" forState:UIControlStateNormal];
            [button setTitle:@"end" forState:UIControlStateSelected];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
            
            button.titleLabel.font = [UIFont boldSystemFontOfSize:16];
            button.backgroundColor = [UIColor blueColor];
            button.layer.masksToBounds = YES;
            button.layer.cornerRadius = 3;
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
            tableView.backgroundColor = [UIColor whiteColor];
            tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            tableView.showsVerticalScrollIndicator = NO;
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            tableView.dataSource = self;
            tableView.delegate   = self;
            [tableView registerClass:[BluetoothTableViewCell class] forCellReuseIdentifier:kTableViewCellReuseIdentifier];
            tableView;
        });
    }
    return _tableView;
}

- (UIActivityIndicatorView *)activityIndicator {
    if (!_activityIndicator) {
        _activityIndicator = ({
            UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
            view.color = [UIColor redColor];
            view;
        });
    }
    return _activityIndicator;
}

@end
