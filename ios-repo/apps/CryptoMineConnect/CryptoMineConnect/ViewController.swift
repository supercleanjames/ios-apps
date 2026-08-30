import UIKit
import WebKit
import SafariServices

final class ViewController: UIViewController {

    // MARK: - Configuration
    private let targetURL = URL(string: "https://cryptomineconnect.live")!
    private let wordmark = "CRYPTOMINE CONNECT"
    private let tagline = "Remote monitoring for crypto mining rigs"
    private let brandBackground = UIColor(hexString: "0A0F0A")
    private let brandAccent = UIColor(hexString: "4CD964")

    // MARK: - Views
    private var webView: WKWebView!
    private let loadingView = UIView()
    private let errorView = UIView()
    private let spinner = UIActivityIndicatorView(style: .large)
    private let statusLabel = UILabel()
    private let errorTitleLabel = UILabel()
    private let errorDetailLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private let disclaimerBar = UIView()

    // MARK: - State
    private var watchdogTimer: Timer?
    private var slowNoticeTimer: Timer?
    private var hasLoadedOnce = false
    private let firstLoadTimeout: TimeInterval = 30
    private let slowNoticeDelay: TimeInterval = 6

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = brandBackground
        setUpDisclaimerBar()
        setUpWebView()
        setUpLoadingView()
        setUpErrorView()
        startLoad()
    }

    deinit {
        watchdogTimer?.invalidate()
        slowNoticeTimer?.invalidate()
    }

    // MARK: - Setup
    private func setUpWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.websiteDataStore = .default()

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = brandBackground
        webView.scrollView.backgroundColor = brandBackground
        webView.alpha = 0
        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: disclaimerBar.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = brandAccent
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
    }

    private func setUpLoadingView() {
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        loadingView.backgroundColor = brandBackground
        view.addSubview(loadingView)
        pin(loadingView, to: view)

        let markLabel = UILabel()
        markLabel.text = wordmark
        markLabel.font = .systemFont(ofSize: 34, weight: .heavy)
        markLabel.textColor = .white
        markLabel.textAlignment = .center
        markLabel.adjustsFontSizeToFitWidth = true
        markLabel.minimumScaleFactor = 0.6

        let taglineLabel = UILabel()
        taglineLabel.text = tagline
        taglineLabel.font = .systemFont(ofSize: 15, weight: .medium)
        taglineLabel.textColor = brandAccent
        taglineLabel.textAlignment = .center
        taglineLabel.numberOfLines = 2

        spinner.color = brandAccent
        spinner.startAnimating()

        statusLabel.text = "Connecting…"
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = UIColor(white: 0.65, alpha: 1)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 2

        let loadingDisclaimer = UILabel()
        loadingDisclaimer.text = "AI-assisted content · Not financial advice"
        loadingDisclaimer.font = .systemFont(ofSize: 11, weight: .medium)
        loadingDisclaimer.textColor = UIColor(white: 0.45, alpha: 1)
        loadingDisclaimer.textAlignment = .center
        loadingDisclaimer.numberOfLines = 2

        let stack = UIStackView(arrangedSubviews: [markLabel, taglineLabel, spinner, statusLabel, loadingDisclaimer])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.setCustomSpacing(28, after: taglineLabel)
        stack.setCustomSpacing(26, after: statusLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: loadingView.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: loadingView.trailingAnchor, constant: -32)
        ])
    }

    private func setUpErrorView() {
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.backgroundColor = brandBackground
        errorView.isHidden = true
        view.addSubview(errorView)
        pin(errorView, to: view)

        errorTitleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        errorTitleLabel.textColor = .white
        errorTitleLabel.textAlignment = .center
        errorTitleLabel.numberOfLines = 2

        errorDetailLabel.font = .systemFont(ofSize: 15)
        errorDetailLabel.textColor = UIColor(white: 0.7, alpha: 1)
        errorDetailLabel.textAlignment = .center
        errorDetailLabel.numberOfLines = 0

        retryButton.setTitle("Try Again", for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        retryButton.setTitleColor(brandBackground, for: .normal)
        retryButton.backgroundColor = brandAccent
        retryButton.layer.cornerRadius = 12
        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            retryButton.heightAnchor.constraint(equalToConstant: 50),
            retryButton.widthAnchor.constraint(equalToConstant: 200)
        ])

        let stack = UIStackView(arrangedSubviews: [errorTitleLabel, errorDetailLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(28, after: errorDetailLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        errorView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: errorView.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: errorView.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: errorView.trailingAnchor, constant: -32)
        ])
    }

    private func setUpDisclaimerBar() {
        disclaimerBar.backgroundColor = UIColor(white: 0.07, alpha: 1)
        disclaimerBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(disclaimerBar)

        let hairline = UIView()
        hairline.backgroundColor = UIColor(white: 0.18, alpha: 1)
        hairline.translatesAutoresizingMaskIntoConstraints = false
        disclaimerBar.addSubview(hairline)

        let label = UILabel()
        label.text = "AI-assisted content · Informational only · Not financial advice — tap"
        label.font = .systemFont(ofSize: 10.5, weight: .medium)
        label.textColor = UIColor(white: 0.62, alpha: 1)
        label.textAlignment = .center
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.translatesAutoresizingMaskIntoConstraints = false
        disclaimerBar.addSubview(label)

        NSLayoutConstraint.activate([
            disclaimerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            disclaimerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            disclaimerBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            disclaimerBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -38),
            hairline.topAnchor.constraint(equalTo: disclaimerBar.topAnchor),
            hairline.leadingAnchor.constraint(equalTo: disclaimerBar.leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: disclaimerBar.trailingAnchor),
            hairline.heightAnchor.constraint(equalToConstant: 0.5),
            label.leadingAnchor.constraint(equalTo: disclaimerBar.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: disclaimerBar.trailingAnchor, constant: -12),
            label.topAnchor.constraint(equalTo: disclaimerBar.topAnchor, constant: 6)
        ])

        disclaimerBar.isUserInteractionEnabled = true
        disclaimerBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showDisclaimer)))
        disclaimerBar.isAccessibilityElement = true
        disclaimerBar.accessibilityLabel = "Legal disclaimer. Double tap to read."
        disclaimerBar.accessibilityTraits = .button
    }

    @objc private func showDisclaimer() {
        let vc = DisclaimerViewController(accent: brandAccent, background: brandBackground)
        vc.modalPresentationStyle = .pageSheet
        present(UINavigationController(rootViewController: vc), animated: true)
    }

    private func pin(_ child: UIView, to parent: UIView) {
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: parent.topAnchor),
            child.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: parent.trailingAnchor)
        ])
    }

    // MARK: - Loading
    private func startLoad() {
        errorView.isHidden = true
        loadingView.isHidden = false
        loadingView.alpha = 1
        spinner.startAnimating()
        statusLabel.text = "Connecting…"

        var request = URLRequest(url: targetURL)
        request.cachePolicy = .reloadRevalidatingCacheData
        request.timeoutInterval = firstLoadTimeout
        webView.load(request)
        scheduleTimers()
    }

    // Selector-based timers are used deliberately: the closure-based
    // Timer.scheduledTimer takes an @Sendable closure, which fails to compile in
    // the Swift 6 language mode when it captures a UIViewController.
    private func scheduleTimers() {
        slowNoticeTimer?.invalidate()
        slowNoticeTimer = Timer.scheduledTimer(timeInterval: slowNoticeDelay,
                                               target: self,
                                               selector: #selector(handleSlowNotice),
                                               userInfo: nil,
                                               repeats: false)

        watchdogTimer?.invalidate()
        watchdogTimer = Timer.scheduledTimer(timeInterval: firstLoadTimeout,
                                             target: self,
                                             selector: #selector(handleWatchdog),
                                             userInfo: nil,
                                             repeats: false)
    }

    @objc private func handleSlowNotice() {
        guard !hasLoadedOnce else { return }
        statusLabel.text = "Waking the server — this can take a few seconds."
    }

    @objc private func handleWatchdog() {
        guard !hasLoadedOnce else { return }
        webView.stopLoading()
        showError(title: "Taking longer than usual",
                  detail: "\(wordmark) could not be reached. Check your connection and try again.")
    }

    private func cancelTimers() {
        slowNoticeTimer?.invalidate()
        slowNoticeTimer = nil
        watchdogTimer?.invalidate()
        watchdogTimer = nil
    }

    private func revealContent() {
        hasLoadedOnce = true
        cancelTimers()
        webView.scrollView.refreshControl?.endRefreshing()
        errorView.isHidden = true

        guard loadingView.isHidden == false || webView.alpha < 1 else { return }
        UIView.animate(withDuration: 0.35, animations: {
            self.webView.alpha = 1
            self.loadingView.alpha = 0
        }, completion: { _ in
            self.loadingView.isHidden = true
            self.spinner.stopAnimating()
        })
    }

    private func showError(title: String, detail: String) {
        cancelTimers()
        webView.scrollView.refreshControl?.endRefreshing()
        spinner.stopAnimating()
        loadingView.isHidden = true
        loadingView.alpha = 1
        errorTitleLabel.text = title
        errorDetailLabel.text = detail
        errorView.isHidden = false
    }

    private func handleFailure(_ error: Error) {
        let nsError = error as NSError
        webView.scrollView.refreshControl?.endRefreshing()
        guard nsError.code != NSURLErrorCancelled else { return }
        guard !hasLoadedOnce else { return }

        let detail: String
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet:
            detail = "You appear to be offline. Connect to the internet and try again."
        case NSURLErrorTimedOut:
            detail = "The server took too long to respond. Please try again."
        default:
            detail = "\(wordmark) could not be reached right now. Please try again."
        }
        showError(title: "Can't load \(wordmark)", detail: detail)
    }

    private func presentInAppBrowser(_ url: URL) {
        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = brandAccent
        present(safari, animated: true)
    }

    // MARK: - Actions
    @objc private func handleRetry() {
        startLoad()
    }

    @objc private func handlePullToRefresh() {
        if hasLoadedOnce {
            webView.reload()
        } else {
            startLoad()
        }
    }
}

// MARK: - WKNavigationDelegate
extension ViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        if !hasLoadedOnce {
            statusLabel.text = "Loading…"
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        revealContent()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleFailure(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleFailure(error)
    }

    /// Under memory pressure WebKit can kill the content process. Without this the
    /// web view silently goes blank and no other delegate callback ever fires.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        if hasLoadedOnce {
            webView.reload()
        } else {
            startLoad()
        }
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url, let scheme = url.scheme?.lowercased() else {
            decisionHandler(.allow)
            return
        }

        if scheme == "http" || scheme == "https" {
            let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? true
            if url.host == targetURL.host || !isMainFrame {
                decisionHandler(.allow)
            } else if navigationAction.navigationType == .linkActivated {
                presentInAppBrowser(url)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
            return
        }

        // mailto:, tel:, and other app schemes
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
        decisionHandler(.cancel)
    }
}

// MARK: - WKUIDelegate
extension ViewController: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Links with target="_blank" would otherwise do nothing at all.
        if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
            if url.host == targetURL.host {
                webView.load(navigationAction.request)
            } else {
                presentInAppBrowser(url)
            }
        }
        return nil
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
            completionHandler(alert?.textFields?.first?.text)
        })
        present(alert, animated: true)
    }
}

// MARK: - Helpers
private extension UIColor {
    convenience init(hexString: String) {
        var value: UInt64 = 0
        let cleaned = hexString.replacingOccurrences(of: "#", with: "")
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(red: CGFloat((value & 0xFF0000) >> 16) / 255,
                  green: CGFloat((value & 0x00FF00) >> 8) / 255,
                  blue: CGFloat(value & 0x0000FF) / 255,
                  alpha: 1)
    }
}


// MARK: - Disclaimer

final class DisclaimerViewController: UIViewController {

    private let accent: UIColor
    private let background: UIColor

    init(accent: UIColor, background: UIColor) {
        self.accent = accent
        self.background = background
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let body = """
    CRYPTOMINE CONNECT presents informational content only.

    AI DISCLOSURE
    Content, data, and answers in this app were generated, gathered, or assisted by artificial intelligence. AI output can be incomplete, out of date, or wrong. Verify anything you intend to rely on before acting on it.

    NOTHING IS FOR SALE
    No digital asset is offered or sold in this app. Nothing here is an offer, a solicitation, or a recommendation to buy, sell, or hold any digital asset.

    NOT A BANK PRODUCT
    This is not a bank, a deposit account, or a money transmission service. It is not insured by the FDIC, the NCUA, or any government agency. It has not been reviewed, endorsed, or approved by any financial regulator or securities authority. The absence of banking oversight does not place any digital asset outside applicable securities, commodities, or consumer-protection law.

    RISK
    Digital assets are highly volatile and may lose all value. Nothing in this app is financial, investment, legal, or tax advice. Do your own research and consult a qualified professional before making any decision.
    """

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = background
        title = "Disclaimer"
        navigationController?.navigationBar.tintColor = accent
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.barTintColor = background
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let label = UILabel()
        label.text = body
        label.font = .systemFont(ofSize: 14)
        label.textColor = UIColor(white: 0.85, alpha: 1)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(label)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            label.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -40),
            label.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    @objc private func close() { dismiss(animated: true) }
}
