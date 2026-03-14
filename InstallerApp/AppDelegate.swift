import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // ── CHANGE THIS URL ────────────────────────────────────────────────────────
    // Apna server ka manifest URL daalo (certificate name aur app name ke saath)
    // Example: https://192.168.1.65:3443/manifest/NationalOilwell/bgmi
    let manifestURL = "https://192.168.1.65:3443/manifest/Takeoff/bgmi"
    // ──────────────────────────────────────────────────────────────────────────

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Setup a minimal window
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        window?.rootViewController = LaunchViewController(manifestURL: manifestURL)
        window?.makeKeyAndVisible()
        return true
    }
}

// ── Launch Screen ──────────────────────────────────────────────────────────────
class LaunchViewController: UIViewController {

    let manifestURL: String

    init(manifestURL: String) {
        self.manifestURL = manifestURL
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1)

        // Logo label
        let logo = UILabel()
        logo.text = "🎮"
        logo.font = .systemFont(ofSize: 80)
        logo.textAlignment = .center
        logo.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "Game Installer"
        title.font = .boldSystemFont(ofSize: 24)
        title.textColor = .white
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel()
        subtitle.text = "Installing game..."
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = UIColor(white: 0.6, alpha: 1)
        subtitle.textAlignment = .center
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [logo, title, subtitle])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Trigger itms-services installation after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            let encoded = self.manifestURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self.manifestURL
            let itmsURLString = "itms-services://?action=download-manifest&url=\(encoded)"

            if let itmsURL = URL(string: itmsURLString) {
                UIApplication.shared.open(itmsURL, options: [:]) { success in
                    if !success {
                        // Fallback: open in Safari
                        if let safarURL = URL(string: "https://YOUR_SERVER/install.html") {
                            UIApplication.shared.open(safarURL)
                        }
                    }
                }
            }
        }
    }
}
