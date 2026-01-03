//
//  RSSFetcherServiceTests+NotModified.swift
//  CelestraKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import Testing

@testable import CelestraKit

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

extension RSSFetcherServiceTests {
  @Suite("RSSFetcherService 304 Not Modified Tests", .serialized, .tags(.networkMock))
  final class NotModified {
    init() {
      mockURLProtocolSemaphore.wait()
    }

    deinit {
      MockURLProtocol.requestHandler = nil
      mockURLProtocolSemaphore.signal()
    }

    @Test("Handle 304 Not Modified response")
    func handle304NotModified() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!

      MockURLProtocol.requestHandler = { request in
        // Verify conditional headers were sent
        #expect(request.value(forHTTPHeaderField: "If-Modified-Since") != nil)
        #expect(request.value(forHTTPHeaderField: "If-None-Match") != nil)

        let response = HTTPURLResponse(
          url: feedURL,
          statusCode: 304,
          httpVersion: nil,
          headerFields: [
            "ETag": "\"abc123\""
          ]
        )!
        return (response, nil)
      }

      let service = RSSFetcherService(
        urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))

      let result = try await service.fetchFeed(
        from: feedURL,
        lastModified: "Mon, 01 Jan 2024 12:00:00 GMT",
        etag: "\"abc123\""
      )

      #expect(result.wasModified == false)
      #expect(result.feedData == nil)
      #expect(result.etag == "\"abc123\"")
      #expect(result.lastModified == "Mon, 01 Jan 2024 12:00:00 GMT")
    }
  }
}
