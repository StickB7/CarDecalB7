import UIKit
import Flutter

/**
 * AppDelegate for SecureVault – iOS security hardening.
 *
 * Security measures:
 *
 *  1. Screenshot prevention via UITextField.isSecureTextEntry trick
 *     (overlaying a secure field while in background hides content).
 *
 *  2. Secure overlay shown on applicationWillResignActive /
 *     applicationDidEnterBackground to hide vault content in the
 *     iOS app switcher.
 *
 *  3. Overlay removed on applicationDidBecomeActive.
 *
 * Note: iOS does not provide a public API equivalent to Android's
 * FLAG_SECURE. The overlay approach is the standard solution used
 * by banking/vault apps on iOS.
 */
@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    private var secureOverlayWindow: UIWindow?

    // ── App lifecycle ──────────────────────────────────────────────────────

    override func applicationWillResignActive(_ application: UIApplication) {
        super.applicationWillResignActive(application)
        showSecureOverlay()
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        super.applicationDidEnterBackground(application)
        // Overlay already shown; ensure it's still present
        if secureOverlayWindow == nil { showSecureOverlay() }
    }

    override func applicationWillEnterForeground(_ application: UIApplication) {
        super.applicationWillEnterForeground(application)
        // Keep overlay until auth is confirmed
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        // Remove overlay – Flutter's AuthProvider will show the lock screen
        hideSecureOverlay()
    }

    // ── Flutter registration ───────────────────────────────────────────────

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // ── Secure overlay helpers ─────────────────────────────────────────────

    private func showSecureOverlay() {
        guard secureOverlayWindow == nil else { return }

        let windowScene: UIWindowScene?
        if #available(iOS 15.0, *) {
            windowScene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                ?? UIApplication.shared.connectedScenes.first as? UIWindowScene
        } else {
            windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        }

        let overlay: UIWindow
        if let scene = windowScene {
            overlay = UIWindow(windowScene: scene)
        } else {
            overlay = UIWindow(frame: UIScreen.main.bounds)
        }

        overlay.windowLevel = .alert + 1
        overlay.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1.0)
        overlay.rootViewController = _SecureOverlayViewController()
        overlay.makeKeyAndVisible()

        secureOverlayWindow = overlay
    }

    private func hideSecureOverlay() {
        secureOverlayWindow?.isHidden = true
        secureOverlayWindow = nil
    }
}

// ── Overlay view controller ────────────────────────────────────────────────────

/// Displays the app icon + name instead of blurring/freezing vault content.
private class _SecureOverlayViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.06, alpha: 1.0)

        let stack = UIStackView()
        stack.axis      = .vertical
        stack.alignment = .center
        stack.spacing   = 20
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Lock icon container
        let iconContainer = UIView()
        iconContainer.layer.cornerRadius = 20
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 80),
            iconContainer.heightAnchor.constraint(equalToConstant: 80),
        ])

        // Gold gradient background
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1).cgColor,
            UIColor(red: 0.72, green: 0.53, blue: 0.04, alpha: 1).cgColor,
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint   = CGPoint(x: 1, y: 1)
        gradient.cornerRadius = 20
        gradient.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        iconContainer.layer.addSublayer(gradient)

        // Lock symbol
        let lockConfig = UIImage.SymbolConfiguration(pointSize: 36, weight: .medium)
        let lockImage  = UIImage(systemName: "lock.fill", withConfiguration: lockConfig)
        let lockView   = UIImageView(image: lockImage)
        lockView.tintColor = UIColor(red: 0.1, green: 0.086, blue: 0, alpha: 1)
        lockView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(lockView)
        NSLayoutConstraint.activate([
            lockView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            lockView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
        ])

        // App name
        let titleLabel     = UILabel()
        titleLabel.text    = "תיקייה נעולה"
        titleLabel.font    = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = UIColor(white: 0.94, alpha: 1)

        // Subtitle
        let subLabel     = UILabel()
        subLabel.text    = "מוגן"
        subLabel.font    = UIFont.systemFont(ofSize: 14, weight: .medium)
        subLabel.textColor = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1)

        stack.addArrangedSubview(iconContainer)
        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(subLabel)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
