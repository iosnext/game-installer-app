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
    private let iPhoneSafeAreaScript = """
    (function() {
      function ensureViewport() {
        var meta = document.querySelector('meta[name="viewport"]');
        if (!meta) {
          meta = document.createElement('meta');
          meta.name = 'viewport';
          document.head.appendChild(meta);
        }
        meta.setAttribute(
          'content',
          'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover'
        );
      }

      function applySafeAreaPadding() {
        var style = document.getElementById('iphone-safe-area-fix');
        if (!style) {
          style = document.createElement('style');
          style.id = 'iphone-safe-area-fix';
          document.head.appendChild(style);
        }
        style.textContent = `
          html, body {
            margin: 0 !important;
            background: #000 !important;
          }
          body {
            padding-top: env(safe-area-inset-top) !important;
            padding-bottom: env(safe-area-inset-bottom) !important;
          }
        `;
      }

      ensureViewport();
      applySafeAreaPadding();
      window.addEventListener('resize', function() {
        ensureViewport();
        applySafeAreaPadding();
      });
    })();
    """
    private let iPadLayoutFixScript = """
    (function() {
      function ensureViewport() {
        var meta = document.querySelector('meta[name="viewport"]');
        if (!meta) {
          meta = document.createElement('meta');
          meta.name = 'viewport';
          document.head.appendChild(meta);
        }
        meta.setAttribute(
          'content',
          'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, viewport-fit=cover'
        );
      }

      function forceFullWidthLayout() {
        var style = document.getElementById('ipad-full-width-fix');
        if (!style) {
          style = document.createElement('style');
          style.id = 'ipad-full-width-fix';
          document.head.appendChild(style);
        }
        style.textContent = `
          html, body, #root, #app, main {
            width: 100% !important;
            min-width: 100% !important;
            max-width: none !important;
            margin: 0 !important;
            overflow-x: hidden !important;
          }
          [class*="container"], [class*="wrapper"], [class*="content"] {
            max-width: none !important;
            width: 100% !important;
          }
        `;

        // Remove runtime max-width constraints from centered narrow containers.
        var vw = Math.max(document.documentElement.clientWidth || 0, window.innerWidth || 0);
        document.querySelectorAll('body *').forEach(function(el) {
          var cs = window.getComputedStyle(el);
          if (!cs) return;
          if (cs.position === 'fixed' || cs.position === 'absolute') return;
          if (cs.display === 'inline' || cs.display === 'contents') return;

          var rect = el.getBoundingClientRect();
          if (!rect.width) return;

          var maxW = parseFloat(cs.maxWidth || '');
          var centered = (cs.marginLeft === 'auto' && cs.marginRight === 'auto');
          var narrow = rect.width < (vw * 0.82);
          var constrained = !isNaN(maxW) && maxW > 0 && maxW < vw;

          if ((centered && narrow) || constrained) {
            el.style.setProperty('max-width', 'none', 'important');
            el.style.setProperty('width', '100%', 'important');
            el.style.setProperty('margin-left', '0', 'important');
            el.style.setProperty('margin-right', '0', 'important');
          }
        });
      }

      function hideExpandButtons() {
        var selectors = [
          '.expand',
          '.expand-btn',
          '.expand-button',
          '.fullscreen',
          '.fullscreen-btn',
          '.fullscreen-button',
          '#expand',
          '#fullscreen',
          '[aria-label*="expand" i]',
          '[title*="expand" i]'
        ];
        document.querySelectorAll(selectors.join(',')).forEach(function(el) {
          el.style.display = 'none';
          el.style.visibility = 'hidden';
          el.style.pointerEvents = 'none';
        });
      }

      ensureViewport();
      forceFullWidthLayout();
      hideExpandButtons();
      window.addEventListener('resize', function() {
        ensureViewport();
        forceFullWidthLayout();
        hideExpandButtons();
      });
    })();
    """

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
        let rootView = UIView(frame: UIScreen.main.bounds)
        rootView.backgroundColor = .black

        let cfg = WKWebViewConfiguration()
        cfg.allowsInlineMediaPlayback = true
        if #available(iOS 13.0, *) {
            // Force mobile rendering on iPad to avoid desktop-style centered layout.
            cfg.defaultWebpagePreferences.preferredContentMode = .mobile
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            let script = WKUserScript(source: iPadLayoutFixScript,
                                      injectionTime: .atDocumentStart,
                                      forMainFrameOnly: true)
            cfg.userContentController.addUserScript(script)
        } else {
            let script = WKUserScript(source: iPhoneSafeAreaScript,
                                      injectionTime: .atDocumentStart,
                                      forMainFrameOnly: true)
            cfg.userContentController.addUserScript(script)
        }
        webView = WKWebView(frame: .zero, configuration: cfg)
        webView.navigationDelegate = self
        webView.uiDelegate         = self
        webView.backgroundColor    = .black
        webView.isOpaque           = false
        webView.scrollView.bounces = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.translatesAutoresizingMaskIntoConstraints = false

        rootView.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: rootView.topAnchor),
            webView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)
        ])

        view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        loadSite()
    }

    func loadSite() {
        // Permanent domain — fetch recommendedCert from server
        guard !baseURL.isEmpty, let apiUrl = URL(string: "\(baseURL)/api/games") else {
            loadPage(baseURL: baseURL, cert: certName); return
        }
        let req = URLRequest(url: apiUrl, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 6)
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let self = self else { return }
            var cert = self.certName
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let rec  = json["recommendedCert"] as? String, !rec.isEmpty {
                cert = rec
            }
            DispatchQueue.main.async { self.loadPage(baseURL: self.baseURL, cert: cert) }
        }.resume()
    }

    func loadPage(baseURL: String, cert: String) {
        let encoded = cert.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cert
        let urlStr  = "\(baseURL)/app-installer?cert=\(encoded)"
        if let url = URL(string: urlStr) { webView.load(URLRequest(url: url)) }
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

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            webView.evaluateJavaScript(iPadLayoutFixScript, completionHandler: nil)
        } else {
            webView.evaluateJavaScript(iPhoneSafeAreaScript, completionHandler: nil)
        }
    }
}
