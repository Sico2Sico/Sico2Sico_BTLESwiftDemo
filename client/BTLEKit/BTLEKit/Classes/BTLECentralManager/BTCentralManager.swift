//
//  BTCentralManager.swift
//  BTLEKit
//
//  Created by 德志 on 2018/1/15.
//

import UIKit
import CryptoSwift
import CoreBluetooth


public class BTCentralManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    /// 单例
    static public let instance = BTCentralManager()

    /// CentralManager配置model
    private var configModel  = BTCentralModel()
    
    /// weak
    public weak var  delegate : BTManagerProtocol?
    

    private override init() {
        super.init()
        configModel.centralManager = CBCentralManager(delegate: self, queue:nil)
    }
    

    //MARK:- 提供操作的三个api
    /// 配置参数 需要自定义设置的时候可以调用
    public func setConfigModel(maxRSSI:Int = -15,minRSSI:Int = -35, maxBuffer:Int = 20,endFlag:String = "EOM"){
        configModel.maxRSSI = maxRSSI
        configModel.minRSSI = minRSSI
        configModel.maxBuffer = maxBuffer
        configModel.endFlag = endFlag
        
    }
    
    /// 开始链接
    public func startConnect(serverID:String,characteristicID:String)-> Bool{
        
        configModel.serverUUID = serverID
        configModel.characteristicID = characteristicID
        
        guard configModel.centralManager.state == .poweredOn else {
            return false
        }
        scan()
        return true
    }
    
    
    /// 写入数据
    public func writeMsg(data:Data,type:DataType){
        guard configModel.sendState == SendState.sendEnd else {
            return
        }
        return sendMsg(data: data, type: type)
    }
    
    
    
    
    

    //MARK:- 客户端代理(CBCentralManagerDelegate)
    /// 客户端状态发生改变
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else {
            return
        }
        scan()
    }


    /// 扫描到服务  获取周边的服务列表
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                               advertisementData: [String : Any], rssi RSSI: NSNumber) {

        if RSSI.intValue > configModel.maxRSSI || RSSI.intValue < configModel.minRSSI {
            return
        }
        
        guard configModel.peripheral == peripheral else {
            // 准备建立连接
            configModel.peripheral = peripheral
            central.connect(peripheral, options:nil)
            return
        }
    }

    
    /// 连接成功
    public func centralManager(_ central: CBCentralManager,
                               didConnect peripheral: CBPeripheral) {
        central.stopScan()
        configModel.peripheral?.delegate = self
        //查找外设的服务特征
        configModel.peripheral?.discoverServices([ CBUUID(string: configModel.serverUUID)])
    }

    /// 连接失败
    public func centralManager(_ central: CBCentralManager,
                               didFailToConnect peripheral: CBPeripheral, error: Error?) {
        configModel.peripheral = nil
        scan()
    }

    //断开连接
    public func centralManager(_ central: CBCentralManager,
                               didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        configModel.peripheral = nil
        scan()
    }




    //MARK:- 外设服务代理(CBPeripheralDelegate)
    /// 获取到特征 服务
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard  error == nil else {
            cleanUp()
            return
        }

        _ = peripheral.services?.flatMap({ (service) -> Void in
            // 设置特征
            peripheral.discoverCharacteristics([ CBUUID(string:configModel.characteristicID)], for:service)
        })
    }


    /// 发现特征  订阅
    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard  error == nil else {
            cleanUp()
            return
        }

        _ = service.characteristics?.flatMap({ (characteristic) -> Void in
            if characteristic.uuid.isEqual(CBUUID(string: configModel.characteristicID)) {
                //订阅特征服务
                peripheral .setNotifyValue(true, for:characteristic)
            }
        })
    }

    
    ///订阅设备 取消订阅 通知
    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            return
        }

        guard characteristic.uuid.isEqual(CBUUID(string:configModel.characteristicID)) else {
            return
        }

        guard characteristic.isNotifying else {
            //取消服务
           configModel.centralManager.cancelPeripheralConnection(peripheral)
            return
        }
        configModel.characteristic = characteristic
    }


    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            delegate?.readError()
            return
        }
        readMsg(data: characteristic.value!)
    }
    
    
    public func peripheral(_ peripheral: CBPeripheral,
                           didWriteValueFor characteristic: CBCharacteristic, error: Error?){
        guard error == nil else {
            configModel.sendState = .sendEnd
            delegate?.readError()
            return
        }
    }


    //MARK:- 扫描  移除
    private func scan() {
        guard configModel.serverUUID != "" else {
            return
        }
        
        guard configModel.characteristicID != "" else {
            return
        }
    
       let serverUUID = CBUUID(string: configModel.serverUUID)
       configModel.centralManager.scanForPeripherals(withServices:[serverUUID],
                                                     options:[CBCentralManagerScanOptionAllowDuplicatesKey:true])
    }

    
    func cleanUp() {
        guard  configModel.peripheral?.state != .connected else {
            return
        }

        guard  configModel.peripheral?.services != nil else {
           configModel.centralManager.cancelPeripheralConnection(configModel.peripheral!)
            return
        }

        _ = configModel.peripheral?.services?.flatMap({[weak self]  (service) -> Void in
            _ = service.characteristics?.flatMap({[weak self] (characteristic) -> Void in
                if characteristic.uuid .isEqual(CBUUID(string: configModel.characteristicID)) {
                    if characteristic.isNotifying {
                        //取消订阅
                        self?.configModel.peripheral?.setNotifyValue(false, for: characteristic)
                        return
                    }
                }
            })
        })
    }


    // MARK:-  消息发送 读取
    private func sendMsg(data:Data,type:DataType){
        
        let dataBytes =  [UInt8](data)
        let typeByte =  UInt8(type.rawValue)
        
        //CRC16校验
        let crc16 = dataBytes.crc16()
        let highByte = UInt8(crc16 >> 8 & 0xFF)
        let lowByte = UInt8(crc16 & 0xFF)
        
        //添加type和crc16
        var sendDataBytes = [UInt8](Data())
        sendDataBytes.append(highByte)
        sendDataBytes.append(lowByte)
        sendDataBytes.append(typeByte)
        sendDataBytes.append(contentsOf:dataBytes)
        
        guard configModel.sendState.rawValue == SendState.sendEnd.rawValue else {
            return
        }

        configModel.dataToSend = sendDataBytes.count
        configModel.sendDataIndex = 0

        guard  configModel.dataToSend >= configModel.sendDataIndex else {
            return
        }

        configModel.sendState = .sendStart
        while (configModel.sendState.rawValue != SendState.sendEnd.rawValue){
            var amountToSend = configModel.dataToSend - configModel.sendDataIndex
            amountToSend = amountToSend > configModel.maxBuffer ?  configModel.maxBuffer : amountToSend


            let sendData = Data.init(bytes:&sendDataBytes+configModel.sendDataIndex, count: amountToSend)
            configModel.peripheral?.writeValue(sendData, for: configModel.characteristic!, type:CBCharacteristicWriteType.withResponse)

            configModel.sendDataIndex += amountToSend
            if configModel.sendDataIndex >= configModel.dataToSend {
                configModel.peripheral?.writeValue(configModel.endFlag.data(using: String.Encoding.utf8)!,
                                                   for:configModel.characteristic!, type: CBCharacteristicWriteType.withResponse)
                configModel.sendState = .sendEnd
            }
        }
    }


    //／ 内部读取数据
    fileprivate func readMsg(data:Data){
        let indexStr = String(data:data, encoding: String.Encoding.utf8)
        guard indexStr != configModel.endFlag else {
            configModel.readState = .readEnd
            crc16Data(data: configModel.readDataD)
            return
        }

        if configModel.readState.rawValue == ReadState.readEnd.rawValue {
            configModel.readState = .readStart
            configModel.readDataD = Data()
        }

        configModel.readDataD.append(data)
    }
    
    
    /// 读取数据校验
    fileprivate func crc16Data(data:Data){
        var readData = [UInt8](data)
        let dataLengthl = readData.count
        
        guard dataLengthl > 3 else {
            delegate?.readError()
            return
        }
        
        let readCrc16   = Data.init(bytes:&readData, count:2)
        let readType    = Data.init(bytes:&readData+2, count:1)
        let readContent = Data.init(bytes:&readData+3, count: (dataLengthl - 3))

        let crc16 = readContent.crc16()
        guard crc16 == readCrc16 else{
            delegate?.readError()
            return
        }
        
        let tyo = readType.hashValue
        delegate?.readSussces(data: readContent, type:DataType.getValueType(value:tyo))
    }
}
