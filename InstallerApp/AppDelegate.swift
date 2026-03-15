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
    private let iPhoneLikeUserAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

    // BaseURL: config.plist → fallback
    var baseURL: String {
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let url = dict["BaseURL"] as? String {
            return url
        }
        return "https://192.168.1.65:3443"
    }

    // CertName: config.plist → fallback
    var certName: String {
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let cert = dict["CertName"] as? String {
            return cert
        }
        return "Takeoff"
    }

    override func loadView() {
        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        if #available(iOS 13.0, *) {
            // Force mobile rendering on iPad to avoid desktop-style centered layout.
            cfg.defaultWebpagePreferences.preferredContentMode = .mobile
        }
        webView = WKWebView(frame: .zero, configuration: cfg)
        if UIDevice.current.userInterfaceIdiom == .pad {
            // Force iPad to receive phone layout from server-side/device-detect logic.
            webView.customUserAgent = iPhoneLikeUserAgent
        }
        webView.navigationDelegate = self
        webView.uiDelegate         = self
        webView.backgroundColor    = UIColor(red: 0.05, green: 0.05, blue: 0.10, alpha: 1)
        webView.isOpaque           = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.10, alpha: 1)
        loadSite()
    }

    func loadSite() {
        let encoded = certName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? certName
        let urlStr  = "\(baseURL)/app-installer?cert=\(encoded)"
        if let url = URL(string: urlStr) {
            webView.load(URLRequest(url: url))
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // ── Handle itms-services:// ────────────────────────────────────────────────
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            let scheme = url.scheme ?? ""
            if ["itms-services", "itms", "itmss"].contains(scheme) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
                return
            }
        }
        decisionHandler(.allow)
    }

    // ── No internet error page (clean, no URL input) ───────────────────────────
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        let html = """
        <html><head>
        <meta name='viewport' content='width=device-width,initial-scale=1,maximum-scale=1'>
        <style>
        *{box-sizing:border-box;margin:0;padding:0}
        body{background:#0a0a0f;color:#f1f5f9;font-family:-apple-system,system-ui;
          display:flex;flex-direction:column;align-items:center;justify-content:center;
          min-height:100vh;padding:32px;text-align:center;gap:16px}
        .icon{font-size:72px}
        h2{font-size:22px;font-weight:700}
        .sub{color:#64748b;font-size:14px;line-height:1.7}
        .btn{margin-top:8px;padding:14px 44px;
          background:rgba(255,255,255,0.08);
          border:1px solid rgba(255,255,255,0.12);
          border-radius:14px;color:#94a3b8;
          font-size:15px;font-weight:600;cursor:pointer}
        </style></head>
        <body>
        <div class='icon'>📡</div>
        <h2>No Internet Connection</h2>
        <div class='sub'>Internet connection check karo<br>aur dobara try karo</div>
        <button class='btn' onclick='location.reload()'>Try Again</button>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}
