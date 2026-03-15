import UIKit
import WebKit

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

class InstallerWebVC: UIViewController, WKNavigationDelegate, WKUIDelegate {

    var webView: WKWebView!

    // ── URL resolution priority ────────────────────────────────────────────────
    // 1. UserDefaults (saved via error page input)
    // 2. config.plist BaseURL
    // 3. Hardcoded fallback
    var baseURL: String {
        if let saved = UserDefaults.standard.string(forKey: "ServerBaseURL"), !saved.isEmpty {
            return saved
        }
        if let path = Bundle.main.path(forResource: "config", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let url = dict["BaseURL"] as? String {
            return url
        }
        return "https://192.168.1.65:3443"
    }

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

        // Allow JS to call Swift to save URL
        let contentController = WKUserContentController()
        contentController.add(self as! WKScriptMessageHandler, name: "saveURL")
        cfg.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: cfg)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.10, alpha: 1)
        webView.isOpaque = false
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
        // Load BGMI installer page with cert-specific URL
        let certName = self.certName
        let encoded  = certName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? certName
        let urlStr   = "\(baseURL)/app-installer?cert=\(encoded)"
        if let url = URL(string: urlStr) {
            webView.load(URLRequest(url: url))
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // ── Handle itms-services:// and custom schemes ─────────────────────────────
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

    // ── Error page with URL input ──────────────────────────────────────────────
    func webView(_ webView: WKWebView,
                 didFailProvisionalNavigation navigation: WKNavigation!,
                 withError error: Error) {
        let currentURL = baseURL
        let html = """
        <html><head>
        <meta name='viewport' content='width=device-width,initial-scale=1,maximum-scale=1'>
        <style>
        *{box-sizing:border-box;margin:0;padding:0}
        body{background:#0a0a0f;color:#f1f5f9;font-family:-apple-system,system-ui;
          display:flex;flex-direction:column;align-items:center;justify-content:center;
          min-height:100vh;padding:24px;text-align:center;gap:0}
        .icon{font-size:52px;margin-bottom:20px}
        h2{font-size:20px;font-weight:700;margin-bottom:10px}
        .sub{color:#64748b;font-size:13px;line-height:1.6;margin-bottom:28px}
        .divider{width:100%;height:1px;background:rgba(255,255,255,0.08);margin:20px 0}
        label{font-size:12px;color:#94a3b8;margin-bottom:8px;text-align:left;width:100%;display:block}
        input{width:100%;padding:13px 14px;background:#1e1e2e;border:1px solid rgba(255,255,255,0.12);
          border-radius:10px;color:#f1f5f9;font-size:13px;outline:none;margin-bottom:12px}
        .btn{width:100%;padding:14px;background:linear-gradient(135deg,#6c6fff,#a78bfa);
          border:none;border-radius:12px;color:#fff;font-size:15px;font-weight:700;cursor:pointer}
        .btn-retry{margin-top:12px;width:100%;padding:13px;background:rgba(255,255,255,0.06);
          border:1px solid rgba(255,255,255,0.12);border-radius:12px;color:#94a3b8;
          font-size:14px;font-weight:600;cursor:pointer}
        </style></head><body>
        <div class='icon'>⚠️</div>
        <h2>Server Connect Nahi Hua</h2>
        <div class='sub'>PC par server chal raha hai?<br>Same WiFi par ho?<br><br>
          <strong style='color:#f1f5f9'>\(currentURL)</strong></div>

        <div class='divider'></div>
        <label>Tunnel URL dalo (SIM internet ke liye):</label>
        <input type='url' id='urlInput' placeholder='https://xxxx.trycloudflare.com'
               value='\(currentURL)' autocorrect='off' autocapitalize='off'/>
        <button class='btn' onclick='saveAndLoad()'>Connect</button>
        <button class='btn-retry' onclick='location.reload()'>Retry Same URL</button>

        <script>
        function saveAndLoad() {
          var url = document.getElementById('urlInput').value.trim().replace(/\\/$/, '');
          if (!url.startsWith('http')) { alert('URL https:// se shuru honi chahiye'); return; }
          window.webkit.messageHandlers.saveURL.postMessage(url);
        }
        </script>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

// ── JS → Swift message: save URL and reload ───────────────────────────────────
extension InstallerWebVC: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        if message.name == "saveURL", let url = message.body as? String {
            UserDefaults.standard.set(url, forKey: "ServerBaseURL")
            loadSite()
        }
    }
}
