//
//  AppDelegate.swift
//  SwindlerExample
//
//  Created by Tyler Mandry on 10/20/15.
//  Copyright © 2015 Tyler Mandry. All rights reserved.
//

import AXSwift
import Cocoa
import Network
import PromiseKit
import Swindler

func dispatchAfter(delay: TimeInterval, block: DispatchWorkItem) {
    let time = DispatchTime.now() + delay
    DispatchQueue.main.asyncAfter(deadline: time, execute: block)
}

let keymap: [String: UInt16] = [
    "0": 0x1d,
    "1": 0x12,
    "2": 0x13,
    "3": 0x14,
    "4": 0x15,
    "5": 0x16,
    "6": 0x17,
    "7": 0x1a,
    "8": 0x1c,
    "9": 0x19
]

class AppDelegate: NSObject, NSApplicationDelegate {
    var swindler: Swindler.State!
    var finale: AXSwift.Application?
    var httpserver: RestHandler!
    var keyseq: String?
    var triggered: Bool = false
    
    func clickItem(app: UIElement, name: String, code: String) {
        let menubar: UIElement = try! app.attribute(.menuBar)!
        // let menubar: UIElement = menubar_attr!.value as! UIElement
        //NSLog("Menu Bar \(menubar)")
       
        let mitems: [AXUIElement] = try! menubar.attribute(.children)!
       
        //NSLog("Menu XXX \(mitems)")
       
        let uilist = mitems
        //NSLog("ATTRS \(uilist)")
       
        for uie_x in uilist {
            let uie = UIElement(uie_x)
            let vxvx: NSString = try! uie.attribute(.title)!
           
            if vxvx.isEqual(to: "Plug-ins") {
                print("Plugins Element: \(uie)")
                //NSLog("Plugins title \(vxvx)")
                // get the menu under plugins
                let muilist_x: [AXUIElement] = try! uie.attribute(.children)!
                let themenu: UIElement = UIElement(muilist_x.first!)
               
                // print("MENU MEMBERS: \(themenu)")
           
                // get member of menu members
                let muimembers: [AXUIElement] = try! themenu.attribute(.children)!
                // print("MENU MEMBERS 2: \(muimembers)")
               
                for mum_x in muimembers {
                    let mum: UIElement = UIElement(mum_x)
                    let mxvx: String = try! mum.attribute(.title)!
                    // print("Plugin member: \(mxvx)")
                    if mxvx.isEqual("JW Lua") {
                        // print("MENU ELEMENT 3: \(mvvx)")
                        //print("JW Lua Element: \(mxvx)")
                        let mum_menu_x: [AXUIElement] = try! mum.attribute(.children)!
                        let mum_menu: UIElement = UIElement(mum_menu_x.first!)
                       
                        //print("JW Lua Menu: \(mum_menu)")
                        // get menu members
                        let mum_members: [AXUIElement] = try! mum_menu.attribute(.children)!
                        //print("JW Lua Menu MEMBERS: \(mum_members)")
                       
                        for lua_x in mum_members {
                            let lua = UIElement(lua_x)
                            let luas: NSString = try! lua.attribute(.title)!
                            //print("LUA \(luas)")
                            if luas.isEqual("JetStream Finale Controller") {
                                //print("MENU ITEM ATTR: \(try! lua.attributes())")
                                keyseq = code
                                try! lua.performAction(.pick)
                                wait()
                                usleep(50000)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func doBox(app: AXSwift.Application, code: String) {
        if !self.triggered {
            return
        }
        let luawx: UIElement = try! app.attribute(.focusedWindow)!
        let actions = try! luawx.actionsAsStrings()
        //print("ACTIONS \(actions)")
        //print("WIN XX ATTR: \(try! luawx.attributes())")
        // try! luawx.performAction(.raise)
        try! luawx.setAttribute(.focused, value: true)
        let muw_members: [AXUIElement] = try! luawx.attribute(.children)!
        //print("WIN XX MEMBERS: \(muw_members)")
        var okbutton: UIElement = luawx
        var cancelbutton: UIElement = luawx
        for mem_x in muw_members {
            //print("MEMBER \(mem_x)")
            let mem: UIElement? = UIElement(mem_x)
            
            if let xmem = mem {
                do {
                    if try! xmem.attributeIsSupported(.title) {
                        let wtitle: String? = try xmem.attribute(.title)
                        if let xtitle = wtitle {
                            if xtitle.isEqual("OK") {
                                print("FOUND OK")
                                okbutton = xmem
                            } else if xtitle.isEqual("Cancel") {
                                print("FOUND Cancel")
                                cancelbutton = xmem
                            }
                        }
                    }
                } catch {}
            }
        }
        // wait()
        // usleep(200000)
        if code.count == 4 {
            for cc in code {
                let kc: UInt16 = keymap[String(cc)]!
                let keydownevent = CGEvent(keyboardEventSource: nil, virtualKey: kc, keyDown: true)!
                let keyupevent = CGEvent(keyboardEventSource: nil, virtualKey: kc, keyDown: false)!
                keydownevent.post(tap: .cghidEventTap)
                keyupevent.post(tap: .cghidEventTap)
            }
                
            // keyRETupevent.post(tap:.cghidEventTap)
            // keyRETdownevent.post(tap:.cghidEventTap)
            // try! luawx.performAction(.cancel)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                try! okbutton.performAction(.press)
                self.triggered = false
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                try! cancelbutton.performAction(.press)
                self.triggered = false
            }
        }
        
        // break
    }
                                   
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard AXSwift.checkIsProcessTrusted(prompt: true) else {
            print("Not trusted as an AX process; please authorize and re-launch")
            NSApp.terminate(self)
            return
        }

        Swindler.initialize().done { state in
            self.swindler = state
            self.setupEventHandlers()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // your function here
                // check for Finale
                self.finale = Application.allForBundleID("com.makemusic.Finale26").first
                print("APP ATTRS: \(try! self.finale?.attributes())")
                try! self.finale?.setAttribute(.frontmost, value: true)
                // self.clickItem(app: app, name: "JetStream Finale Controller")
            }
        }.catch { error in
            print("Fatal error: failed to initialize Swindler: \(error)")
            NSApp.terminate(self)
        }
    }

    private func setupEventHandlers() {
        print("screens: \(swindler.screens)")
        
        swindler.on { (event: WindowCreatedEvent) in
            let window = event.window
            print("new window: \(window.title.value)")
        }
        swindler.on { (event: WindowFrameChangedEvent) in
            print("Frame changed from \(event.oldValue) to \(event.newValue),",
                  "external: \(event.external)")
        }
        swindler.on { (event: WindowDestroyedEvent) in
            print("window destroyed: \(event.window.title.value)")
        }
        swindler.on { (event: ApplicationMainWindowChangedEvent) in
            print("new main window: \(String(describing: event.newValue?.title.value)).",
                  "[old: \(String(describing: event.oldValue?.title.value))]")
            self.frontmostWindowChanged()
        }
        swindler.on { (event: FrontmostApplicationChangedEvent) in
            let bundle = event.newValue?.bundleIdentifier
            print("new frontmost app: \(event.newValue?.bundleIdentifier ?? "unknown").",
                  "[old: \(event.oldValue?.bundleIdentifier ?? "unknown")]")
            
            
            if let xbundle = bundle {
                if xbundle.isEqual("com.makemusic.Finale26") {
                    // self.clickItem(app: self.finale, name: "JetStream Finale Controller")
                    self.finale = Application.allForBundleID("com.makemusic.Finale26").first
                    print("NEW APP ATTRS: \(try! self.finale?.attributes())")
                    try! self.finale?.setAttribute(.frontmost, value: true)
                }
            }
            
            self.frontmostWindowChanged()
        }
        
        httpserver = RestHandler(port: 8765)
        httpserver.addhandler(key: "/fred") {
            code in
            if let xapp = self.finale {
                self.triggered = true
                self.clickItem(app: xapp, name: "JetStream Finale Controller", code: code)
                return true
            } else {
                return false
            }
        }
        httpserver.addhandler(key: "/dolua") {
            code in
            if let xapp = self.finale {
                self.triggered = true
                self.clickItem(app: xapp, name: "JetStream Finale Controller", code: code)
                return true
            } else {
                return false
            }
        }
        httpserver.addhandler(key: "/focus") {
            _ in
            try! self.finale?.setAttribute(.frontmost, value: true)
            return true
        }
        httpserver.start()
    }

    private func frontmostWindowChanged() {
        let window = swindler.frontmostApplication.value?.mainWindow.value
        let wtitle = window?.title.value
        print("new frontmost window: \(String(describing: wtitle))")
        if let xwtitle = wtitle, let xapp = self.finale, let xcode = self.keyseq {
            if xwtitle.isEqual("JetStream Finale Controller") {
                print("FINALE: JW BOX!")
                if self.triggered {
                    doBox(app: xapp, code: xcode)
                    keyseq = nil
                }
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}
