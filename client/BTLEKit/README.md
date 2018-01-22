# BTLEKit

[![CI Status][image-1]][1]
[![Version][image-2]][2]
[![License][image-3]][3]
[![Platform][image-4]][4]

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

BTLEKit is available through [CocoaPods][5]. To install
it, simply add the following line to your Podfile:

```ruby
pod 'BTLEKit'
```

## Author

Sico2Sico, wu.dz@aiiage.com

## 使用说明

. 需要实现 BTManagerProtocol 协议 
	class ViewController: UIViewController,BTManagerProtocol {
	    func writeError() {
	        print("写入错误")
	    }
	
	    func writSuccess() {
	        print("写入成功")
	    }
	
	    func readError() {
	        print("读取错误")
	    }
	
	    func readSussces(data: Data, type: DataType) {
	
	        print(String.init(data: data, encoding: String.Encoding.utf8))
	
	    }

 . 初始化设置 设置实现协议的作为manager.delegate
	       manager = BTCentralManager.instance
	        manager.delegate = self
	        manager.startConnect(serverID:"E20A39F4-73F5-4BC4-A12F-17D1AD07A961", characteristicID:"08590F7E-DB05-467E-8757-72F6FAEB13D4")
	

. 写入数据
	manager.writeMsg(data:"wudezhi".data(using: String.Encoding.utf8)!, type:DataType.text)
	

## License

BTLEKit is available under the MIT license. See the LICENSE file for more info.

[1]:	https://travis-ci.org/Sico2Sico/BTLEKit
[2]:	http://cocoapods.org/pods/BTLEKit
[3]:	http://cocoapods.org/pods/BTLEKit
[4]:	http://cocoapods.org/pods/BTLEKit
[5]:	http://cocoapods.org

[image-1]:	http://img.shields.io/travis/Sico2Sico/BTLEKit.svg?style=flat
[image-2]:	https://img.shields.io/cocoapods/v/BTLEKit.svg?style=flat
[image-3]:	https://img.shields.io/cocoapods/l/BTLEKit.svg?style=flat
[image-4]:	https://img.shields.io/cocoapods/p/BTLEKit.svg?style=flat