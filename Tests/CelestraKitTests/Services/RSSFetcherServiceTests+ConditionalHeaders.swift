//
//  RSSFetcherServiceTests+ConditionalHeaders.swift
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
  @Suite("RSSFetcherService Conditional Headers Tests", .serialized, .tags(.networkMock))
  final class ConditionalHeaders {
    init() async {
      await mockURLProtocolCoordinator.acquire()
    }

    deinit {
      Task {
        await mockURLProtocolCoordinator.release()
      }
    }

    @Test("Send If-Modified-Since header when lastModified provided")
    func sendsIfModifiedSinceHeader() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!
      let expectedLastModified = "Mon, 01 Jan 2024 12:00:00 GMT"

      var headersSent = false
      MockURLProtocol.requestHandler = { request in
        let ifModifiedSince = request.value(forHTTPHeaderField: "If-Modified-Since")
        #expect(ifModifiedSince == expectedLastModified)
        headersSent = true

        let response = HTTPURLResponse(
          url: feedURL, statusCode: 304,
          httpVersion: nil, headerFields: nil
        )!
        return (response, nil)
      }

      let service = RSSFetcherService(
        urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
      _ = try await service.fetchFeed(from: feedURL, lastModified: expectedLastModified)

      #expect(headersSent)
    }

    @Test("Send If-None-Match header when etag provided")
    func sendsIfNoneMatchHeader() async throws {
      let feedURL = URL(string: "https://example.com/feed.xml")!
      let expectedEtag = "\"abc123\""

      var headersSent = false
      MockURLProtocol.requestHandler = { request in
        let ifNoneMatch = request.value(forHTTPHeaderField: "If-None-Match")
        #expect(ifNoneMatch == expectedEtag)
        headersSent = true

        let response = HTTPURLResponse(
          url: feedURL, statusCode: 304,
          httpVersion: nil, headerFields: nil
        )!
        return (response, nil)
      }

      let service = RSSFetcherService(
        urlSession: createMockURLSession(), userAgent: UserAgent.app(build: 1))
      _ = try await service.fetchFeed(from: feedURL, etag: expectedEtag)

      #expect(headersSent)
    }
  }
}
