//
//  ViewController.swift
//  BTLEKit
//
//  Created by Sico2Sico on 01/15/2018.
//  Copyright (c) 2018 Sico2Sico. All rights reserved.
//

import UIKit
import BTLEKit
import CryptoSwift

class ViewController: UIViewController,BTManagerProtocol {
    func writeError() {

    }

    func writSuccess() {

    }

    func readError() {

    }

    func readSussces(data: Data, type: DataType) {

    }


    
    var manager: BTCentralManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = BTCentralManager.instance
        manager.delegate = self
        manager.startConnect(serverID:"E20A39F4-73F5-4BC4-A12F-17D1AD07A961", characteristicID:"08590F7E-DB05-467E-8757-72F6FAEB13D4")
    }
    


    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        manager.writeMsg(data:"wudezhi".data(using: String.Encoding.utf8)!, type:DataType.text)
    }
    
}

