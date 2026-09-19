//
//  PixelBufferCropper.swift
//  breathing
//
//

import AVFoundation  // Import AVFoundation framework for handling audiovisual media
import UIKit         // Import UIKit framework for UI-related functionality

// A class to crop a CVPixelBuffer to a specified rectangular region
class PixelBufferCropper {
    
    // MARK: - Method to Crop CVPixelBuffer
    // Function to crop a pixel buffer to a given rectangle and return the cropped result
    func cropPixelBuffer(_ pixelBuffer: CVPixelBuffer, rect: CGRect) -> CVPixelBuffer? {
        // Get the width of the original pixel buffer
        let width = CVPixelBufferGetWidth(pixelBuffer)
        // Get the height of the original pixel buffer
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        // Ensure the cropping rectangle is within the bounds of the original image
        let croppedRect = rect.intersection(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        
        // Return nil if the cropping rectangle is empty
        if croppedRect.isEmpty {
            print("Cropping region is empty")
            return nil
        }
        
        // Declare a variable to hold the new cropped pixel buffer
        var croppedPixelBuffer: CVPixelBuffer?
        // Create a new CVPixelBuffer to store the cropped image data
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(croppedRect.width),
                                         Int(croppedRect.height),
                                         CVPixelBufferGetPixelFormatType(pixelBuffer),
                                         nil,
                                         &croppedPixelBuffer)
        
        // Check if the pixel buffer creation was successful and unwrap the result
        guard status == kCVReturnSuccess, let newPixelBuffer = croppedPixelBuffer else {
            print("Failed to create new pixel buffer")
            return nil
        }
        
        // Lock the base addresses of the original and cropped pixel buffers for reading
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        CVPixelBufferLockBaseAddress(newPixelBuffer, .readOnly)
        
        // Ensure the base addresses are unlocked when the function exits
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            CVPixelBufferUnlockBaseAddress(newPixelBuffer, .readOnly)
        }
        
        // Get the base address of the original pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!
        // Get the number of bytes per row in the original pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        // Get the base address of the cropped pixel buffer
        let newBaseAddress = CVPixelBufferGetBaseAddress(newPixelBuffer)!
        // Get the number of bytes per row in the cropped pixel buffer
        let newBytesPerRow = CVPixelBufferGetBytesPerRow(newPixelBuffer)
        
        // Calculate the starting position of the cropping region in the original image
        let startX = Int(croppedRect.origin.x)
        let startY = Int(croppedRect.origin.y)

        // Perform the cropping operation row by row
        for y in 0..<Int(croppedRect.height) {
            // Calculate the pointer to the current row in the original pixel buffer
            let originalRowPointer = baseAddress + (startY + y) * bytesPerRow
            // Calculate the pointer to the current row in the cropped pixel buffer
            let newRowPointer = newBaseAddress + y * newBytesPerRow
            
            // Copy the pixel data for the current row from the original to the cropped buffer
            memcpy(newRowPointer, originalRowPointer + startX * MemoryLayout<UInt8>.size, Int(croppedRect.width) * MemoryLayout<UInt8>.size)
        }
        
        // Return the cropped pixel buffer
        return newPixelBuffer
    }
}
