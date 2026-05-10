import SwiftUI
import WebKit

// MARK: - Navigation Delegate

class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {

    // Allow ALL navigation actions (handles redirects from embed providers)
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        let scheme = url.scheme?.lowercased() ?? ""

        // Block non-web schemes that could try to open external apps
        let blockedSchemes = ["itms-apps", "tel", "sms", "facetime", "mailto"]
        if blockedSchemes.contains(scheme) {
            decisionHandler(.cancel)
            return
        }

        // Allow everything else (http, https, about, blob, data, javascript)
        decisionHandler(.allow)
    }

    // Allow all navigation responses
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        decisionHandler(.allow)
    }

    // Handle redirects — always follow them
    func webView(
        _ webView: WKWebView,
        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!
    ) {}

    // Handle auth challenges (some providers use HTTPS with custom certs)
    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView navigation failed: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("WebView provisional navigation failed: \(error.localizedDescription)")
    }
}

// MARK: - WKWebView Wrapper
class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            let scheme = url.scheme?.lowercased() ?? ""
            let blockedSchemes = ["itms-apps", "tel", "sms", "facetime", "mailto"]
            
            if blockedSchemes.contains(scheme) {
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
               let serverTrust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                completionHandler(.performDefaultHandling, nil)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView failed: \(error.localizedDescription)")
        }
    }

struct WebView: UIViewRepresentable {
    let url: URL

    // Must be retained strongly — delegate is weak in WKWebView
    private let navigationDelegate = WebViewNavigationDelegate()
    func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        // Allow inline media playback without user gesture
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        // Allow JS and popups (needed by embed providers)
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Picture-in-picture support
        config.allowsPictureInPictureMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = navigationDelegate
        webView.navigationDelegate = context.coordinator
        // Spoof Safari user agent — providers often block generic WebView UA
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.isOpaque = false
        webView.scrollView.isScrollEnabled = false

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        var request = URLRequest(url: url)
        // Referer header — some providers validate this before serving content
        request.setValue(url.absoluteString, forHTTPHeaderField: "Referer")
        request.setValue(
            "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            forHTTPHeaderField: "User-Agent"
        )
        webView.load(request)
    }
}

// MARK: - Player Sheet

struct PlayerView: View {
    let url: URL
    let providerName: String

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                WebView(url: url)
                    .ignoresSafeArea(edges: .bottom)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation { isLoading = false }
                        }
                    }

                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.4)
                        Text("Loading player...")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle(providerName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
