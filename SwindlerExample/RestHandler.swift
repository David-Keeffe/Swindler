//
//  RestHandler.swift
//  SwindlerExample
//
//  Created by David Keeffe on 06/08/2020.
//  Copyright © 2020 Tyler Mandry. All rights reserved.
//

import Foundation
import Swifter

class RestHandler {
    var server: HttpServer
    var port: UInt16
    typealias Callback = (_ code: String) -> Bool
    
    init(port: UInt16) {
        self.server = HttpServer()
        self.server.listenAddressIPv4 = "127.0.0.1"
        self.port = port
    }
    
    func addhandler(key: String, handler: @escaping Callback) {
        print("ADD HANDLER: \(key) with \(String(describing: handler))")
        self.server[key] = { request in
            print("GOT \(key) \(request.queryParams)")
            let code: String? = request.queryParams.filter({ $0.0 == "code"}).first?.1
            var xx: Bool = false
            if let xcode = code {
                xx = handler(xcode)
            } else {
                xx = handler("")
            }
            
            return HttpResponse.ok(.text("<h1>\(xx)</h1>"))
        }
    }
    
    func start() {
        try! self.server.start(self.port)
    }

}
