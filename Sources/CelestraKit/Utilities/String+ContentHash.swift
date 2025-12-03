// String+ContentHash.swift
// CelestraKit
//
// Created for Celestra on 2025-12-03.
//

import Crypto
import Foundation

// MARK: - Content Hashing Utilities
extension String {
  /// SHA256 hash for secure content deduplication
  public var contentHash: String {
    let data = Data(self.utf8)
    let digest = SHA256.hash(data: data)
    return digest.compactMap { String(format: "%02x", $0) }.joined()
  }
}
