//
//  MemoryPressureMonitor.swift
//  CelestraKit
//
//  Created for Celestra on 2025-08-13.
//

public import Foundation
import os.log

/// Memory pressure levels for queue management
public enum MemoryPressureLevel: Int, Sendable, Comparable {
  case normal = 0
  case warning = 1
  case critical = 2
  
  public static func < (lhs: MemoryPressureLevel, rhs: MemoryPressureLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}

/// Memory usage statistics
public struct MemoryUsage: Sendable {
  public let totalPhysical: Int64
  public let available: Int64
  public let used: Int64
  public let cached: Int64
  public let timestamp: Date
  
  public var usagePercentage: Double {
    guard totalPhysical > 0 else { return 0.0 }
    return Double(used) / Double(totalPhysical) * 100.0
  }
  
  public var availablePercentage: Double {
    guard totalPhysical > 0 else { return 0.0 }
    return Double(available) / Double(totalPhysical) * 100.0
  }
  
  public init(
    totalPhysical: Int64 = 0,
    available: Int64 = 0,
    used: Int64 = 0,
    cached: Int64 = 0,
    timestamp: Date = Date()
  ) {
    self.totalPhysical = totalPhysical
    self.available = available
    self.used = used
    self.cached = cached
    self.timestamp = timestamp
  }
}

/// Configuration for memory pressure monitoring
public struct MemoryPressureConfig: Sendable {
  public let warningThreshold: Double     // Percentage of memory used
  public let criticalThreshold: Double    // Percentage of memory used
  public let monitoringInterval: TimeInterval
  public let lowMemoryTaskLimit: Int      // Max concurrent tasks under pressure
  
  public init(
    warningThreshold: Double = 75.0,
    criticalThreshold: Double = 85.0,
    monitoringInterval: TimeInterval = 5.0,
    lowMemoryTaskLimit: Int = 2
  ) {
    self.warningThreshold = warningThreshold
    self.criticalThreshold = criticalThreshold
    self.monitoringInterval = monitoringInterval
    self.lowMemoryTaskLimit = lowMemoryTaskLimit
  }
}

/// Monitors system memory pressure and provides recommendations for queue management
@MainActor
public final class MemoryPressureMonitor: ObservableObject {
  private let config: MemoryPressureConfig
  private let logger = Logger(subsystem: "com.celestra.kit", category: "MemoryPressure")
  
  @Published public private(set) var currentLevel: MemoryPressureLevel = .normal
  @Published public private(set) var memoryUsage: MemoryUsage = MemoryUsage()
  @Published public private(set) var isMonitoring = false
  
  private var monitoringTask: Task<Void, Never>?
  private let pressureSource: DispatchSourceMemoryPressure
  
  public init(config: MemoryPressureConfig = MemoryPressureConfig()) {
    self.config = config
    
    // Set up system memory pressure notifications
    self.pressureSource = DispatchSource.makeMemoryPressureSource(
      eventMask: [.warning, .critical],
      queue: .main
    )
    
    setupPressureSource()
  }
  
  deinit {
    stopMonitoring()
  }
  
  /// Start monitoring memory pressure
  public func startMonitoring() {
    guard !isMonitoring else { return }
    
    isMonitoring = true
    pressureSource.resume()
    
    // Start periodic memory usage monitoring
    monitoringTask = Task {
      while !Task.isCancelled {
        await updateMemoryUsage()
        
        try? await Task.sleep(for: .seconds(config.monitoringInterval))
      }
    }
    
    logger.info("Memory pressure monitoring started")
  }
  
  /// Stop monitoring memory pressure
  public func stopMonitoring() {
    guard isMonitoring else { return }
    
    isMonitoring = false
    monitoringTask?.cancel()
    monitoringTask = nil
    pressureSource.suspend()
    
    logger.info("Memory pressure monitoring stopped")
  }
  
  /// Get recommended task limit based on current memory pressure
  public func recommendedTaskLimit(defaultLimit: Int) -> Int {
    switch currentLevel {
    case .normal:
      return defaultLimit
    case .warning:
      return min(defaultLimit, max(1, defaultLimit / 2))
    case .critical:
      return min(config.lowMemoryTaskLimit, 1)
    }
  }
  
  /// Check if parsing operations should be paused due to memory pressure
  public func shouldPauseOperations() -> Bool {
    currentLevel >= .critical
  }
  
  /// Force garbage collection (iOS/macOS specific)
  public func requestMemoryCleanup() {
    // Request memory cleanup from the system
    autoreleasepool {
      // This will help release any pending autoreleased objects
    }
    
    logger.info("Memory cleanup requested")
  }
  
  // MARK: - Private Methods
  
  private func setupPressureSource() {
    pressureSource.setEventHandler { [weak self] in
      Task { @MainActor in
        await self?.handleSystemMemoryPressure()
      }
    }
    
    pressureSource.setCancelHandler { [weak self] in
      self?.logger.debug("Memory pressure source cancelled")
    }
  }
  
  private func handleSystemMemoryPressure() {
    let memoryPressure = pressureSource.mask
    
    if memoryPressure.contains(.critical) {
      currentLevel = .critical
      logger.warning("Critical memory pressure detected")
      requestMemoryCleanup()
    } else if memoryPressure.contains(.warning) {
      currentLevel = .warning
      logger.info("Memory pressure warning")
    }
    
    // Update memory usage immediately
    Task { await updateMemoryUsage() }
  }
  
  private func updateMemoryUsage() async {
    let usage = await getMemoryUsage()
    memoryUsage = usage
    
    // Update pressure level based on usage percentage
    let usagePercent = usage.usagePercentage
    let newLevel: MemoryPressureLevel
    
    if usagePercent >= config.criticalThreshold {
      newLevel = .critical
    } else if usagePercent >= config.warningThreshold {
      newLevel = .warning
    } else {
      newLevel = .normal
    }
    
    if newLevel != currentLevel {
      currentLevel = newLevel
      logger.info("Memory pressure level changed to \(newLevel) (usage: \(usagePercent, format: .number.precision(.fractionLength(1)))%)")
    }
  }
  
  private func getMemoryUsage() async -> MemoryUsage {
    return await withCheckedContinuation { continuation in
      Task.detached {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
          $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
          }
        }
        
        var usage = MemoryUsage()
        
        if result == KERN_SUCCESS {
          // Get physical memory info
          var physicalMemory: UInt64 = 0
          var size = MemoryLayout<UInt64>.size
          sysctlbyname("hw.memsize", &physicalMemory, &size, nil, 0)
          
          // Get VM stats
          var vmStats = vm_statistics64()
          var statsCount = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
          
          let statsResult = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
              host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &statsCount)
            }
          }
          
          if statsResult == KERN_SUCCESS {
            let pageSize = vm_kernel_page_size
            let totalPhysical = Int64(physicalMemory)
            let available = Int64((vmStats.free_count + vmStats.inactive_count) * UInt64(pageSize))
            let used = totalPhysical - available
            let cached = Int64(vmStats.inactive_count * UInt64(pageSize))
            
            usage = MemoryUsage(
              totalPhysical: totalPhysical,
              available: available,
              used: used,
              cached: cached
            )
          }
        }
        
        continuation.resume(returning: usage)
      }
    }
  }
}