//
//  BTCentralModel.swift
//  BTLEKit
//
//  Created by 德志 on 2018/1/18.
//

import UIKit
import CoreBluetooth

/// 写入状态
public enum SendState:Int {
    case sendStart
    case sending
    case sendEnd
}

/// 读取状态
public enum ReadState : Int {
    case readStart
    case reading
    case readEnd
}

//／ 数据类型
public enum DataType:Int{
    case image
    case audio
    case video
    case xml
    case json
    case text
    
    static func getValueType(value:Int)->DataType{
        switch value {
        case DataType.image.rawValue:
            return DataType.image
        case DataType.audio.rawValue:
            return DataType.audio
        case DataType.video.rawValue:
            return DataType.video
        case DataType.xml.rawValue:
            return DataType.xml
        case DataType.json.rawValue:
            return DataType.json
        case DataType.text.rawValue:
            return DataType.text
        default:
            return DataType.text
        }
    }
}


/// 配置model
class BTCentralModel{
    
    /// 服务id
    public var serverUUID : String = ""
    
    /// 特征id
    public var characteristicID : String = ""
    
    
    /// 客户端获取外设对象
    public var  peripheral : CBPeripheral?
    
    /// 特征
    public var  characteristic  : CBCharacteristic?
    
    //／ 客服端管理中心
    public var centralManager : CBCentralManager!
    

    
    /// 读取完的数据
    public var  readDataD:Data = Data()
    
    /// 发送总的数据长度
    public var  dataToSend : Int = 0
    
    /// 已发送的数据长度
    public var  sendDataIndex : Int = 0
    
    /// 发送状态
    public var  sendState : SendState = .sendEnd
    
    /// 读取状态
    public var  readState : ReadState = .readEnd
    
    /// 结束符设置
    public var  endFlag : String = "EOM"
    
    /// 设置单次最大传输量
    public var  maxBuffer : Int = 20
    
    
    /// 信号址设置
    public var maxRSSI : Int = -15
    public var minRSSI : Int = -35
    
}


