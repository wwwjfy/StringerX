import SwiftUI
import WebKit

final class KeyForwardingWebView: WKWebView {
    var onShortcut: ((Character) -> Void)?
    var onEscape: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        // Escape (keyCode 53) closes the article overlay
        if event.keyCode == 53 {
            onEscape?()
            return
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        // Only intercept letter shortcuts when no command/option/control held (shift OK for capital A)
        if modifiers.subtracting(.shift).isEmpty,
           let chars = event.charactersIgnoringModifiers,
           chars.count == 1 {
            let c = Character(chars)
            switch c {
            case "j", "k", "o", "g", "v", "s", "A":
                onShortcut?(c)
                return
            default:
                break
            }
        }

        super.keyDown(with: event)
    }
}

struct ArticleWebView: NSViewRepresentable {
    let htmlContent: String
    let baseURL: URL?
    @Binding var hoveredURL: String?
    let onShortcut: (Character) -> Void
    let onEscape: () -> Void

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

        let webView = KeyForwardingWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.onShortcut = onShortcut
        webView.onEscape = onEscape

        #if DEBUG
        if #available(macOS 13.3, *) {
            webView.isInspectable = true
        }
        #endif

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        if let kfWebView = webView as? KeyForwardingWebView {
            kfWebView.onShortcut = onShortcut
            kfWebView.onEscape = onEscape
        }

        // Only reload if content actually changed
        if context.coordinator.currentHTML != htmlContent {
            context.coordinator.currentHTML = htmlContent
            webView.loadHTMLString(htmlContent, baseURL: baseURL)
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
