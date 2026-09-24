# Contactless Breathing Monitor

[![iOS build and tests](https://github.com/asher0913/contactless-breathing-monitor/actions/workflows/ci.yml/badge.svg)](https://github.com/asher0913/contactless-breathing-monitor/actions/workflows/ci.yml)
![Swift](https://img.shields.io/badge/Swift-5-orange)
![iOS](https://img.shields.io/badge/iOS-18.2%2B-lightgrey)

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
5. A weighted moving-average filter reduces frame-to-frame noise. Every 0.5 s the mean of the
   window's frames becomes one sample of the live breathing curve (the last 50 s are shown).
6. Once 15 s of signal is available, the respiratory rate is estimated from the curve and shown
   under it in breaths per minute.

## Breathing rate

`BreathingRateEstimator` works on the 2 Hz depth series:

- it removes the least-squares trend, since the phone or the person drifts slowly;
- it computes the normalised autocorrelation over lags between 6 and 40 breaths per minute;
- it takes the shortest strong peak as the breathing period, refined by parabolic interpolation;
- it declines to answer when no lag correlates above 0.3.

On synthetic chest-depth signals (4 mm breathing amplitude at 0.8 m, Gaussian noise, slow drift,
8–30 breaths per minute, 200 seeds per setting):

| Noise, relative to breathing amplitude | Within 1 breath/min | Declined | Half the true rate |
|---:|---:|---:|---:|
| 30% | 100% | 0% | 0% |
| 60% | 99.6% | 0% | <0.1% |
| 100% | 69% | 15% | 5% |

On pure noise, a rate is reported in 0.8% of windows. An earlier rule, the shortest peak within
90% of the best, halved the rate for one noisy signal in three: a periodic signal correlates
almost as well at twice its period. These are synthetic signals; accuracy on real people, who
talk, shift and breathe irregularly, has not been measured.

The depth series itself had a bug that mattered more than any filter. Each 0.5 s sample was
the *sum* of the frame depths in the window, not their mean. With one frame more or less per
window, the sample moved by about 7%, several times the ~1% depth change of a breath. It now
records the mean.

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

The unit tests cover Gaussian filtering, weighted moving averages, pixel-buffer cropping,
breathing-curve rendering and the rate estimator: clean rates across the normal range, noise
and drift, declining on noise, and the 15 s minimum. CI builds the app and runs them on an
iPhone simulator. From the command line:

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
