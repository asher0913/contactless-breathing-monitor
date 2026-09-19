//
//  CameraViewModel.swift
//  breathing
//
//
import Foundation  // Import Foundation framework for basic functionality like ObservableObject

// A view model to manage camera-related state, conforming to ObservableObject for SwiftUI updates
class CameraViewModel: ObservableObject {
    // Singleton instance for shared access across the app
    static let shared = CameraViewModel()

    // Published property to track whether shoulders are locked, triggering UI updates when changed
    @Published var isShoulderLocked: Bool = false // Observable state for shoulder lock status
}
