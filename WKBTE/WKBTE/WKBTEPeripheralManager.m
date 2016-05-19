//
//  WKBTEManager.m
//  WKBTE
//
//  Created by WiKi on 16/5/17.
//  Copyright © 2016年 WiKi. All rights reserved.
//

#import "WKBTEPeripheralManager.h"

static WKBTEPeripheralManager *helper;

@implementation WKBTEPeripheralManager

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        helper = [[WKBTEPeripheralManager alloc] init];
    });
    return helper;
}

- (instancetype)init{
    
    self = [super init];
    if (self) {
        
        _manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
}


#pragma mark - 实例方法的实现;


/**
 *  扫描蓝牙设备
 */
- (void)scanThePeripheral{
    
    NSArray *services = [[NSArray alloc]init];

    [self.manager scanForPeripheralsWithServices:nil options:@{ CBCentralManagerScanOptionAllowDuplicatesKey : @YES,CBCentralManagerScanOptionSolicitedServiceUUIDsKey : services }];
    
}

/**
 *  连接
 */
- (void)connectToPeripheral:(CBPeripheral *)peripheral{
    
    
    [self.manager connectPeripheral:peripheral options:nil];
    
}



/**
 *  和某个设备断开连接
 */
- (void)cancelConnectWithPeripheral:(CBPeripheral *)peripheral{

    
    if (peripheral) {
        
        [self.manager cancelPeripheralConnection:peripheral];
    }else{
        
        [self.manager cancelPeripheralConnection:self.currentperipheral];
    }
    
    
}


/**
 *  发送数据
 */
- (void)sendMsgDataToCurrentConnectCharacteristic:(CBCharacteristic *)characteristic withData:(NSData *)sendData{

    
    if (self.currentperipheral == nil || characteristic == nil) {
        
        NSLog(@"请选择连接某个设备");
        
        return;
    }
    
    
    /*
     最好一个type参数可以为CBCharacteristicWriteWithResponse或type:CBCharacteristicWriteWithResponse,
     区别是,是否会有反馈.也就是会不会调用didwrite代理回调。 前者有。后者没有。
     */
    if(characteristic.properties & CBCharacteristicPropertyWrite){
        
        [self.currentperipheral writeValue:sendData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
        
        
    }else if (characteristic.properties & CBCharacteristicPropertyWriteWithoutResponse){
        
         [self.currentperipheral writeValue:sendData forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
        
    }else{
        
        NSLog(@"该设备不可写！");
    }

    
}


/**
 *  订阅Characteristic通知（server）
 */

- (void)notifyCharacteristic:(CBCharacteristic *)characteristic{
    
    
    [self.currentperipheral setNotifyValue:YES forCharacteristic:characteristic];
    
}


/**
 *  取消订阅Characteristic通知（server）
 */
- (void)cancelNotifyCharacteristic:(CBCharacteristic *)characteristic{
    
    
    [self.currentperipheral setNotifyValue:NO forCharacteristic:characteristic];
    
}


#pragma mark - 代理回调;

/**
 *  主设备状态改变的委托，
 *
 */
- (void)centralManagerDidUpdateState:(CBCentralManager *)central;
{
    if (central.state == CBCentralManagerStatePoweredOff) {

        
        UIAlertView *aler = [[UIAlertView alloc] initWithTitle:@"系统蓝牙关闭了" message:@"请打开蓝牙"
                             delegate:nil cancelButtonTitle:nil otherButtonTitles:@"ok", nil];
        
        [aler show];
        
        
    }else{
        //可以自己判断其他的类型
        /*
         CBCentralManagerStateUnknown = 0,
         CBCentralManagerStateResetting,
         CBCentralManagerStateUnsupported,
         CBCentralManagerStateUnauthorized,
         CBCentralManagerStatePoweredOff,
         CBCentralManagerStatePoweredOn,
         */
        
        NSLog(@"蓝牙状态 -> %ld",(long)central.state);
    }
}



/**
 *  当主设备扫描到外设的时候。
 *
 *  @param central           管理者
 *  @param peripheral        蓝牙设备
 *  @param advertisementData 数据
 *  @param RSSI              RSSI
 */
- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
{
    
    //这个方法里面，你可以解析出当前扫描到的外设的广播包信息，当前RSSI等，现在很多的做法是，会根据广播包带出来的设备名，初步判断是不是自己公司的设备，才去连接这个设备，就是在这里面进行判断的
 
    NSLog(@"这个才是真正的设备名称---->%@",peripheral.name);
    
    
    
    BOOL isExist = [self comparePeripheralisEqual:peripheral RSSI:RSSI];
    if (!isExist) {
        
        NSLog(@"扫描到的设备的数据advertisementData = %@",advertisementData);
        
        NSArray *services = [advertisementData objectForKey:@"kCBAdvDataServiceUUIDs"];

        BlePeripheral *l_per = [[BlePeripheral alloc]init];
        l_per.peripheral = peripheral;
        l_per.peripheralIdentifier = [peripheral.identifier UUIDString];
        l_per.peripheralLocaName = peripheral.name;
        l_per.peripheralRSSI = RSSI;
        l_per.peripheralServices   = [services count];
        
        [self.searchPeripheralArray addObject:l_per];
    }
    
    
}


#pragma mark  连接设备状态回调（成功 ，失败 ，断开连接 , 设备改参数了）;

/**
 *  连接上设备的时候
 *
 *  @param central    蓝牙管理者
 *  @param peripheral 设备
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral;
{
    
    //蓝牙停止扫描
    [self.manager stopScan];
    
    
    //当用户连接上设备的时候。默认这就是当前操作的设备。
    self.currentperipheral = peripheral;
    self.currentperipheral.delegate = self;
    
    //保存已经连接上的设备到数组中。
    [self.allConnectPeripheral addObject:peripheral];
    
    
    NSLog(@"已经连接上了: %@",peripheral.name);
    
    //delegate 给出去外面一个通知什么的，表明已经连接上了
    [self.managerDelegate bleMangerConnectedPeripheral:peripheral andIfConnected:YES];
    

#warning 读取所有server。但是有时候，不一定要读取所有的server。可以通过下面的方法书写。
    
    //我们直接一次读取外设的所有的Services ,如果只想找某个服务，直接传数组进去就行，比如你只想扫描服务UUID为 FFF1和FFE2 的这两项服务
    /*
     NSArray *array_service = [NSArray arrayWithObjects:[CBUUID UUIDWithString:@"FFF1"], [CBUUID UUIDWithString:@"FFE2"],nil];
     [m_peripheral discoverServices:array_service];
     */
    
    [self.currentperipheral discoverServices:nil];

    
}


/**
 *  连接外设失败
 *
 *  @param central    蓝牙管理者
 *  @param peripheral 设备
 *  @param error      错误原因
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
    //看苹果的官方解释 {@link connectPeripheral:options:} ,也就是说链接外设失败了
    
    
    [self.managerDelegate bleMangerConnectedPeripheral:peripheral andIfConnected:NO];
    
    NSLog(@"链接外设失败 %@",error);
    
    
}


/**
 *  断开连接
 *
 *  @param central    蓝牙管理者
 *  @param peripheral 设备
 *  @param error      错误描述
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
{
    //自己看看官方的说明，这个函数被调用是有前提条件的，首先你的要先调用过了 connectPeripheral:options:这个方法，其次是如果这个函数被回调的原因不是因为你主动调用了 cancelPeripheralConnection 这个方法，那么说明，整个蓝牙连接已经结束了，不会再有回连的可能，得要重来了
    NSLog(@"断开连接");
    
#error 需要确定一下，是否删除了。
    [self.allConnectPeripheral removeObject:peripheral];
    
    
    //如果你想要尝试回连外设，可以在这里调用一下链接函数
    /*
     [central connectPeripheral:peripheral options:@{CBCentralManagerScanOptionSolicitedServiceUUIDsKey : @YES,CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES}];
     */
    
    
    [self.managerDelegate bleMangerDisConnectedPeripheral:peripheral];
    
}


//当前连接的设备，修改了名称。

/**
 *  设备改名字了。浩之晨 --> 熊孩子
 */
- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral NS_AVAILABLE(NA, 6_0);
{
    
    //这个函数一般不会被调用，他被调用是因为 peripheral.name 被修改了，才会被调用
    
#error 会不会断开连接？？
    //TODO
    [self.allConnectPeripheral removeObject:self.currentperipheral];
    [self.allConnectPeripheral addObject:peripheral];
    
    
    self.currentperipheral  = peripheral ;
    
    
    
    
    /*
     
     该名称后重新否看需求而定。
     
    //重新连接该设备
    [self.manager connectPeripheral:peripheral options:nil];
    */
}



/**
 *  蓝牙设备变成了无效的服务。
 *
 */
- (void)peripheralDidInvalidateServices:(CBPeripheral *)peripheral NS_DEPRECATED(NA, NA, 6_0, 7_0);
{
    //这个函数一般也不会被调用，它是在你已经读取过一次外设的 services 之后，没有断开，这个时候外设突然来个我的某个服务不让用了，这个时候才会被调用，你得要再一次读取外设的 services 即可
    
    [self.allConnectPeripheral removeObject:self.currentperipheral];
    self.currentperipheral = nil;
    
    //重新连接该设备
    [self.manager connectPeripheral:peripheral options:nil];
    
}


/**
 *  对于蓝牙设备操作权限进行了更改。需要重新连接
 *
 *  @param peripheral          设备
 *  @param invalidatedServices server改变了？
 */
- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray *)invalidatedServices NS_AVAILABLE(NA, 7_0);
{
    
    [self.allConnectPeripheral removeObject:self.currentperipheral];
     self.currentperipheral = nil;
    
    //重新连接该设备
    [self.manager connectPeripheral:peripheral options:nil];
}



/**
 *  RSSI更新了。如果是实时的数据再次进行操作。
 */
- (void)peripheralDidUpdateRSSI:(CBPeripheral *)peripheral error:(NSError *)error NS_DEPRECATED(NA, NA, 5_0, 8_0);
{
    //这个函数一看就知道了，当外设更新了RSSI的时候被调用，当然，外设不会无故给你老是发RSSI，听硬件那边工程师说，蓝牙协议栈里面的心跳包是可以把RSSI带过来的，但是不知道什么情况，被封杀了，你的要主动调用 [peripheral readRSSI];方法，人家外设才给你回RSSI，不过这个方法现在被弃用了。用下面的方法来接收
    //已经弃用
    
}


/**
 *  RSSI更新了。如果是实时的数据再次进行操作。
 */
- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error NS_AVAILABLE(NA, 8_0);
{
    
    //同上，这个就是你主动调用了 [peripheral readRSSI];方法回调的RSSI，你可以根据这个RSSI估算一下距离什么的
    NSLog(@" peripheral Current RSSI:%@",RSSI);
    
}


#pragma mark 关于Server的回调;

/**
 *  当扫描到蓝牙的时候，会获取serv。 发现了server
 *
 *  @param peripheral 蓝牙设备
 *  @param error      错误信息
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error;
{
    //说明你上面调用的  [self.peripheral discoverServices:nil]; 方法起效果了，我们接着来找找特征值UUID
    
    for (CBService *service in [peripheral services]) {
        
        NSLog(@"Discovered service %@", service);

        [peripheral discoverCharacteristics:nil forService:service];  //同上，如果只想找某个特征值，传参数进去
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(NSError *)error;
{
    //基本用不上
    NSLog(@"didDiscoverIncludedServicesForService");
}



/**
 *  当发现特定服务的Characteristics。
 *
 *  @param peripheral 设备
 *  @param service    server
 *  @param error      错误
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error;
{
    //发现了（指定）的特征值了，如果你想要有所动作，你可以直接在这里做，比如有些属性为 notify 的 Characteristics ,你想要监听他们的值，可以这样写
    
    for (CBCharacteristic *characte in service.characteristics) {
        if ([[characte.UUID UUIDString] isEqualToString:@"FFF2"]) {
            
            //手动获取一下基本的数据。（一次，并且是刚发现的时候）
            [peripheral readValueForCharacteristic:characte];

            //监听（总是）。 不想监听的时候，设置为：NO 就行了
             [self notifyCharacteristic:characte];
             break;
        }
    }
    
    NSLog(@"characteristic uuid:%@",service.UUID);

 
}




/**
 *  获取特性的值。readValueForCharacteristic后的回调
 *
 *  @param peripheral     设备
 *  @param characteristic server
 *  @param error          错误
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
{
    //这个可是重点了，你收的一切数据，基本都从这里得到,你只要判断一下 [characteristic.UUID UUIDString] 符合你们定义的哪个，然后进行处理就行，值为：characteristic.value 一切数据都是这个，至于怎么解析，得看你们自己的了
    //[characteristic.UUID UUIDString]  注意： UUIDString 这个方法是IOS 7.1之后才支持的,要是之前的版本，得要自己写一个转换方法
    NSLog(@"receiveData = %@,fromCharacteristic.UUID = %@",characteristic.value,characteristic.UUID);
    
    NSLog(@"获取到的数据 ：%@",characteristic.value);
 
#warning 在这加个判断，看是不是自己需要的特征数据。
    [self.managerDelegate bleMangerReceiveDataPeripheral:peripheral witData:characteristic.value fromCharacteristic:characteristic];
    
    
}



/**
 *  这个方法被调用是因为你主动调用方法： setNotifyValue:forCharacteristic 给你的反馈
 */
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;

{
    
    NSLog(@"你更新了对特征值:%@ 的通知",[characteristic.UUID UUIDString]);
    
#warning 在这加个判断，看是不是自己需要的特征数据。
    [self.managerDelegate bleMangerReceiveDataPeripheral:peripheral witData:characteristic.value fromCharacteristic:characteristic];
    
}

#pragma mark  自己发送数据的回调;



/**
 *  自己发送数据的回调
 *
 *  @param peripheral     设备
 *  @param characteristic server
 *  @param error          错误
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error;
{
    //这个方法比较好，这个是你发数据到外设的某一个特征值上面，并且响应的类型是 CBCharacteristicWriteWithResponse ，上面的官方文档也有，如果确定发送到外设了，就会给你一个回应，当然，这个也是要看外设那边的特征值UUID的属性是怎么设置的,看官方文档，人家已经说了，条件是，特征值UUID的属性：CBCharacteristicWriteWithResponse
    
    if (!error) {
        NSLog(@"说明发送成功，characteristic.uuid为：%@",[characteristic.UUID UUIDString]);
    }else{
        NSLog(@"发送失败了啊！characteristic.uuid为：%@",[characteristic.UUID UUIDString]);
    }
    
}


/**
 *  写入出错。会调用该方法。
 */
- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    
    NSLog(@"发送数据，写入出错 %@",error);
    
}



#pragma mark   特征注册通知;

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    
    
    NSLog(@"特征注册通知");
    
}


- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error{
    
    
    NSLog(@"didDiscoverDescriptorsForCharacteristic");
    
}

#pragma mark - help;


/**
 *  有没有曾经扫描到过这个设备
 *
 *  @param disCoverPeripheral 设备
 *  @param RSSI               RSSI
 *
 *  @return YES/NO
 */
-(BOOL) comparePeripheralisEqual :(CBPeripheral *)disCoverPeripheral RSSI:(NSNumber *)RSSI
{
    if ([self.searchPeripheralArray count]>0) {
        for (int i=0;i<[self.searchPeripheralArray count];i++) {
            
            BlePeripheral *l_per = [self.searchPeripheralArray objectAtIndex:i];
            if ([disCoverPeripheral isEqual:l_per.peripheral]) {
                l_per.peripheralRSSI = RSSI;
                return YES;
            }
        }
    }
    return NO;
}



#pragma mark - getter;

- (NSMutableArray *)searchPeripheralArray{
    
    if (!_searchPeripheralArray) {
        _searchPeripheralArray = [[NSMutableArray alloc] init];
    }
    return _searchPeripheralArray;
}


- (NSMutableArray *)allConnectPeripheral{
    
    if (!_allConnectPeripheral) {
        _allConnectPeripheral = [[NSMutableArray alloc] init];
    }
    return _allConnectPeripheral;
}


@end


//===================================================================


@implementation BlePeripheral

@synthesize peripheral;
@synthesize peripheralIdentifier;
@synthesize peripheralLocaName;
@synthesize peripheralName;
@synthesize peripheralRSSI;
@synthesize peripheralServices;

@end
