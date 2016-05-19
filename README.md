# WKBTE
IOS 蓝牙 

WKBTEPeripheralManager 这是使用客户端作为peripheral来控制设备的简易封装。
用户在controller中通过来进行基本的UI显示。其余的需要用户自定义。

蓝牙可以连接多个设备。只是同时发消息是不可以的。
用户如果只是连接唯一的设备，有些参数可以设置为nil。那么就默认是当前连接的设备。

如果蓝牙连接了多个设备，那么在进行类似cacel。write 操作时。
需要重新复制currentPeripheral。
