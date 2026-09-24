//
//  BreathingRateEstimatorTests.swift
//  breathingTests
//

import XCTest
@testable import breathing

/// Deterministic noise so the tests never flake.
private struct SeededNoise {
    var state: UInt64
    mutating func uniform() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(1 << 53)
    }
    mutating func gaussian() -> Double {
        let u = max(uniform(), 1e-12), v = uniform()
        return sqrt(-2 * log(u)) * cos(2 * .pi * v)
    }
}

/// Chest depth sampled every 0.5 s: ~0.8 m away, 4 mm breathing amplitude, optional noise and drift.
private func chestDepth(bpm: Double, seconds: Double = 50, noise: Double = 0, drift: Double = 0, seed: UInt64 = 7) -> [Double] {
    var rng = SeededNoise(state: seed)
    return (0..<Int(seconds / 0.5)).map { i in
        let t = Double(i) * 0.5
        return 0.8 + 0.004 * sin(2 * .pi * bpm / 60 * t) + drift * t + noise * 0.004 * rng.gaussian()
    }
}

final class BreathingRateEstimatorTests: XCTestCase {
    func testRecoversCleanRatesAcrossTheNormalRange() throws {
        for bpm in [8.0, 12, 15, 20, 25, 30] {
            let estimate = try XCTUnwrap(BreathingRateEstimator.estimate(samples: chestDepth(bpm: bpm), sampleInterval: 0.5))
            XCTAssertEqual(estimate.breathsPerMinute, bpm, accuracy: 0.5, "at \(bpm) breaths/min")
            XCTAssertGreaterThan(estimate.confidence, 0.9)
        }
    }

    func testToleratesNoiseAndSlowDrift() throws {
        // Noise with a standard deviation of 60% of the breathing amplitude, and the phone slowly moving away.
        for bpm in [10.0, 16, 22] {
            let samples = chestDepth(bpm: bpm, noise: 0.6, drift: 0.0005)
            let estimate = try XCTUnwrap(BreathingRateEstimator.estimate(samples: samples, sampleInterval: 0.5))
            XCTAssertEqual(estimate.breathsPerMinute, bpm, accuracy: 1.0, "at \(bpm) breaths/min")
        }
    }

    func testDoesNotReportARateForNoise() {
        var rng = SeededNoise(state: 3)
        let noise = (0..<100).map { _ in rng.gaussian() }
        XCTAssertNil(BreathingRateEstimator.estimate(samples: noise, sampleInterval: 0.5))
    }

    func testNeedsFifteenSecondsOfSignal() {
        XCTAssertNil(BreathingRateEstimator.estimate(samples: chestDepth(bpm: 12, seconds: 10), sampleInterval: 0.5))
        XCTAssertNotNil(BreathingRateEstimator.estimate(samples: chestDepth(bpm: 12, seconds: 20), sampleInterval: 0.5))
    }

    func testDetrendRemovesALinearRamp() {
        let ramp = (0..<50).map { 2.0 + 0.1 * Double($0) }
        XCTAssertTrue(BreathingRateEstimator.detrended(ramp).allSatisfy { abs($0) < 1e-9 })
    }
}
