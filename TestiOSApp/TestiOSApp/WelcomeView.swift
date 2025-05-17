import SwiftUI
import WebKit

struct WelcomeView: View {
    @Binding var isPresented: Bool
    private let htmlFileName = "start.html"

    var body: some View {
        VStack(spacing: 0) {
            WebView(fileName: htmlFileName)
                .edgesIgnoringSafeArea(.top) // Allow webview to extend to top

            Button("Continue") {
                isPresented = false
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()
        }
        .background(Color(.systemGroupedBackground)) // Match system background
    }
}

struct WebView: UIViewRepresentable {
    let fileName: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = Bundle.main.url(forResource: fileName, withExtension: nil) {
            uiView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            // Fallback or error handling if file not found
            let htmlString = "<html><body><h1>Error: \(fileName) not found.</h1></body></html>"
            uiView.loadHTMLString(htmlString, baseURL: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("Webview didFail navigation: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("Webview didFailProvisionalNavigation: \(error.localizedDescription)")
        }
    }
}

#Preview {
    WelcomeView(isPresented: .constant(true))
} 