//
//  BTLEPeripheralViewController.swift
//  BTLESwiftDemo
//
//  Created by 德志 on 2018/1/6.
//  Copyright © 2018年 com.aiiage.www. All rights reserved.
//

import UIKit
import SnapKit
import Result
import ReactiveSwift
import ReactiveCocoa
import CoreBluetooth

class BTLEPeripheralViewController: UIViewController,CBPeripheralManagerDelegate {

    // MARK:- UI属性
    // 发送msg输入框
    let  sendMsgTextFile = UITextField()

    //消息发送按钮
    let sendMsgButton = UIButton()

    //重新扫描
    let  scanButton = UIButton()

    //读取msg文本框
    let  readMsgLabel = UILabel()

    // MARK:- 服务属性
    //外设管理
    lazy var  peripheralManager :CBPeripheralManager =  CBPeripheralManager(delegate:self, queue:nil)
    //外设服务特征
    var  transferCharacteristic : CBMutableCharacteristic?

    var  transferService : CBMutableService?


    override func viewDidLoad() {
        super.viewDidLoad()
        title = "BTLECentral"
        view.backgroundColor = UIColor.white

        //添加UI
        view.addSubview(scanButton)
        view.addSubview(sendMsgTextFile)
        view.addSubview(sendMsgButton)
        view.addSubview(readMsgLabel)

        //布局UI
        serupUI()

        creatBTLPeripheralServer()

    }


    func serupUI() {
        sendMsgTextFile.snp.makeConstraints { (make) in
            make.height.equalTo(200)
            make.trailing.leading.equalToSuperview()
            make.top.equalToSuperview()
        }

        scanButton.snp.makeConstraints { (make) in
            make.height.equalTo(44)
            make.top.equalTo(sendMsgTextFile.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }

        sendMsgButton.snp.makeConstraints { (make) in
            make.height.equalTo(44)
             make.top.equalTo(sendMsgTextFile.snp.bottom).offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }

        readMsgLabel.snp.makeConstraints { (make) in
            make.top.equalTo(sendMsgButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
        }

        sendMsgTextFile.placeholder = "请输入需要发送的数据"
        sendMsgTextFile.textColor = UIColor.red
        sendMsgTextFile.font = UIFont.systemFont(ofSize:16)

        //扫描
        sendMsgButton.setTitle("扫描", for: UIControlState.normal)
        sendMsgButton.titleLabel?.font = UIFont.systemFont(ofSize:16)
        sendMsgButton.setTitleColor(UIColor.red, for: UIControlState.normal)
        scanButton.reactive.controlEvents(UIControlEvents.touchUpInside).observeValues { ( _ ) in

        }

        sendMsgButton.setTitle("发送", for: UIControlState.normal)
        sendMsgButton.titleLabel?.font = UIFont.systemFont(ofSize:16)
        sendMsgButton.setTitleColor(UIColor.red, for: UIControlState.normal)
        sendMsgButton.reactive.controlEvents(.touchUpInside).observeValues {  ( _ ) in

        }

        readMsgLabel.textColor = UIColor.blue
        readMsgLabel.numberOfLines = 0
        readMsgLabel.font = UIFont.systemFont(ofSize:16)
        readMsgLabel.text = "读取到的消息为"
    }

    func creatBTLPeripheralServer() {
        _ = self.peripheralManager
    }


    deinit {
        peripheralManager.stopAdvertising()
    }
}


//MARK:- CBPeripheralManagerDelegate
extension BTLEPeripheralViewController {

    //  检测到设备状态发生更新 重新设置外围设备(其实它才是真的服务器)
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {

        guard peripheral.state == .poweredOn else {
            return
        }

        //特征ID
        let characteristicID  = CBUUID(string: AppDefine.characteristicID)
        let properties = UInt8(CBCharacteristicProperties.read.rawValue) | UInt8(CBCharacteristicProperties.write.rawValue) | UInt8(CBCharacteristicProperties.notify.rawValue)
        let permissions = UInt8(CBAttributePermissions.readable.rawValue) | UInt8(CBAttributePermissions.writeable.rawValue)
        //初始化特征 可以多个
        transferCharacteristic = CBMutableCharacteristic(type:characteristicID, properties: CBCharacteristicProperties(rawValue: CBCharacteristicProperties.RawValue(properties)), value:nil, permissions: CBAttributePermissions(rawValue: CBAttributePermissions.RawValue(permissions)))

        //初始化服务 可设置多个 服务Id
        let serverUUID = CBUUID(string:AppDefine.serverUUID)
        transferService = CBMutableService(type: serverUUID, primary: true)

        //添加特征到服务
        transferService?.characteristics = [transferCharacteristic!]

        //将服务添加到设备管理
        peripheralManager.add(transferService!)

    }


    //开始广播 服务开启
    public func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print(error)
       print( peripheralManager.isAdvertising)
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print(error)
        peripheral.startAdvertising([CBAdvertisementDataServiceUUIDsKey:[service.uuid]])

    }



    //订阅特征服务 成功
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
            debugPrint("连接成功")

        //发送数据到客户端
      let isoK =  peripheral.updateValue("连接成功".data(using:String.Encoding.utf8)!, for:transferCharacteristic!, onSubscribedCentrals: nil)
    }

    //订阅特征服务 失败
    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("shibai")

    }

    // 读取服务器（外围设备）请求  当用户中心调取特征读取方法的时候  外围设备就会执行这个函数 发送数据给用户客户端
    // (这个需要注意的是 在配置transferCharacteristic 特征服务 初始化的时候需要 配置添加read  write writeWithoutResponse
    //  notify 不然下面的代理  didReceiveRead  didReceiveWrite 不会调取
    //  let properties = UInt8(CBCharacteristicProperties.read.rawValue) | UInt8(CBCharacteristicProperties.write.rawValue) | UInt8(CBCharacteristicProperties.notify.rawValue) | UInt8(CBCharacteristicProperties.writeWithoutResponse.rawValue))

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        //客户端需要读取数据  写图数据到客户端
        let isoK = peripheral.updateValue("返回需要读取的数据".data(using: String.Encoding.utf8)!, for:transferCharacteristic!, onSubscribedCentrals:nil )

    }



    // 写入服务器（外围设备）请求  当用户中心调取写入数据到外围设备  外围设备就会执行这个函数 获得写入的数据
    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        //客服端写入数据到 到外设 服务器
        debugPrint("读取写入的数据 === \(String(describing: requests.first?.value))")

    }

    // ok
    public func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        peripheral.updateValue("返回需要读取的数据".data(using: String.Encoding.utf8)!, for:transferCharacteristic!, onSubscribedCentrals:nil )
    }

}
