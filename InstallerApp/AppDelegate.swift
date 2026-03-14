import UIKit
import WebKit

// ─── AppDelegate ──────────────────────────────────────────────────────────────
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = InstallerWebVC()
        window?.makeKeyAndVisible()
        return true
    }
}

// ─── WebView VC ───────────────────────────────────────────────────────────────
class InstallerWebVC: UIViewController, WKNavigationDelegate, WKUIDelegate {

    var webView: WKWebView!
    var baseURL  = "https://192.168.1.65:3443"
    var certName = "Takeoff"

    // ── Load config.plist ──────────────────────────────────────────────────────
    override func loadView() {
        // Read config.plist
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) {
            baseURL  = (dict["BaseURL"]  as? String) ?? baseURL
            certName = (dict["CertName"] as? String) ?? certName
        }

        // WKWebView — full screen, no bounce
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: cfg)
        webView.navigationDelegate = self
        webView.uiDelegate         = self
        webView.backgroundColor    = UIColor(red:0.05,green:0.05,blue:0.10,alpha:1)
        webView.isOpaque           = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red:0.05,green:0.05,blue:0.10,alpha:1)

        // Build URL: baseURL/app-installer?cert=CertName
        let encoded = certName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? certName
        let urlStr  = "\(baseURL)/app-installer?cert=\(encoded)"
        if let url = URL(string: urlStr) {
            webView.load(URLRequest(url: url))
        }
    }

    // ── Status bar dark ───────────────────────────────────────────────────────
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // ── Intercept itms-services:// and other custom schemes ──────────────────
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {

        if let url = navigationAction.request.url {
            let scheme = url.scheme ?? ""
            // Let iOS handle itms-services, itms, etc.
            if scheme == "itms-services" || scheme == "itms" || scheme == "itmss" {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    // ── Error page ────────────────────────────────────────────────────────────
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let html = """
        <html><head><meta name='viewport' content='width=device-width,initial-scale=1'>
        <style>body{background:#0a0a0f;color:#f1f5f9;font-family:-apple-system;display:flex;
        flex-direction:column;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:20px;box-sizing:border-box;text-align:center;}
        h2{font-size:20px;margin-bottom:12px;}.sub{color:#64748b;font-size:14px;line-height:1.6;}
        .btn{margin-top:24px;padding:14px 32px;background:linear-gradient(135deg,#6c6fff,#a78bfa);border:none;border-radius:14px;color:#fff;font-size:15px;font-weight:700;}</style></head>
        <body><div style='font-size:48px;margin-bottom:16px'>⚠️</div>
        <h2>Server Connect Nahi Hua</h2>
        <div class='sub'>PC par server chal raha hai?<br>Same WiFi par ho?<br><br><strong>\(baseURL)</strong></div>
        <button class='btn' onclick='location.reload()'>Retry</button></body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
