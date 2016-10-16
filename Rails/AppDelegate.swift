//
//  AppDelegate.swift
//  Rails
//
//  Created by 胡 桓铭 on 2016/10/10.
//  Copyright © 2016年 胡 桓铭. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system().statusItem(withLength: -2)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.activate(ignoringOtherApps: true)
        
        if let button = statusItem.button {
            button.image = NSImage(named: "Tray")
        }
        
        let menu = NSMenu()
        statusItem.menu = menu
        
        
        var pidMenuItems = Dictionary<String, NSMenuItem>()
        var nameItems = Dictionary<String, NSMenuItem>()
        var pidApps = Dictionary<String, NSRunningApplication>()
        
        let apps = NSWorkspace.shared().runningApplications
        
        

        for app in apps {
            let menuItem = NSMenuItem()
            menuItem.title = "\(app.localizedName!) ↑0M/0kb/s  ↓0M/0kb/s"
            menuItem.image = app.icon
            menuItem.target = self
            menuItem.action = #selector(clickMenuItem(sender:))
            menuItem.identifier = app.bundleURL?.absoluteString
            menu.addItem(menuItem)
            
            pidMenuItems[String(app.processIdentifier)] = menuItem
            nameItems[app.localizedName!] = menuItem
            pidApps[String(app.processIdentifier)] = app
        }
        
        
        
        
        DispatchQueue.global(qos: .background).async {
            var last_date = Date()
            while true {
                let current_date = Date()
                let dataLines = self.readNettop()
                for dataline in dataLines {
                    if dataline.count < 1 {
                        continue
                    }
                    let menuItem = pidMenuItems[dataline.last!]
                    let app = pidApps[dataline.last!]
                    DispatchQueue.main.async {
                        menuItem?.title = "\(app?.localizedName!) ↑\(dataline[5])/0kb/s  ↓\(dataline[4])/0kb/s"
                    }
                }
                last_date = current_date
                sleep(1)
            }
        }
    }

    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func clickMenuItem(sender: NSMenuItem) {
        NSWorkspace.shared().open(URL(string: sender.identifier ?? "")!)
    }
    
    func readNettop()->[[String]] {
        // Create a Task instance (was NSTask on swift pre 3.0)
        let task = Process()
        
        // Set the task parameters
        task.launchPath = "/usr/bin/nettop"
        task.arguments = ["-L1"]
        
        // Create a Pipe and make the task
        // put all the output there
        let pipe = Pipe()
        task.standardOutput = pipe
        
        // Launch the task
        task.launch()
        
        // Get the data

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        
        // "time,,interface,state,bytes_in,bytes_out,rx_dupe,rx_ooo,re-tx,rtt_avg,rcvsize,tx_win,tc_class,tc_mgt,cc_algo,P,C,R,W,"
        var lines:[String] = (output?.components(separatedBy: "\n"))!

        lines.removeFirst()
        
        return lines.map({ (s: String) -> [String] in
            if s.characters.count < 2 {
                return []
            }
            var vals:[String] = s.components(separatedBy: ",")
            vals.append(vals[1].components(separatedBy: ".").last!)
            return vals
        })
    }
}

