//
//  DerootifierApp.swift
//  Derootifier
//
//  Created by Анохин Юрий on 15.04.2023.
//

import SwiftUI

@main
struct DerootifierBinary {
    static func main() {
        if CommandLine.arguments.count >= 2 {
            exit(PatcherMain())
        } else {
            DerootifierApp.main()
        }
    }
}

struct DerootifierApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
