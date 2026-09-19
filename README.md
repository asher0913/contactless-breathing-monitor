# Contactless Breathing Monitor

An iOS prototype that estimates respiratory motion without wearable sensors.
It combines the front TrueDepth camera with Vision body-pose landmarks to
isolate the chest region, smooth its depth signal, and plot motion over time in
a SwiftUI interface.

## How it works

1. `AVCaptureMultiCamSession` synchronizes front-camera video and depth output.
2. `VNDetectHumanBodyPoseRequest` locates the shoulders and derives a chest
   region of interest.
3. The corresponding depth buffer is cropped and passed through a Gaussian
   image filter.
4. Invalid depth pixels are discarded and the remaining values are averaged.
5. A weighted moving-average filter reduces frame-to-frame noise before the
   signal is sampled into a live breathing curve.

All frame and depth processing happens on the device. The project has no
network client, analytics integration, or persistence layer.

## Technology

- Swift 5 and SwiftUI
- AVFoundation / TrueDepth
- Vision human-body pose estimation
- Core Image and `CVPixelBuffer` processing
- XCTest unit and UI tests

## Requirements

- Xcode 16 or newer
- iOS 18.2+
- A physical iPhone or iPad with a front TrueDepth camera for live capture

The simulator can build and run the interface and parts of the test suite, but
it cannot provide the required depth-camera stream.

## Run

1. Open `breathing.xcodeproj` in Xcode.
2. Select the `breathing` scheme and a compatible physical device.
3. Choose a local signing team if Xcode requests one.
4. Build and run, then grant camera access.

## Tests

The test targets cover Gaussian filtering, weighted moving averages, pixel
buffer cropping, and breathing-curve rendering. From the command line:

```bash
xcodebuild \
  -project breathing.xcodeproj \
  -scheme breathing \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  test
```

Hardware-dependent capture behavior should be validated on a TrueDepth device.

## Privacy

The app processes camera and depth frames in memory and does not upload or save
them. The repository intentionally contains no provisioning profile, signing
team, user-specific Xcode data, or production credentials.
