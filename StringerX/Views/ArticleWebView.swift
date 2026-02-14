import SwiftUI
import WebKit

struct ArticleWebView: NSViewRepresentable {
    let htmlContent: String
    @Binding var hoveredURL: String?

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // Add mouse-over script to detect link hovering
        let mouseoverScript = WKUserScript(
            source: """
            document.onmouseover = function (event) {
                var target = event.target;
                while (target) {
                    if (target.href) {
                        window.webkit.messageHandlers.mouseover.postMessage(target.href);
                        return;
                    }
                    target = target.parentNode;
                }
                window.webkit.messageHandlers.mouseover.postMessage(null);
            }
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )

        configuration.userContentController.addUserScript(mouseoverScript)
        configuration.userContentController.add(context.coordinator, name: "mouseover")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        // Only reload if content actually changed
        if context.coordinator.currentHTML != htmlContent {
            context.coordinator.currentHTML = htmlContent
            webView.loadHTMLString(htmlContent, baseURL: nil)
        }

        // Make webview first responder so Space/Shift+Space work for scrolling
        DispatchQueue.main.async {
            webView.window?.makeFirstResponder(webView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        let parent: ArticleWebView
        var currentHTML: String = ""

        init(parent: ArticleWebView) {
            self.parent = parent
        }

        // Handle link clicks - open in Safari
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }

            // Allow about:blank and initial page load
            if url.absoluteString == "about:blank" || navigationAction.navigationType == .other {
                decisionHandler(.allow)
                return
            }

            // Cancel and open in browser
            decisionHandler(.cancel)
            openInBrowser(url: url)
        }

        // Handle target="_blank" links
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if let url = navigationAction.request.url {
                openInBrowser(url: url)
            }
            return nil
        }

        // Handle mouseover messages from JavaScript
        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            if message.name == "mouseover" {
                DispatchQueue.main.async {
                    if let urlString = message.body as? String {
                        self.parent.hoveredURL = urlString
                    } else {
                        self.parent.hoveredURL = nil
                    }
                }
            }
        }

        private func openInBrowser(url: URL) {
            NSWorkspace.shared.open(
                [url],
                withApplicationAt: URL(fileURLWithPath: "/Applications/Safari.app"),
                configuration: NSWorkspace.OpenConfiguration()
            )
        }
    }
}
