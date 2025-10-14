//
//  BestShotService.swift
//  swift-cam
//
//  Service for managing Best Shot automatic capture sequence
//

import Foundation
import CoreLocation
import UIKit
import OSLog

/// Manages Best Shot automatic capture sequence
///
/// Coordinates the Best Shot feature which automatically captures high-resolution
/// photos when a target object is detected with high confidence. Features include:
/// - Configurable sequence duration
/// - Confidence-based capture (>80%)
/// - Throttling (1 capture/second)
/// - Top candidate selection
///
/// **Usage:**
/// ```swift
/// let service = BestShotService()
/// service.onCountdownTick = { remaining in
///     // Update UI
/// }
/// service.startSequence(duration: 10.0, targetLabel: "cat") { result in
///     // Trigger photo capture
/// }
/// ```
class BestShotService {
    
    // MARK: - Candidate Model
    
    struct CaptureCandidate: Equatable, Identifiable {
        let id = UUID()
        let imageData: Data
        let result: ClassificationResult
        var thumbnail: UIImage?
        var location: CLLocation?
        
        static func == (lhs: CaptureCandidate, rhs: CaptureCandidate) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    // MARK: - Properties
    
    private(set) var isSequenceActive = false
    private(set) var countdown: Double = 0
    private(set) var candidateCount: Int = 0
    private(set) var candidates: [CaptureCandidate] = []
    
    private var sequenceTimer: Timer?
    private var lastCaptureTime: Date = .distantPast
    private var targetLabel: String = ""
    
    private let hapticManager = HapticManagerService.shared
    
    // MARK: - Callbacks
    
    /// Called every second during countdown
    var onCountdownTick: ((Double) -> Void)?
    
    /// Called when sequence completes with sorted candidates
    var onSequenceComplete: (([CaptureCandidate]) -> Void)?
    
    /// Called when a high-confidence detection occurs (should trigger photo capture)
    var onCaptureNeeded: ((ClassificationResult) -> Void)?
    
    /// Called when candidate count changes
    var onCandidateCountChanged: ((Int) -> Void)?
    
    // MARK: - Sequence Control
    
    /// Start Best Shot capture sequence
    ///
    /// - Parameters:
    ///   - duration: Length of sequence in seconds
    ///   - targetLabel: Object label to detect (e.g., "cat")
    func startSequence(duration: Double, targetLabel: String) {
        guard !isSequenceActive else { return }
        
        hapticManager.impact(.medium)
        Logger.bestShot.info("Starting Best Shot sequence for \(duration)s, target: \(targetLabel)")
        
        isSequenceActive = true
        countdown = duration
        self.targetLabel = targetLabel.lowercased()
        candidates.removeAll()
        candidateCount = 0
        lastCaptureTime = .distantPast
        
        onCountdownTick?(countdown)
        
        // Start countdown timer
        sequenceTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            self.countdown -= 1
            self.onCountdownTick?(self.countdown)
            
            // Haptic feedback for last 3 seconds
            if self.countdown <= 3 && self.countdown > 0 {
                self.hapticManager.impact(.medium)
            }
            
            if self.countdown <= 0 {
                self.stopSequence()
            }
        }
    }
    
    /// Stop the Best Shot sequence
    func stopSequence() {
        guard isSequenceActive else { return }
        
        hapticManager.generate(.success)
        Logger.bestShot.info("Finished Best Shot sequence with \(self.candidates.count) candidates")
        
        isSequenceActive = false
        sequenceTimer?.invalidate()
        sequenceTimer = nil
        
        // Sort by confidence and notify
        let sortedCandidates = self.candidates.sorted { $0.result.confidence > $1.result.confidence }
        onSequenceComplete?(sortedCandidates)
        
        // Clean up
        self.candidates.removeAll()
    }
    
    // MARK: - Detection Processing
    
    /// Process live classification results to determine if capture is needed
    ///
    /// - Parameters:
    ///   - results: Current classification results
    ///   - confidenceThreshold: Minimum confidence required (default: 0.8)
    /// - Returns: True if capture should be triggered
    func processResults(_ results: [ClassificationResult], confidenceThreshold: Double = 0.8) -> Bool {
        guard isSequenceActive, !targetLabel.isEmpty else { return false }
        
        // Throttle captures to once per second
        let now = Date()
        guard now.timeIntervalSince(lastCaptureTime) > 1.0 else { return false }
        
        // Check for target object with high confidence
        if let bestResult = results.first(where: { 
            $0.identifier.lowercased().contains(targetLabel) 
        }), bestResult.confidence > confidenceThreshold {
            
            Logger.bestShot.debug("High-confidence object found: \(bestResult.identifier) (\(String(format: "%.1f%%", bestResult.confidence * 100)))")
            lastCaptureTime = now
            
            // Notify that capture should happen
            onCaptureNeeded?(bestResult)
            return true
        }
        
        return false
    }
    
    // MARK: - Candidate Management
    
    /// Add a captured candidate
    ///
    /// - Parameters:
    ///   - imageData: The captured image data
    ///   - result: The classification result that triggered capture
    ///   - thumbnail: Optional thumbnail for UI preview
    ///   - location: Optional location metadata
    func addCandidate(imageData: Data, result: ClassificationResult, thumbnail: UIImage?, location: CLLocation?) {
        let candidate = CaptureCandidate(
            imageData: imageData,
            result: result,
            thumbnail: thumbnail,
            location: location
        )
        
        candidates.append(candidate)
        candidateCount = candidates.count
        onCandidateCountChanged?(self.candidateCount)
        
        hapticManager.impact(.light)
        Logger.bestShot.info("Added candidate #\(self.candidateCount): \(result.identifier) (\(String(format: "%.1f%%", result.confidence * 100)))")
    }
    
    /// Clear all candidates
    func clearCandidates() {
        candidates.removeAll()
        candidateCount = 0
        onCandidateCountChanged?(0)
    }
}
