import UIKit

// ─── Game Model ───────────────────────────────────────────────────────────────
struct Game {
    let name: String
    let subtitle: String
    let iconName: String   // asset name in bundle
    let statusText: String
    let isAvailable: Bool
    let manifestKey: String
}

// ─── AppDelegate ──────────────────────────────────────────────────────────────
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = GameListVC()
        window?.makeKeyAndVisible()
        return true
    }
}

// ─── Main VC ──────────────────────────────────────────────────────────────────
class GameListVC: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let games: [Game] = [
        Game(name: "BGMI",        subtitle: "Battlegrounds Mobile India", iconName: "BGMI",    statusText: "Safe",         isAvailable: true,  manifestKey: "bgmi"),
        Game(name: "PUBG Global", subtitle: "PUBG Mobile – Global",       iconName: "GL",      statusText: "Coming Soon",  isAvailable: false, manifestKey: "pubg"),
        Game(name: "PUBG KR",     subtitle: "PUBG Mobile – Korea",        iconName: "KR",      statusText: "Coming Soon",  isAvailable: false, manifestKey: "pubgkr"),
        Game(name: "PUBG VN",     subtitle: "PUBG Mobile – Vietnam",      iconName: "VN",      statusText: "Coming Soon",  isAvailable: false, manifestKey: "pubgvn"),
        Game(name: "PUBG TW",     subtitle: "PUBG Mobile – Taiwan",       iconName: "TW",      statusText: "Coming Soon",  isAvailable: false, manifestKey: "pubgtw"),
    ]

    var manifestURLs: [String: String] = [:]

    private let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        loadConfig()
        setupBG()
        setupHeader()
        setupTable()
    }

    func loadConfig() {
        guard let path = Bundle.main.path(forResource: "config", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let gamesDict = dict["Games"] as? [String: String] else { return }
        manifestURLs = gamesDict.filter { !$0.value.isEmpty }
    }

    func setupBG() {
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.10, alpha: 1)
        let g = CAGradientLayer()
        g.frame = view.bounds
        g.colors = [UIColor(red:0.06,green:0.05,blue:0.14,alpha:1).cgColor,
                    UIColor(red:0.04,green:0.04,blue:0.08,alpha:1).cgColor]
        g.startPoint = CGPoint(x:0,y:0); g.endPoint = CGPoint(x:1,y:1)
        view.layer.insertSublayer(g, at: 0)

        // Glow blob top right
        let blob = UIView(frame: CGRect(x: view.bounds.width - 100, y: -100, width: 280, height: 280))
        blob.backgroundColor = UIColor(red:0.35,green:0.25,blue:0.95,alpha:0.22)
        blob.layer.cornerRadius = 140
        let blurFx = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurFx.frame = blob.bounds; blurFx.layer.cornerRadius = 140; blurFx.clipsToBounds = true
        blob.addSubview(blurFx)
        view.addSubview(blob)
    }

    func setupHeader() {
        // Logo image
        let logoIV = UIImageView()
        if let data = loadBundleFile("next.png"), let img = UIImage(data: data) {
            logoIV.image = img
        }
        logoIV.contentMode = .scaleAspectFill
        logoIV.layer.cornerRadius = 22
        logoIV.clipsToBounds = true
        logoIV.layer.shadowColor = UIColor(red:0.4,green:0.3,blue:1,alpha:1).cgColor
        logoIV.layer.shadowRadius = 20; logoIV.layer.shadowOpacity = 0.6; logoIV.layer.shadowOffset = .zero
        logoIV.translatesAutoresizingMaskIntoConstraints = false

        let titleL = UILabel()
        titleL.text = "Next Installer"
        titleL.font = UIFont.systemFont(ofSize: 30, weight: .black)
        titleL.textColor = .white; titleL.textAlignment = .center
        titleL.translatesAutoresizingMaskIntoConstraints = false

        let subL = UILabel()
        subL.text = "Select a game to install"
        subL.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        subL.textColor = UIColor(white:0.5,alpha:1); subL.textAlignment = .center
        subL.translatesAutoresizingMaskIntoConstraints = false

        // Divider
        let divider = UIView()
        divider.backgroundColor = UIColor(white:1,alpha:0.07)
        divider.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(logoIV); view.addSubview(titleL); view.addSubview(subL); view.addSubview(divider)

        NSLayoutConstraint.activate([
            logoIV.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 28),
            logoIV.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoIV.widthAnchor.constraint(equalToConstant: 84),
            logoIV.heightAnchor.constraint(equalToConstant: 84),

            titleL.topAnchor.constraint(equalTo: logoIV.bottomAnchor, constant: 16),
            titleL.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleL.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subL.topAnchor.constraint(equalTo: titleL.bottomAnchor, constant: 5),
            subL.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subL.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            divider.topAnchor.constraint(equalTo: subL.bottomAnchor, constant: 24),
            divider.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
        ])

        // Store divider bottom for table
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 16),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])
    }

    func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self; tableView.delegate = self
        tableView.register(GameCell.self, forCellReuseIdentifier: "cell")
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        tableView.showsVerticalScrollIndicator = false
    }

    // Helper — load file from bundle regardless of extension
    func loadBundleFile(_ name: String) -> Data? {
        if let url = Bundle.main.url(forResource: name, withExtension: nil) {
            return try? Data(contentsOf: url)
        }
        let parts = name.components(separatedBy: ".")
        if parts.count == 2, let url = Bundle.main.url(forResource: parts[0], withExtension: parts[1]) {
            return try? Data(contentsOf: url)
        }
        return nil
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { games.count }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 96 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! GameCell
        let g = games[indexPath.row]; let url = manifestURLs[g.manifestKey]
        cell.configure(game: g, manifestURL: url, vc: self)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// ─── Game Cell ────────────────────────────────────────────────────────────────
class GameCell: UITableViewCell {

    private let card      = UIView()
    private let iconIV    = UIImageView()
    private let nameL     = UILabel()
    private let subL      = UILabel()
    private let badge     = UILabel()
    private let btn       = UIButton(type: .custom)
    private var manifestURL: String?
    private weak var vc: GameListVC?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear; selectionStyle = .none
        buildLayout()
    }
    required init?(coder: NSCoder) { fatalError() }

    func buildLayout() {
        // Card
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1
        card.clipsToBounds = false
        card.translatesAutoresizingMaskIntoConstraints = false

        // Icon
        iconIV.contentMode = .scaleAspectFill
        iconIV.layer.cornerRadius = 16
        iconIV.clipsToBounds = true
        iconIV.layer.borderWidth = 1
        iconIV.layer.borderColor = UIColor(white:1,alpha:0.1).cgColor
        iconIV.translatesAutoresizingMaskIntoConstraints = false
        iconIV.backgroundColor = UIColor(white:0.1,alpha:1)

        // Name
        nameL.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        nameL.textColor = .white
        nameL.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle
        subL.font = UIFont.systemFont(ofSize: 11, weight: .regular)
        subL.textColor = UIColor(white:0.45,alpha:1)
        subL.translatesAutoresizingMaskIntoConstraints = false

        // Badge
        badge.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        badge.layer.cornerRadius = 7; badge.layer.masksToBounds = true
        badge.textAlignment = .center
        badge.translatesAutoresizingMaskIntoConstraints = false

        // Button
        btn.layer.cornerRadius = 13
        btn.clipsToBounds = true
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(installTapped), for: .touchUpInside)
        btn.addTarget(self, action: #selector(btnDown), for: .touchDown)
        btn.addTarget(self, action: #selector(btnUp), for: [.touchUpInside,.touchUpOutside,.touchCancel])

        let inner = UIView()   // inner card container (for blur bg)
        inner.backgroundColor = UIColor(white:1,alpha:0.04)
        inner.layer.cornerRadius = 20
        inner.translatesAutoresizingMaskIntoConstraints = false
        inner.clipsToBounds = true

        contentView.addSubview(card)
        card.addSubview(inner)
        card.addSubview(iconIV)
        card.addSubview(nameL)
        card.addSubview(subL)
        card.addSubview(badge)
        card.addSubview(btn)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 7),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -7),

            inner.topAnchor.constraint(equalTo: card.topAnchor),
            inner.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            inner.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            inner.bottomAnchor.constraint(equalTo: card.bottomAnchor),

            iconIV.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            iconIV.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconIV.widthAnchor.constraint(equalToConstant: 56),
            iconIV.heightAnchor.constraint(equalToConstant: 56),

            nameL.leadingAnchor.constraint(equalTo: iconIV.trailingAnchor, constant: 14),
            nameL.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            nameL.trailingAnchor.constraint(equalTo: btn.leadingAnchor, constant: -10),

            subL.leadingAnchor.constraint(equalTo: nameL.leadingAnchor),
            subL.topAnchor.constraint(equalTo: nameL.bottomAnchor, constant: 3),
            subL.trailingAnchor.constraint(equalTo: nameL.trailingAnchor),

            badge.leadingAnchor.constraint(equalTo: nameL.leadingAnchor),
            badge.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            badge.heightAnchor.constraint(equalToConstant: 18),

            btn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            btn.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            btn.widthAnchor.constraint(equalToConstant: 90),
            btn.heightAnchor.constraint(equalToConstant: 40),
        ])
    }

    func configure(game: Game, manifestURL: String?, vc: GameListVC) {
        self.manifestURL = manifestURL
        self.vc = vc

        // Load icon from bundle
        let iconFile = game.iconName + ".webp"
        if let data = vc.loadBundleFile(iconFile), let img = UIImage(data: data) {
            iconIV.image = img
        } else if let img = UIImage(named: game.iconName) {
            iconIV.image = img
        } else {
            iconIV.image = nil
            iconIV.backgroundColor = UIColor(red:0.2,green:0.15,blue:0.4,alpha:1)
        }

        nameL.text = game.name
        subL.text  = game.subtitle

        let enabled = game.isAvailable && manifestURL != nil

        // Status badge
        if game.isAvailable {
            badge.text = "  ✅ \(game.statusText)  "
            badge.textColor      = UIColor(red:0.2,green:0.9,blue:0.55,alpha:1)
            badge.backgroundColor = UIColor(red:0.1,green:0.7,blue:0.4,alpha:0.18)
        } else {
            badge.text = "  ⏳ \(game.statusText)  "
            badge.textColor      = UIColor(red:1,green:0.78,blue:0.2,alpha:1)
            badge.backgroundColor = UIColor(red:0.8,green:0.6,blue:0.1,alpha:0.15)
        }

        // Card styling
        if enabled {
            card.layer.borderColor = UIColor(red:0.42,green:0.32,blue:1,alpha:0.45).cgColor
            card.layer.shadowColor  = UIColor(red:0.42,green:0.32,blue:1,alpha:1).cgColor
            card.layer.shadowRadius = 14; card.layer.shadowOpacity = 0.3; card.layer.shadowOffset = .zero
        } else {
            card.layer.borderColor   = UIColor(white:1,alpha:0.08).cgColor
            card.layer.shadowOpacity = 0
        }

        // Button
        if enabled {
            let gl = makeGradient()
            gl.frame = CGRect(x:0,y:0,width:90,height:40)
            btn.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
            btn.layer.insertSublayer(gl, at: 0)
            btn.setTitle("Install", for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.isEnabled = true
            btn.alpha = 1
        } else {
            btn.layer.sublayers?.filter { $0 is CAGradientLayer }.forEach { $0.removeFromSuperlayer() }
            btn.backgroundColor = UIColor(white:1,alpha:0.07)
            btn.setTitle("Soon", for: .normal)
            btn.setTitleColor(UIColor(white:0.35,alpha:1), for: .normal)
            btn.isEnabled = false
            btn.alpha = 1
            btn.layer.borderWidth = 1
            btn.layer.borderColor = UIColor(white:1,alpha:0.1).cgColor
        }
    }

    func makeGradient() -> CAGradientLayer {
        let g = CAGradientLayer()
        g.colors = [UIColor(red:0.5,green:0.3,blue:1,alpha:1).cgColor,
                    UIColor(red:0.3,green:0.2,blue:0.9,alpha:1).cgColor]
        g.startPoint = CGPoint(x:0,y:0); g.endPoint = CGPoint(x:1,y:1)
        g.cornerRadius = 13
        return g
    }

    @objc func installTapped() {
        guard let url = manifestURL else { return }
        let encoded = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? url
        if let u = URL(string: "itms-services://?action=download-manifest&url=\(encoded)") {
            UIApplication.shared.open(u, options: [:], completionHandler: nil)
        }
    }
    @objc func btnDown() { UIView.animate(withDuration: 0.1) { self.btn.transform = CGAffineTransform(scaleX: 0.95, y: 0.95) } }
    @objc func btnUp()   { UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 3, options: [], animations: { self.btn.transform = .identity }, completion: nil) }
}
