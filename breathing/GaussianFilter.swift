//
//  GaussianFilter.swift
//  breathing
//
//

import AVFoundation  // Import AVFoundation framework for handling audiovisual media
import UIKit         // Import UIKit framework for UI-related functionality

// A class to apply a Gaussian blur filter to depth images
class GaussianFilter {
    
    // MARK: - Apply Gaussian Filter
    // Function to apply a Gaussian blur filter to a depth image and return the filtered result
    func applyGaussianFilter(depthImage: CVPixelBuffer) -> CVPixelBuffer? {
        // Get the width of the input depth image
        let width = CVPixelBufferGetWidth(depthImage)
        // Get the height of the input depth image
        let height = CVPixelBufferGetHeight(depthImage)

        // Lock the base address of the input depth image for reading
        CVPixelBufferLockBaseAddress(depthImage, .readOnly)
        // Ensure the base address is unlocked when the function exits
        defer { CVPixelBufferUnlockBaseAddress(depthImage, .readOnly) }

        // Create a Core Image CIImage object from the input pixel buffer
        let ciImage = CIImage(cvPixelBuffer: depthImage)

        // Create a Gaussian blur filter
        let gaussianFilter = CIFilter(name: "CIGaussianBlur")
        // Set the input image for the filter
        gaussianFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        // Set the blur radius to 8.0 (adjustable as needed)
        gaussianFilter?.setValue(8.0, forKey: kCIInputRadiusKey)  // Radius set to 8, can be modified

        // Retrieve the filtered output image, or return nil if it fails
        guard let outputImage = gaussianFilter?.outputImage else {
            print("Gaussian filter failed")
            return nil
        }

        // Declare a variable to hold the output pixel buffer
        var outputPixelBuffer: CVPixelBuffer?
        // Create a new pixel buffer to store the filtered result
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         CVPixelBufferGetPixelFormatType(depthImage),
                                         nil,
                                         &outputPixelBuffer)

        // Check if the pixel buffer creation was successful
        if status != kCVReturnSuccess {
            print("Failed to create pixel buffer")
            return nil
        }

        // Create a CIContext for rendering the processed CIImage
        let context = CIContext(options: nil)
        // Render the filtered output image into the new pixel buffer
        context.render(outputImage, to: outputPixelBuffer!)

        // Return the filtered pixel buffer
        return outputPixelBuffer
    }
}
