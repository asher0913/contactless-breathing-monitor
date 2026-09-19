//
//  CameraSetUp.swift
//  breathing
//
//

import AVFoundation  // Import AVFoundation framework for camera and media handling
import UIKit         // Import UIKit framework for UI-related functionality

// MARK: - CameraSetupDelegate
// Protocol defining delegate methods for handling captured video frames and depth data
protocol CameraSetupDelegate: AnyObject {
    // Called when a video frame is captured
    func didCaptureVideoFrame(_ sampleBuffer: CMSampleBuffer)
    // Called when depth data is captured
    func didCaptureDepthData(_ depthData: AVDepthData)
}

// Class to manage camera setup and capture for both video and depth data
class CameraSetup: NSObject {
    // Capture session for managing multiple camera inputs and outputs
    var captureSession: AVCaptureMultiCamSession!
    // Layer to display the camera preview
    var previewLayer: AVCaptureVideoPreviewLayer!
    // Output object for depth data
    var depthOutput: AVCaptureDepthDataOutput!
    // Output object for video data
    var videoDataOutput: AVCaptureVideoDataOutput!
    
    // Weak reference to the delegate to avoid retain cycles
    weak var delegate: CameraSetupDelegate?
    
    // MARK: - Setup Camera
    // Function to configure and start the camera session for a given view controller
    func setupCamera(for viewController: UIViewController) {
        // Check if the device supports multi-camera sessions
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            print("Device does not support multi-camera session")
            return
        }
        
        // Initialize the multi-camera capture session
        captureSession = AVCaptureMultiCamSession()
        
        // Configure the depth camera input and output
        configureDepthCamera()
        
        // Configure the regular video camera input and output
        configureVideoCamera(viewController: viewController)
        
        // Start the capture session to begin capturing data
        captureSession.startRunning()
    }
    
    // MARK: - Configure Depth Camera
    // Private function to set up the depth camera (TrueDepth camera)
    private func configureDepthCamera() {
        // Attempt to get the front-facing TrueDepth camera
        guard let depthDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) else {
            print("Depth camera not found")
            return
        }
        
        do {
            // Create an input for the depth camera device
            let depthInput = try AVCaptureDeviceInput(device: depthDevice)
            // Add the depth input to the session if possible
            if captureSession.canAddInput(depthInput) {
                captureSession.addInput(depthInput)
                print("Depth camera added successfully")
            }
            
            // Initialize the depth data output
            depthOutput = AVCaptureDepthDataOutput()
            // Add the depth output to the session if possible
            if captureSession.canAddOutput(depthOutput) {
                captureSession.addOutput(depthOutput)
                // Set this class as the delegate for depth data, using the main queue
                depthOutput.setDelegate(self, callbackQueue: DispatchQueue.main)
                print("Depth camera output added successfully")
            }
        } catch {
            // Handle any errors that occur during depth camera setup
            print("Error setting up depth camera: \(error)")
        }
    }
    
    // MARK: - Configure Video Camera
    // Private function to set up the regular video camera (wide-angle camera)
    private func configureVideoCamera(viewController: UIViewController) {
        // Attempt to get the front-facing wide-angle camera
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Video camera not found")
            return
        }
        
        do {
            // Create an input for the video camera device
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            // Add the video input to the session if possible
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                print("Video camera added successfully")
            }
            
            // Initialize the video data output
            videoDataOutput = AVCaptureVideoDataOutput()
            // Add the video output to the session if possible
            if captureSession.canAddOutput(videoDataOutput) {
                captureSession.addOutput(videoDataOutput)
                // Set this class as the delegate for video data, using the main queue
                videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
                
                // Create and configure a preview layer for displaying the camera feed
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                // Set the preview layer's frame to match the view controller's bounds
                previewLayer.frame = viewController.view.bounds
                // Configure the preview layer to fill the frame while preserving aspect ratio
                previewLayer.videoGravity = .resizeAspectFill
                // Add the preview layer to the view controller's view hierarchy
                viewController.view.layer.addSublayer(previewLayer)
            }
        } catch {
            // Handle any errors that occur during video camera setup
            print("Error setting up video camera: \(error)")
        }
    }
    
    // Function to stop the capture session and halt data capturing
    func stopCapturing() {
        // Stop the running capture session
        captureSession.stopRunning()
    }
    
}

// MARK: - AVCaptureDepthDataOutputDelegate
// Extension to handle depth data output delegate methods
extension CameraSetup: AVCaptureDepthDataOutputDelegate {
    // Delegate method called when depth data is output
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        // Notify the delegate with the captured depth data
        delegate?.didCaptureDepthData(depthData)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
// Extension to handle video data output delegate methods
extension CameraSetup: AVCaptureVideoDataOutputSampleBufferDelegate {
    // Delegate method called when a video frame is output
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Notify the delegate with the captured video frame
        delegate?.didCaptureVideoFrame(sampleBuffer)
    }
}
