// ArticleDetailView.swift
// CelestraKit
//
// Created for Celestra on 2025-08-07.

#if canImport(SwiftUI)

  import SwiftUI

  #if canImport(WebKit)
    import WebKit
  #endif

  /// Article detail view with HTML content rendering
  struct ArticleDetailView: View {
    let article: Article
    @Environment(\.dismiss)
    private var dismiss
    #if canImport(WebKit)
      @State private var webPage = WebPage()
    #endif

    var body: some View {
      NavigationStack {
        VStack(alignment: .leading, spacing: 0) {
          // Article header
          VStack(alignment: .leading, spacing: 8) {
            Text(article.title)
              .font(.largeTitle)
              .bold()

            if let author = article.author {
              Text("By \(author)")
                .foregroundStyle(.secondary)
            }

            Text(article.publishedDate.formatted(date: .complete, time: .shortened))
              .font(.caption)
              .foregroundStyle(.tertiary)
          }
          .padding()

          Divider()
          #if canImport(WebKit)
            // HTML content rendered in WebView
            if let content = article.content {
              WebView(webPage)
                .onAppear {
                  loadHTMLContent(content)
                }
            } else {
              Text("No content available")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
          #else

            if let content = article.content {
              Text(content)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
              Text("No content available")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
          #endif
        }
        #if os(iOS)
          .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
          ToolbarItem(placement: .automatic) {
            Button("Done") {
              dismiss()
            }
          }
        }
      }
    }
    #if canImport(WebKit)
      #warning("Refactor this")
      // swiftlint:disable:next function_body_length
      private func loadHTMLContent(_ htmlContent: String) {
        let styledHTML = """
          <!DOCTYPE html>
          <html>
          <head>
              <meta
                name="viewport"
                content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
              <style>
                  :root {
                      color-scheme: light dark;
                  }

                  body {
                      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
                      font-size: 17px;
                      line-height: 1.6;
                      color: var(--text-color, #000);
                      background-color: transparent;
                      padding: 16px;
                      margin: 0;
                      word-wrap: break-word;
                      -webkit-text-size-adjust: 100%;
                  }

                  @media (prefers-color-scheme: dark) {
                      body {
                          color: #fff;
                      }
                  }

                  img {
                      max-width: 100%;
                      height: auto;
                      display: block;
                      margin: 16px 0;
                      border-radius: 8px;
                  }

                  a {
                      color: #007AFF;
                      text-decoration: none;
                  }

                  a:hover {
                      text-decoration: underline;
                  }

                  pre {
                      overflow-x: auto;
                      background-color: rgba(128, 128, 128, 0.1);
                      padding: 12px;
                      border-radius: 6px;
                      font-family: 'SF Mono', Menlo, Monaco, Consolas, monospace;
                      font-size: 14px;
                  }

                  code {
                      font-family: 'SF Mono', Menlo, Monaco, Consolas, monospace;
                      background-color: rgba(128, 128, 128, 0.1);
                      padding: 2px 4px;
                      border-radius: 3px;
                      font-size: 0.9em;
                  }

                  blockquote {
                      border-left: 4px solid #007AFF;
                      margin: 16px 0;
                      padding-left: 16px;
                      color: rgba(0, 0, 0, 0.6);
                  }

                  @media (prefers-color-scheme: dark) {
                      blockquote {
                          color: rgba(255, 255, 255, 0.6);
                      }
                  }

                  h1, h2, h3, h4, h5, h6 {
                      margin-top: 24px;
                      margin-bottom: 16px;
                      font-weight: 600;
                  }

                  p {
                      margin: 16px 0;
                  }

                  ul, ol {
                      padding-left: 24px;
                      margin: 16px 0;
                  }

                  li {
                      margin: 8px 0;
                  }

                  hr {
                      border: none;
                      border-top: 1px solid rgba(128, 128, 128, 0.2);
                      margin: 24px 0;
                  }

                  table {
                      border-collapse: collapse;
                      width: 100%;
                      margin: 16px 0;
                  }

                  th, td {
                      border: 1px solid rgba(128, 128, 128, 0.2);
                      padding: 8px 12px;
                      text-align: left;
                  }

                  th {
                      background-color: rgba(128, 128, 128, 0.1);
                      font-weight: 600;
                  }
              </style>
          </head>
          <body>
              \(htmlContent)
          </body>
          </html>
          """
        self.webPage.load(html: styledHTML)
      }
    #endif
  }

#endif
