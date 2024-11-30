//
//  PatcherMain.swift
//  Rootifier
//
//  Created by Nick Chan on 2024/11/30.
//

import Foundation

func PatcherMain() -> Int32 {
    let args = CommandLine.arguments

    if (args.count < 2) {
        return -1;
    }
    
    switch (args[1]) {
        case "patch":
        if (args.count != 3) {
            print("wrong number of arguments", args.count)
            
            return -1
        }
            
        return patcher((args[2] as NSString).utf8String)

        default:
            return -1
    }
}
