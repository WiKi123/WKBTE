//
//  ViewController.m
//  WKBTE
//
//  Created by WiKi on 16/5/17.
//  Copyright © 2016年 WiKi. All rights reserved.
//

#import "ViewController.h"
#import "WKBTEPeripheralManager.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    //扫描
    [[WKBTEPeripheralManager shareInstance] scanThePeripheral];
    
    //连接
     CBPeripheral *peri = nil;
    [[WKBTEPeripheralManager shareInstance] connectToPeripheral:peri];
    
    //发送数据给某个特征
     NSData *data = nil;
     CBCharacteristic *charac = nil;
    [[WKBTEPeripheralManager shareInstance] sendMsgDataToCurrentConnectCharacteristic:charac withData:data];
    
    
    
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
