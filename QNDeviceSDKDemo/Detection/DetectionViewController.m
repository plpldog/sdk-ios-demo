//
//  DetectionViewController.m
//  QNDeviceSDKDemo
//
//  Created by Yolanda on 2018/3/16.
//  Copyright © 2018年 Yolanda. All rights reserved.
//

typedef enum{
    DeviceStyleNormal = 0,  //默认状态
    DeviceStyleScanning = 1,//正在扫描
    DeviceStyleLinging = 2,   //正在链接
    DeviceStyleLingSucceed = 3, //链接成功
    DeviceStyleMeasuringWeight = 4,//测量体重
    DeviceStyleMeasuringResistance = 5,//测量阻抗
    DeviceStyleMeasuringHeartRate = 6, //测量心率
    DeviceStyleMeasuringSucceed = 7,     //测量完成
    DeviceStyleDisconnect = 8,         //断开连接/称关机
}DeviceStyle;


#import "DetectionViewController.h"
#import "DeviceTableViewCell.h"
#import "ScaleDataCell.h"
#import "BandVC.h"

@interface DetectionViewController ()<UITableViewDelegate,UITableViewDataSource,BLEToolDelegate>
@property (weak, nonatomic) IBOutlet UILabel *appIdLabel;
@property (weak, nonatomic) IBOutlet UIButton *scanBtn;
@property (weak, nonatomic) IBOutlet UILabel *styleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *unstableWeightLabel;  //时时体重
@property (weak, nonatomic) IBOutlet UIView *headerView;

@property (nonatomic, assign) DeviceStyle currentStyle;
@property (nonatomic, strong) NSMutableArray *deviceAry; //扫描到外设数组
@property (nonatomic, strong) NSMutableArray *scaleDataAry; //收到测量完成后数组
@end

@implementation DetectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = @"测量";
    self.tableView.estimatedSectionFooterHeight = 0;
    self.tableView.estimatedSectionHeaderHeight = 0;
    self.tableView.estimatedRowHeight = 0;
    self.currentStyle = DeviceStyleNormal;
    [BLETool sharedBLETool].delegate = self;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(back)];
}

- (void)back {
    [[BLETool sharedBLETool] disconnectScale];
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark 设置设备各个阶段状态
- (void)setCurrentStyle:(DeviceStyle)currentStyle {
    _currentStyle = currentStyle;
    switch (_currentStyle) {
        case DeviceStyleScanning: //正在扫描
            [self setScanningStyleUI];
            [self startScanDevice];
            break;
        case DeviceStyleLinging: //正在链接
            [self setLingingStyleUI];
            break;
        case DeviceStyleLingSucceed: //链接成功
            [self setLingSucceedStyleUI];
            break;
        case DeviceStyleMeasuringWeight: //测量体重
            [self setMeasuringWeightStyleUI];
            break;
        case DeviceStyleMeasuringResistance: //测量阻抗
            [self setMeasuringSucceedStyleUI];
            break;
        case DeviceStyleMeasuringHeartRate: //测量心率
            [self setMeasuringSucceedStyleUI];
            break;
        case DeviceStyleMeasuringSucceed://测量完成
            [self setMeasuringResistanceStyleUI];
            break;
        case DeviceStyleDisconnect://断开连接/称关机
            [self setDisconnectStyleUI];
            [self disconnectDevice];
            break;
        default: //默认状态
            [self setNormalStyleUI];
            [self stopScanDevice];
            break;
    }
}
#pragma - UI处理
#pragma mark 正在扫描状态UI
- (void)setScanningStyleUI {
    [self.scanBtn setTitle:@"正在扫描" forState:UIControlStateNormal];
    self.headerView.hidden = NO;
    self.styleLabel.text = @"点击链接设备";
    self.unstableWeightLabel.text = @"";
    self.tableView.hidden = NO;
}

#pragma mark 正在链接状态UI
- (void)setLingingStyleUI {
    [self.scanBtn setTitle:@"断开连接" forState:UIControlStateNormal];
    self.styleLabel.text = @"正在连接";
    self.unstableWeightLabel.text = @"";
    self.tableView.hidden = YES;
    self.headerView.hidden = YES;
}

#pragma mark 链接成功状态UI
- (void)setLingSucceedStyleUI {
    [self.scanBtn setTitle:@"断开连接" forState:UIControlStateNormal];
    self.styleLabel.text = @"连接成功";
    self.unstableWeightLabel.text = @"0.0";
    self.tableView.hidden = YES;
    self.headerView.hidden = YES;
}

#pragma mark 测量体重状态UI
- (void)setMeasuringWeightStyleUI {
    self.styleLabel.text = @"正在称量";
}

#pragma mark 测量阻抗状态UI
- (void)setMeasuringSucceedStyleUI {
    self.styleLabel.text = @"正在测阻抗";
}

#pragma mark 测量完成状态UI
- (void)setMeasuringResistanceStyleUI {
    self.styleLabel.text = @"测量完成";
    self.tableView.hidden = NO;
}

#pragma mark 断开连接/称关机状态UI
- (void)setDisconnectStyleUI {
    [self.scanBtn setTitle:@"扫描" forState:UIControlStateNormal];
    self.styleLabel.text = @"连接已断开";
}

#pragma mark 默认状态UI
- (void)setNormalStyleUI {
    [self.scanBtn setTitle:@"扫描" forState:UIControlStateNormal];
    self.styleLabel.text = @"";
    self.unstableWeightLabel.text = @"";
    self.tableView.hidden = YES;
    self.headerView.hidden = NO;
}

#pragma mark - 蓝牙状态处理
#pragma mark 开始扫描附近设备
- (void)startScanDevice {
    [self.deviceAry removeAllObjects];
    [self.tableView reloadData];
    [[BLETool sharedBLETool] scanDevice];
}

#pragma mark 链接设备设备
- (void)connectDevice:(QNBleDevice *)device {

}

#pragma mark 断开设备
- (void)disconnectDevice {
    [[BLETool sharedBLETool] disconnectScale];
}

#pragma mark 停止扫描附近设备
- (void)stopScanDevice {
    [[BLETool sharedBLETool] stopScan];
}

#pragma mark -
- (void)qnDiscoverDevice:(QNBleDevice *)device{//该方法会在发现设备后回调
    for (QNBleDevice *item in self.deviceAry) {
        if ([item.mac isEqualToString:device.mac]) {
            return;
        }
    }
    [self.deviceAry addObject:device];
    [self.tableView reloadData];
}

- (void)qnDeviceStateChange:(QNDeviceState)state device:(QNBleDevice *)device {
    if (state == QNDeviceStateConnected) {//链接成功
        self.currentStyle = DeviceStyleLingSucceed;
    }else if (state == QNDeviceStateRealTime){//测量体重
        self.currentStyle = DeviceStyleMeasuringWeight;
    }else if (state == QNDeviceStateBodyFat){//测量阻抗
        self.currentStyle = DeviceStyleMeasuringResistance;
    }else if (state == QNDeviceStateHeartRate){//测量心率
        self.currentStyle = DeviceStyleMeasuringHeartRate;
    }else if (state == QNDeviceStateMeasureCompleted){//测量完成
        self.currentStyle = DeviceStyleMeasuringSucceed;
    }else if (state == QNDeviceStateLinkLoss){//断开连接/称关机
        self.currentStyle = DeviceStyleNormal;
    }
}

- (void)qnScaleReceiveRealTimeWeight:(double)weight device:(QNBleDevice *)device {
    weight = [[BLETool sharedBLETool] convertWeightWithTargetUnit:weight unit:[[QNBleApi sharedBleApi] getConfig].unit];
    self.unstableWeightLabel.text = [NSString stringWithFormat:@"%.2f",weight];
}

- (void)qnScaleReceiveResultData:(QNScaleData *)scaleData device:(QNBleDevice *)device {
    [self.scaleDataAry removeAllObjects];
    for (QNScaleItemData *item in [scaleData getAllItem]) {
        [self.scaleDataAry addObject:item];
    }
    [self.tableView reloadData];
}

- (void)qnScaleStoredDatas:(NSArray<QNScaleStoreData *> *)storedDataList device:(QNBleDevice *)device {
    //存储数据
}

- (void)qnBleStateUpdate:(QNBLEState)bleState {
    
}


#pragma mark - UITabelViewDelegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.currentStyle == DeviceStyleScanning) {
        return self.deviceAry.count;
    }else {
        return self.scaleDataAry.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.currentStyle == DeviceStyleScanning) {
        DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DeviceTableViewCell"];
        if (!cell) {
            cell = [[[NSBundle mainBundle]loadNibNamed:@"DeviceTableViewCell" owner:self options:nil]lastObject];
        }
        cell.device = self.deviceAry[indexPath.row];
        return cell;
    }else {
        ScaleDataCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ScaleDataCell"];
        if (!cell) {
            cell = [[[NSBundle mainBundle]loadNibNamed:@"ScaleDataCell" owner:self options:nil]lastObject];
        }
        cell.itemData = self.scaleDataAry[indexPath.row];
        cell.unit = [[QNBleApi sharedBleApi] getConfig].unit;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.currentStyle == DeviceStyleScanning) {
        [[BLETool sharedBLETool] stopScan];
        self.currentStyle = DeviceStyleLinging;
        QNBleDevice *device = self.deviceAry[indexPath.row];
        if (device.deviceType == QNDeviceBand) {
            BandMessage *bandMessage = [BandMessage sharedBandMessage];
            bandMessage.mac = device.mac;
            bandMessage.modeId = device.modeId;
            bandMessage.uuidString = device.uuidIdentifier;
            bandMessage.blueToothName = device.bluetoothName;
            self.user.weight = 60;//此处应为用户的实际体重值，该值会影响健康的相关数据
            bandMessage.user = self.user;
            BandVC *bandVc = [[BandVC alloc] init];
            [self.navigationController pushViewController:bandVc animated:YES];
        }else {
            [[BLETool sharedBLETool] connectDevice:device user:self.user];
        }
    }else {
        
    }
}

- (IBAction)clickScanBtn:(UIButton *)sender {
    switch (self.currentStyle) {
        case DeviceStyleScanning: self.currentStyle = DeviceStyleNormal; break;
        case DeviceStyleLinging:
        case DeviceStyleLingSucceed:
        case DeviceStyleMeasuringWeight:
        case DeviceStyleMeasuringResistance:
        case DeviceStyleMeasuringHeartRate:
        case DeviceStyleMeasuringSucceed:
            self.currentStyle = DeviceStyleDisconnect;
            break;
        case DeviceStyleDisconnect: self.currentStyle = DeviceStyleScanning; break;
        default:
            self.currentStyle = DeviceStyleScanning;
            break;
    }
}

- (NSMutableArray *)deviceAry {
    if (!_deviceAry) {
        _deviceAry = [NSMutableArray arrayWithCapacity:1];
    }
    return _deviceAry;
}

- (NSMutableArray *)scaleDataAry {
    if (!_scaleDataAry) {
        _scaleDataAry = [NSMutableArray arrayWithCapacity:1];
    }
    return _scaleDataAry;
}
@end
