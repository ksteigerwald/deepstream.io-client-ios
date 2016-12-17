//
//  DeepstreamClient+Extensions.swift
//  TestApp
//
//  Created by Akram Hussein on 17/12/2016.
//
//

import Foundation

extension DeepstreamClient {
    // Needed as J2ObjC does not translate properties
    // Required explicit getters/setters in Java
    var record : RecordHandler? {
        get {
            return self.value(forKey: "record_") as? RecordHandler
        }
    }
    
    var event : EventHandler? {
        get {
            return self.value(forKey: "event_") as? EventHandler
        }
    }
    
    var rpc : RpcHandler? {
        get {
            return self.value(forKey: "rpc_") as? RpcHandler
        }
    }
}