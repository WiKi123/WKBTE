//
//  WKBTEManager.h
//  WKBTE
//
//  Created by WiKi on 16/5/17.
//  Copyright © 2016年 WiKi. All rights reserved.
//

/*
 基于蓝牙4.0的封装。
 这是客户端作为操作方。也就是去连接外部设备。
 
 里面的各种回调。可以自己去通过各种方式去实现UI。就不写了。
 开发者自行去实现。例如，通过通知。
 
 注意：
 对于蓝牙的连接。
 如果是只会和一台设备相连。发送数据等，peripheral为空，默认和当前连接的设备发送
 如果蓝牙和多态设备正在连接，要写确定的peripheral。否则，默认和当前连接的设备发送

 */

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>


@protocol WKBTEDelegate <NSObject>

/**
 *  是否连接上了设备
 */
-(void)bleMangerConnectedPeripheral:(CBPeripheral *)peripheral andIfConnected:(BOOL)isConnect;

/**
 *  与某个设备断开了连接
 */
-(void)bleMangerDisConnectedPeripheral :(CBPeripheral *)peripheral;


/**
 *  收到了某个Characteristic特征数据
 */
-(void)bleMangerReceiveDataPeripheral:(CBPeripheral *)peripheral witData :(NSData *)data
                      fromCharacteristic :(CBCharacteristic *)curCharacteristic;


@end


//==================================================================



@interface WKBTEPeripheralManager : NSObject<CBCentralManagerDelegate,CBPeripheralDelegate>

/**
 *  单例.
 */
+ (instancetype)shareInstance;

/**
 *    系统蓝牙设备管理对象。可以把他理解为主设备。通过它，可以去扫描和连接外设。
 */
@property (nonatomic,strong,readonly ) CBCentralManager *manager;

/**
 *  当前连接的设备.
 */
@property (nonatomic,strong) CBPeripheral     *currentperipheral;


/**
 *  当前所有连接上的设备。 一个蓝牙可以连接多个设备。（ 有上线! ）
 *  当发数据切换目标设备的时候，重新赋值currentperipheral。
 */
@property (nonatomic,strong) NSMutableArray  *allConnectPeripheral;

/**
 *  检测到的所有蓝牙设备(无所谓)
 */
@property (nonatomic,strong) NSMutableArray   *searchPeripheralArray;


/**
 *  与外界UI通讯的代理
 */
@property (nonatomic,strong)  id<WKBTEDelegate>  managerDelegate;



/**
 *  扫描蓝牙
 */
- (void)scanThePeripheral;


/**
 *  连接某个蓝牙。
 */
- (void)connectToPeripheral:(CBPeripheral *)peripheral;


/**
 *  和某个设备断开连接
 *
 *  @param peripheral  为nil的时候，默认和当前的设备断开连接currentperipheral
 */
- (void)cancelConnectWithPeripheral:(CBPeripheral *)peripheral;


/**
 *  给当前连接的设备的某个特征发送数据
 *
 *  @param characteristic 特征类型 AFF0
 *  @param sendData       数据（一般是二进制数据。如果不是的话，自行更改里面的代码）
 */
- (void)sendMsgDataToCurrentConnectCharacteristic:(CBCharacteristic *)characteristic withData:(NSData *)sendData;


/**
 *  订阅Characteristic通知（为了实时的收到设备发送过来的数据）
 *  在操作中，我们给C端发送数据，C端一般都会返回数据，为了接收数据。
 */

- (void)notifyCharacteristic:(CBCharacteristic *)characteristic;


/**
 *  取消订阅Characteristic通知
 */
- (void)cancelNotifyCharacteristic:(CBCharacteristic *)characteristic;



@end


//===================================================================


@interface BlePeripheral : NSObject

@property(nonatomic,copy)   CBPeripheral *peripheral;
@property(nonatomic,copy)   NSString     *peripheralIdentifier;
@property(nonatomic,copy)   NSString     *peripheralLocaName;
@property(nonatomic,copy)   NSString     *peripheralName;
@property(nonatomic,copy)   NSNumber     *peripheralRSSI;
@property(nonatomic,assign) NSInteger     peripheralServices;

@end
