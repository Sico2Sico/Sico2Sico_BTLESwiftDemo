//
//  BTManagerProtocol.swift
//  BTLEKit
//
//  Created by 德志 on 2018/1/18.
//

import UIKit

public protocol BTManagerProtocol:class {
    
    var manager : BTCentralManager! {get set}
    
    func  writeError()
    
    func  writSuccess()
    
    func  readError()
    
    func  readSussces(data:Data,type:DataType)

}


//后续如果不强制 可以直接打开
//extension BTManagerProtocol {
//    
//    func  writeError(){}
//    
//    func  writSuccess(){}
//    
//    func  readError(){}
//    
//    func  readSussces(data:Data,type:DataType){}
//}
    

