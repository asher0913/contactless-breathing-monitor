//
//  breathingApp.swift
//  breathing
//
//

import SwiftUI  // Import the SwiftUI framework for building the user interface

// Define the main entry point of the application, conforming to the App protocol
@main
struct breathingApp: App {
    // The body property defines the scene structure of the app
    var body: some Scene {
        // Create a WindowGroup scene, which manages a group of windows for the app
        WindowGroup {
            // Set TestView as the root view of the application
            ContentView()
        }
    }
}
