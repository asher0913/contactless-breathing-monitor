//
//  HumanPoseEstimator.swift
//  breathing
//
//

import Vision        // Import Vision framework for image analysis and human pose detection
import AVFoundation  // Import AVFoundation framework for handling audiovisual media
import UIKit         // Import UIKit framework for UI-related functionality

// A class to estimate human pose from video frames and draw head and chest regions
class HumanPoseEstimator {
    // Request object for detecting human body pose
    var poseRequest: VNRequest!
    // The most recent human body pose observation
    var lastObservation: VNHumanBodyPoseObservation?
    // Default width of the camera resolution
    var cameraWidth: Int = 1440
    // Default height of the camera resolution
    var cameraHeight: Int = 1080
    
    // Layers for displaying head and chest regions on the UI
    private var headLayer: CALayer?
    private var chestLayer: CALayer?
    
    // Initializer to set up the human pose detection request
    init() {
        // Create a human body pose detection request
        let bodyPoseRequest = VNDetectHumanBodyPoseRequest { request, error in
            // Handle the results of the pose detection request
            if let results = request.results as? [VNHumanBodyPoseObservation], let firstObservation = results.first {
                // Store the first detected pose observation
                self.lastObservation = firstObservation
            } else {
                // Log an error or lack of detection
                print("No human pose detected or an error occurred: \(error?.localizedDescription ?? "No error message")")
            }
        }
        // Assign the request to the poseRequest property
        self.poseRequest = bodyPoseRequest
    }
    
    // Process a video frame to detect human pose and update the UI
    func processFrame(pixelBuffer: CVPixelBuffer, view: UIView) {
        // Create a sequence request handler for processing the frame
        let handler = VNSequenceRequestHandler()
        do {
            // Perform the pose detection request on the pixel buffer
            try handler.perform([self.poseRequest], on: pixelBuffer)
            // If a pose observation is available, draw the head and chest regions on the main thread
            if let observation = lastObservation {
                DispatchQueue.main.async {
                    self.drawHeadAndChestRegion(observation, view: view)
                }
            }
        } catch {
            // Log any errors that occur during the request
            print("Human pose estimation request failed: \(error)")
        }
    }
    
    // Draw head and chest regions based on pose observation
    private func drawHeadAndChestRegion(_ observation: VNHumanBodyPoseObservation, view: UIView) {
        // Retrieve key points for shoulders and nose
        guard let (leftShoulder, rightShoulder, nose) = getPoseKeyPoints(from: observation) else {
            print("Insufficient key points or confidence too low")
            return
        }

        // Calculate scaling factors based on the view dimensions
        let (scaleX, scaleY) = calculateScaleFactors(view: view)
        
        // Calculate the positions of key points in view coordinates
        let (leftShoulderX, leftShoulderY) = calculatePointPosition(point: leftShoulder, scaleX: scaleX, scaleY: scaleY)
        let (rightShoulderX, rightShoulderY) = calculatePointPosition(point: rightShoulder, scaleX: scaleX, scaleY: scaleY)
        let (noseX, noseY) = calculatePointPosition(point: nose, scaleX: scaleX, scaleY: scaleY)
        
        // Calculate the chest rectangle based on shoulder positions
        let chestRect = calculateChestRect(leftShoulderX: leftShoulderX, leftShoulderY: leftShoulderY,
                                           rightShoulderX: rightShoulderX, rightShoulderY: rightShoulderY)
        
        // Calculate the head rectangle based on nose position and chest width
        let headRect = calculateHeadRect(noseX: noseX, noseY: noseY, chestWidth: chestRect.width)
        
        // Update the chest and head layers with their respective frames and colors
        updateLayer(frame: chestRect, layer: &chestLayer, color: .red, view: view)
        updateLayer(frame: headRect, layer: &headLayer, color: .green, view: view)
    }
    
    // Extract key points (left shoulder, right shoulder, nose) from the pose observation
    private func getPoseKeyPoints(from observation: VNHumanBodyPoseObservation) -> (VNRecognizedPoint, VNRecognizedPoint, VNRecognizedPoint)? {
        // Attempt to retrieve key points with sufficient confidence
        guard let leftShoulder = try? observation.recognizedPoint(.leftShoulder),
              let rightShoulder = try? observation.recognizedPoint(.rightShoulder),
              let nose = try? observation.recognizedPoint(.nose),
              leftShoulder.confidence > 0.2, rightShoulder.confidence > 0.2, nose.confidence > 0.2 else {
            return nil
        }
        // Return the key points as a tuple
        return (leftShoulder, rightShoulder, nose)
    }
    
    // Calculate scaling factors to map camera coordinates to view coordinates
    private func calculateScaleFactors(view: UIView) -> (CGFloat, CGFloat) {
        // Scale X based on view width relative to camera height
        let scaleX = view.bounds.width / CGFloat(cameraHeight)
        // Scale Y based on view height relative to camera width
        let scaleY = view.bounds.height / CGFloat(cameraWidth)
        return (scaleX, scaleY)
    }
    
    // Convert a recognized point to view coordinates using scaling factors
    private func calculatePointPosition(point: VNRecognizedPoint, scaleX: CGFloat, scaleY: CGFloat) -> (CGFloat, CGFloat) {
        // Adjust x-coordinate, flipping y due to Vision's coordinate system
        let x = (1 - point.location.y) * CGFloat(cameraHeight) * scaleX
        // Adjust y-coordinate based on x from Vision's coordinate system
        let y = point.location.x * CGFloat(cameraWidth) * scaleY
        return (x, y)
    }
    
    // Calculate the chest rectangle based on shoulder positions
    private func calculateChestRect(leftShoulderX: CGFloat, leftShoulderY: CGFloat, rightShoulderX: CGFloat, rightShoulderY: CGFloat) -> CGRect {
        // Calculate chest width, adding padding
        let chestWidth = abs(rightShoulderX - leftShoulderX) + 60
        // Define a fixed chest height
        let chestHeight: CGFloat = 200
        // Position chest X at the leftmost shoulder with an offset
        let chestX = min(leftShoulderX, rightShoulderX) - 30
        // Position chest Y slightly above the shoulders
        let chestY = leftShoulderY - chestHeight / 4
        // Return the chest rectangle
        return CGRect(x: chestX, y: chestY, width: chestWidth, height: chestHeight)
    }
    
    // Calculate the head rectangle based on nose position and chest width
    private func calculateHeadRect(noseX: CGFloat, noseY: CGFloat, chestWidth: CGFloat) -> CGRect {
        // Set head width as half of the chest width
        let headWidth = chestWidth / 2
        // Define a fixed head height
        let headHeight: CGFloat = 100
        // Center the head X around the nose
        let headX = noseX - headWidth / 2
        // Center the head Y around the nose
        let headY = noseY - headHeight / 2
        // Return the head rectangle
        return CGRect(x: headX, y: headY, width: headWidth, height: headHeight)
    }
    
    // Update or create a layer with a given frame, color, and view
    private func updateLayer(frame: CGRect, layer: inout CALayer?, color: UIColor, view: UIView) {
        // Create a new layer if it doesn't exist
        if layer == nil {
            layer = CALayer()
            // Set the border color for the layer
            layer?.borderColor = color.cgColor
            // Set the border width for the layer
            layer?.borderWidth = 2
            // Add the layer to the view's layer hierarchy
            view.layer.addSublayer(layer!)
        }
        // Update the layer's frame to the calculated rectangle
        layer?.frame = frame
    }
    
    // Retrieve the left shoulder position from the last observation
    func getLeftShoulderPosition() -> CGPoint? {
        // Attempt to get the left shoulder point with sufficient confidence
        guard let leftShoulder = try? lastObservation?.recognizedPoint(.leftShoulder),
              leftShoulder.confidence > 0.2 else {
            return nil
        }
        // Return the location of the left shoulder
        return leftShoulder.location
    }

    // Retrieve the right shoulder position from the last observation
    func getRightShoulderPosition() -> CGPoint? {
        // Attempt to get the right shoulder point with sufficient confidence
        guard let rightShoulder = try? lastObservation?.recognizedPoint(.rightShoulder),
              rightShoulder.confidence > 0.2 else {
            return nil
        }
        // Return the location of the right shoulder
        return rightShoulder.location
    }
}
