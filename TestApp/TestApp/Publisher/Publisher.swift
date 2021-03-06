//
//  Publisher.swift
//  TestApp
//
//  Created by Akram Hussein on 17/12/2016.
//  Copyright (c) 2016 deepstreamHub GmbH. All rights reserved.
//

import Foundation

final public class Publisher {
    
    init() {
        let authData = ["username" : "Publisher"]
    
        guard let client = DSDeepstreamClient("0.0.0.0:6020") else {
            print("Publisher: Unable to initialize client")
            return
        }
        
        self.subscribeConnectionChanges(client: client)
        self.subscribeRuntimeErrors(client: client)
        
        guard let loginResult = client.login(authData.jsonElement) else {
            print("Publisher: Failed to login")
            return
        }
        
        if (!loginResult.loggedIn()) {
            print("Publisher: Provider Failed to login \(loginResult.getErrorEvent())")
        } else {
            print("Publisher: Provider Login Success")
            self.listenEvent(client: client)
            self.listenRecord(client: client)
            self.provideRpc(client: client)
            //self.updateRecordWithAck(recordName: "testRecord", client: client)
        }
    }
    
    private func listenRecord(client: DSDeepstreamClient) {
        let record = client.record
        
        let handler = PublisherListenListener(handler: { (subscription, client) in
            self.updateRecord(subscription: subscription, client: client)
        }, client: client)
        
        record.listen("record/.*", listenCallback: handler)
    }
    
    private func updateRecord(subscription: String, client: DSDeepstreamClient) {
        DispatchQueue.main.async {
            var count = 0
            let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
                let timeInterval : TimeInterval = Date().timeIntervalSince1970
                let data : [String : Any] = [
                    "timer" : timeInterval,
                    "id" : subscription,
                    "count" : count
                ]
                count += 1
                print("Publisher: Setting record \(data)")
                client.record.getRecord(subscription)!.set(data.jsonElement)
            }
            RunLoop.current.add(timer, forMode: RunLoopMode.commonModes)
            timer.fire()
        }
    }
    
cgetent    private func listenEvent(client: DSDeepstreamClient) {
        client.event.listen("event/.*",
                            listenListener: PublisherListenListener(handler: { (subscription, client) in
                                print("Publisher: Event \(subscription) just subscribed.")
                                self.publishEvent(subscription: subscription, client: client)
                             }, client: client))
    }

    
    private func publishEvent(subscription: String, client: DSDeepstreamClient) {
        DispatchQueue.main.async {
            let timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { timer in
                let timeInterval : TimeInterval = Date().timeIntervalSince1970
                let data : [Any] = ["An event just happened", timeInterval]
                print("Publisher: Emitting event \(data)")
                client.event.emit(subscription, data: data.jsonElement)
            }
            RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
            timer.fire()
        }
    }

    private func provideRpc(client: DSDeepstreamClient) {
        typealias PublisherRpcRequestedListenerHandler = ((String, Any, DSRpcResponse) -> Void)
        
        final class PublisherRpcRequestedListener : NSObject, DSRpcRequestedListener {
            private var handler : PublisherRpcRequestedListenerHandler!
            
            init(handler: @escaping PublisherRpcRequestedListenerHandler) {
                self.handler = handler
            }
            
            func onRPCRequested(_ rpcName: String!, data: Any!, response: DSRpcResponse!) {
                self.handler(rpcName, data, response)
            }
        }
        
        client.rpc.provide("add-numbers",
                            rpcRequestedListener: PublisherRpcRequestedListener { (rpcName, data, response) in
                                print("Publisher: Got an RPC request")
                                
                                guard let numbers = (data as? GSONJsonArray)?.array as? [Double] else {
                                    print("Publisher: Unable to cast data to Array")
                                    return
                                }

                                if (numbers.count < 2) { return }
                                
                                let random = (Double(arc4random()) / Double(UInt32.max))
                                switch (random) {
                                case 0..<0.2:
                                    response.reject()
                                case 0..<0.7:
                                    let value = numbers[0] + numbers[1]
                                    response.send(value)
                                default:
                                    print("Publisher: This intentionally randomly failed")
                                }
        })
    }
    
    private func subscribeRuntimeErrors(client: DSDeepstreamClient) {
        client.setRuntimeErrorHandler(RuntimeErrorHandler())
    }
    
    private func subscribeConnectionChanges(client: DSDeepstreamClient) {
        client.addConnectionChange(AppConnectionStateListener())
    }

    private func updateRecordWithAck(recordName: String, client: DSDeepstreamClient) {
        guard let record = client.record.getRecord(recordName) else {
            print("Publisher: No record name \(recordName)")
            return
        }
    
        guard let result = record.setWithAck("number", value: 2) else {
            print("Publisher: No result")
            return
        }
        
        let error = result.getResult()
        if (error == nil) {
            print("Record set successfully with ack")
        } else {
            print("Record wasn't able to be set, error: \(error)")
        }
    }
}
