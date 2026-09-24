//
//  BreathingRateEstimator.swift
//  breathing
//
//  Breaths per minute from the chest-depth series, by autocorrelation.
//

import Foundation

struct BreathingRateEstimate: Equatable {
    /// Estimated respiratory rate.
    let breathsPerMinute: Double
    /// Normalised autocorrelation at the breathing period, 0...1. Low values mean no clear rhythm.
    let confidence: Double
}

enum BreathingRateEstimator {
    /// Estimate the breathing rate from evenly spaced chest-depth samples.
    ///
    /// The series is detrended with a least-squares line (the phone or the person drifts slowly),
    /// then the normalised autocorrelation is searched over lags that correspond to
    /// `minBPM...maxBPM`. A periodic signal correlates almost as well at twice its period, and noise
    /// can tip the balance, so the shortest peak within 60% of the best one is taken as the period
    /// (with 90%, heavy noise halved one rate in three). The lag is refined by parabolic
    /// interpolation because at 2 Hz one sample is a large step in rate.
    ///
    /// Returns `nil` when there is less than `minimumDuration` seconds of data or no lag correlates
    /// above `minimumConfidence`.
    static func estimate(
        samples: [Double],
        sampleInterval: Double,
        minBPM: Double = 6,
        maxBPM: Double = 40,
        minimumDuration: Double = 15,
        minimumConfidence: Double = 0.3
    ) -> BreathingRateEstimate? {
        let n = samples.count
        guard sampleInterval > 0, Double(n) * sampleInterval >= minimumDuration else { return nil }

        let x = detrended(samples)
        let energy = x.reduce(0) { $0 + $1 * $1 }
        guard energy > 0 else { return nil }

        let minLag = max(1, Int((60 / maxBPM / sampleInterval).rounded(.down)))
        let maxLag = min(n / 2, Int((60 / minBPM / sampleInterval).rounded(.up)))
        guard minLag + 1 < maxLag else { return nil }

        // Normalised so that r(0) = 1, with a 1/(n - k) correction for the shrinking overlap.
        func r(_ lag: Int) -> Double {
            var sum = 0.0
            for t in 0..<(n - lag) { sum += x[t] * x[t + lag] }
            return (sum / Double(n - lag)) / (energy / Double(n))
        }
        let correlations = (minLag - 1...maxLag + 1).map { r($0) }
        func corr(_ lag: Int) -> Double { correlations[lag - (minLag - 1)] }

        let peaks = (minLag...maxLag).filter { corr($0) >= corr($0 - 1) && corr($0) >= corr($0 + 1) }
        guard let best = peaks.map(corr).max(), best >= minimumConfidence else { return nil }
        guard let lag = peaks.first(where: { corr($0) >= 0.6 * best }) else { return nil }

        let (left, centre, right) = (corr(lag - 1), corr(lag), corr(lag + 1))
        let curvature = left - 2 * centre + right
        let offset = curvature < 0 ? 0.5 * (left - right) / curvature : 0
        let period = (Double(lag) + offset) * sampleInterval
        return BreathingRateEstimate(breathsPerMinute: 60 / period, confidence: min(1, centre))
    }

    /// Subtract the least-squares line through the samples.
    static func detrended(_ samples: [Double]) -> [Double] {
        let n = Double(samples.count)
        guard n > 1 else { return samples.map { _ in 0 } }
        let meanT = (n - 1) / 2
        let meanY = samples.reduce(0, +) / n
        var covariance = 0.0
        var variance = 0.0
        for (t, y) in samples.enumerated() {
            covariance += (Double(t) - meanT) * (y - meanY)
            variance += (Double(t) - meanT) * (Double(t) - meanT)
        }
        let slope = covariance / variance
        return samples.enumerated().map { t, y in y - (meanY + slope * (Double(t) - meanT)) }
    }
}
