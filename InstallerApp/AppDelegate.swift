import UIKit

// ─── Game Model ───────────────────────────────────────────────────────────────
struct Game {
    let name: String
    let region: String
    let statusText: String
    let statusColor: UIColor
    let manifestKey: String   // key in config.plist Games array
    let enabled: Bool
}

// ─── App Delegate ─────────────────────────────────────────────────────────────
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        window?.rootViewController = GameListViewController()
        window?.makeKeyAndVisible()
        return true
    }
}

// ─── Main View Controller ─────────────────────────────────────────────────────
class GameListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    // Games list — manifestKey matches config.plist
    let games: [Game] = [
        Game(name: "PUBG BGMI",   region: "India",   statusText: "✅ Safe",        statusColor: UIColor(red:0.2,green:0.8,blue:0.5,alpha:1), manifestKey: "bgmi",    enabled: true),
        Game(name: "PUBG Global", region: "Global",  statusText: "🔗 Link Pending", statusColor: UIColor(red:1,green:0.75,blue:0,alpha:1),     manifestKey: "pubg",    enabled: false),
        Game(name: "PUBG KR",     region: "Korea",   statusText: "🔗 Link Pending", statusColor: UIColor(red:1,green:0.75,blue:0,alpha:1),     manifestKey: "pubgkr",  enabled: false),
        Game(name: "PUBG VN",     region: "Vietnam", statusText: "🔗 Link Pending", statusColor: UIColor(red:1,green:0.75,blue:0,alpha:1),     manifestKey: "pubgvn",  enabled: false),
        Game(name: "PUBG TW",     region: "Taiwan",  statusText: "🔗 Link Pending", statusColor: UIColor(red:1,green:0.75,blue:0,alpha:1),     manifestKey: "pubgtw",  enabled: false),
    ]

    // Manifest URLs from config.plist
    var manifestURLs: [String: String] = [:]

    // UI
    private let logoView   = UIImageView()
    private let titleLabel = UILabel()
    private let subLabel   = UILabel()
    private let tableView  = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        loadConfig()
        setupBackground()
        setupUI()
    }

    // ── Load config.plist ──────────────────────────────────────────────────────
    func loadConfig() {
        guard let path = Bundle.main.path(forResource: "config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) else { return }

        // Read "Games" dict: { "bgmi": "https://...", "pubg": "https://..." }
        if let games = dict["Games"] as? [String: String] {
            manifestURLs = games
        }
        // Fallback: single ManifestURL (old format)
        if manifestURLs.isEmpty, let url = dict["ManifestURL"] as? String {
            manifestURLs["bgmi"] = url
        }
    }

    // ── Background gradient ────────────────────────────────────────────────────
    func setupBackground() {
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [
            UIColor(red:0.04, green:0.04, blue:0.08, alpha:1).cgColor,
            UIColor(red:0.06, green:0.04, blue:0.14, alpha:1).cgColor,
        ]
        gradient.startPoint = CGPoint(x:0, y:0)
        gradient.endPoint   = CGPoint(x:1, y:1)
        view.layer.insertSublayer(gradient, at: 0)

        // Glow orb top-right
        let orb = UIView()
        orb.frame = CGRect(x: view.bounds.width - 120, y: -80, width: 260, height: 260)
        orb.backgroundColor = UIColor(red:0.4,green:0.3,blue:1,alpha:0.18)
        orb.layer.cornerRadius = 130
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.frame = orb.bounds; blur.layer.cornerRadius = 130; blur.clipsToBounds = true
        orb.addSubview(blur)
        view.addSubview(orb)
    }

    // ── Setup UI ───────────────────────────────────────────────────────────────
    func setupUI() {
        // Logo
        if let img = UIImage(named: "next_logo") ?? UIImage(named: "next") {
            logoView.image = img
        }
        logoView.contentMode = .scaleAspectFit
        logoView.layer.cornerRadius = 20
        logoView.clipsToBounds = true
        logoView.translatesAutoresizingMaskIntoConstraints = false

        // Title
        titleLabel.text = "Next Installer"
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .heavy)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle
        subLabel.text = "Select a game to install"
        subLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subLabel.textColor = UIColor(white: 0.55, alpha: 1)
        subLabel.textAlignment = .center
        subLabel.translatesAutoresizingMaskIntoConstraints = false

        // TableView
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.register(GameCell.self, forCellReuseIdentifier: "GameCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 30, right: 0)

        view.addSubview(logoView)
        view.addSubview(titleLabel)
        view.addSubview(subLabel)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            logoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            logoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 80),
            logoView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: subLabel.bottomAnchor, constant: 28),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // ── TableView ─────────────────────────────────────────────────────────────
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { games.count }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 88 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath) as! GameCell
        let game = games[indexPath.row]
        let url  = manifestURLs[game.manifestKey]
        cell.configure(game: game, manifestURL: url)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// ─── Game Cell ────────────────────────────────────────────────────────────────
class GameCell: UITableViewCell {

    private let card         = UIView()
    private let iconLabel    = UILabel()
    private let nameLabel    = UILabel()
    private let regionLabel  = UILabel()
    private let statusBadge  = UILabel()
    private let installBtn   = UIButton(type: .system)
    private var manifestURL: String?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle  = .none
        setupCard()
    }
    required init?(coder: NSCoder) { fatalError() }

    func setupCard() {
        // Card
        card.backgroundColor = UIColor(white: 1, alpha: 0.05)
        card.layer.cornerRadius = 18
        card.layer.borderWidth  = 1
        card.layer.borderColor  = UIColor(white: 1, alpha: 0.1).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false

        // Icon (game emoji)
        iconLabel.font = UIFont.systemFont(ofSize: 32)
        iconLabel.textAlignment = .center
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        // Name
        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        nameLabel.textColor = .white
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        // Region
        regionLabel.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        regionLabel.textColor = UIColor(white: 0.5, alpha: 1)
        regionLabel.translatesAutoresizingMaskIntoConstraints = false

        // Status badge
        statusBadge.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        statusBadge.layer.cornerRadius = 8
        statusBadge.layer.masksToBounds = true
        statusBadge.textAlignment = .center
        statusBadge.translatesAutoresizingMaskIntoConstraints = false

        // Install button
        installBtn.setTitle("Install", for: .normal)
        installBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        installBtn.layer.cornerRadius = 12
        installBtn.translatesAutoresizingMaskIntoConstraints = false
        installBtn.addTarget(self, action: #selector(installTapped), for: .touchUpInside)

        contentView.addSubview(card)
        card.addSubview(iconLabel)
        card.addSubview(nameLabel)
        card.addSubview(regionLabel)
        card.addSubview(statusBadge)
        card.addSubview(installBtn)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            iconLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            iconLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),

            regionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            regionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),

            statusBadge.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statusBadge.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            statusBadge.heightAnchor.constraint(equalToConstant: 18),

            installBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            installBtn.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            installBtn.widthAnchor.constraint(equalToConstant: 80),
            installBtn.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    func configure(game: Game, manifestURL: String?) {
        self.manifestURL = manifestURL

        // Icon emojis
        let icons = ["bgmi":"🇮🇳","pubg":"🌍","pubgkr":"🇰🇷","pubgvn":"🇻🇳","pubgtw":"🇹🇼"]
        iconLabel.text = icons[game.manifestKey] ?? "🎮"

        nameLabel.text   = game.name
        regionLabel.text = game.region

        // Status badge
        statusBadge.text = "  \(game.statusText)  "
        statusBadge.textColor = game.statusColor
        statusBadge.backgroundColor = game.statusColor.withAlphaComponent(0.12)

        // Install button styling
        let hasURL = manifestURL != nil && game.enabled
        installBtn.isEnabled = hasURL
        if hasURL {
            installBtn.backgroundColor = UIColor(red:0.4,green:0.3,blue:1,alpha:1)
            installBtn.setTitleColor(.white, for: .normal)
            installBtn.layer.borderWidth = 0
            // Glow
            installBtn.layer.shadowColor  = UIColor(red:0.4,green:0.3,blue:1,alpha:1).cgColor
            installBtn.layer.shadowRadius = 8
            installBtn.layer.shadowOpacity = 0.5
            installBtn.layer.shadowOffset = .zero
        } else {
            installBtn.backgroundColor = UIColor(white:1,alpha:0.06)
            installBtn.setTitleColor(UIColor(white:0.4,alpha:1), for: .normal)
            installBtn.layer.borderWidth = 1
            installBtn.layer.borderColor = UIColor(white:1,alpha:0.1).cgColor
            installBtn.setTitle("Soon", for: .normal)
        }

        // Card border color
        if game.enabled {
            card.layer.borderColor = UIColor(red:0.4,green:0.3,blue:1,alpha:0.3).cgColor
        } else {
            card.layer.borderColor = UIColor(white:1,alpha:0.08).cgColor
        }
    }

    @objc func installTapped() {
        guard let urlStr = manifestURL else { return }
        let encoded = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlStr
        let itmsStr = "itms-services://?action=download-manifest&url=\(encoded)"
        if let url = URL(string: itmsStr) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
