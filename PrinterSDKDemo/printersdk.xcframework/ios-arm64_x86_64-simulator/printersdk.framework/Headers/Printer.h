// PrinterSDK.h
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PrinterState) {
    PrinterStateDisconnected,
    PrinterStateConnected,
    PrinterStateIdle,
    PrinterStatePrinting,
    PrinterStatePrintingCompleted,
    PrinterStatePrintingPaused,
    PrinterStateError
};

@class DiscoveredDevice;
@class PrinterStatus;
@class PrintResult;
@class Printer;

@protocol PrinterDelegate <NSObject>
@optional
- (void)printerDidDiscoverDevice:(DiscoveredDevice *)device;
- (void)printerDidReportStatus:(PrinterStatus *)status;
- (void)printerDidFinishPrint:(PrintResult *)result;
- (void)printerDidChangeState:(PrinterState)state fromOldState:(PrinterState)oldState;
@end

@interface DiscoveredDevice : NSObject
@property (nonatomic, copy, readonly) NSString *id; // BLE peripheral identifier (UUID string)
@property (nonatomic, copy, readonly, nullable) NSString *name;
@property (nonatomic, copy, readonly, nullable) NSString *mac;
@property (nonatomic, assign, readonly) NSInteger rssi;
- (instancetype)initWithId:(NSString *)id
                      name:(nullable NSString *)name
                       mac:(nullable NSString *)mac
                      rssi:(NSInteger)rssi NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface PrinterStatus : NSObject
@property (nonatomic, assign) NSInteger battery;
@property (nonatomic, assign) BOOL hasPaper;
@property (nonatomic, assign) NSInteger inCharge;
@property (nonatomic, assign) BOOL isHot;
@property (nonatomic, assign) BOOL isLowBattery;
@property (nonatomic, assign) NSInteger density;
- (NSString *)description;
@end

@interface PrintResult : NSObject
@property (nonatomic, assign, readonly) BOOL success;
@property (nonatomic, copy, readonly, nullable) NSString *errorMessage;
- (instancetype)initWithSuccess:(BOOL)success
                  errorMessage:(nullable NSString *)errorMessage NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@end

@interface Printer : NSObject
@property (nonatomic, weak, nullable) id<PrinterDelegate> delegate;
@property (nonatomic, assign, readonly) PrinterState state;
@property (nonatomic, assign, readonly) NSInteger deviceType;
@property (nonatomic, assign, readonly) NSInteger dataLength;

- (instancetype)initWithContext:(nullable id)context NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (void)startScanWithTimeout:(NSTimeInterval)timeout; // seconds
- (void)connectById:(NSString *)id;
- (void)disconnect;

- (void)setDensity:(NSInteger)density;    // 0..6
- (void)movePaper:(NSInteger)height;      // 1..255
- (void)printWithBuffer:(NSData *)buffer;
- (void)stopPrint;
- (NSString *)getMac;
@end

// Utilities
@interface PrinterUtils : NSObject
+ (nullable NSString *)genCrcWithMac:(NSString *)mac
                               random:(NSData *)random
                               lowCrc:(NSString * _Nullable * _Nullable)lowCrc
                              highCrc:(NSString * _Nullable * _Nullable)highCrc;

+ (NSString *)bytesToHex:(NSData *)data;
+ (uint16_t)readUInt16BE:(NSData *)data offset:(NSInteger)offset;
+ (void)writeUInt16BE:(NSMutableData *)data offset:(NSInteger)offset value:(uint16_t)value;
+ (NSString *)macBytesToString:(NSData *)bytes reversed:(BOOL)reversed;
+ (NSData *)hexStringToByteArray:(NSString *)hex;
@end

NS_ASSUME_NONNULL_END
