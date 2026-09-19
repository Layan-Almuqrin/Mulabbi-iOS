//
//  MulabbiApp.swift
//  Mulabbi
//
//  Created by Layan Almuqrin on 03/04/1448 AH.
//

import SwiftUI
import FirebaseCore

@main
struct MulabbiApp: App {
    
    init(){
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
