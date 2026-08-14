import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {
    var webView: WKWebView!
    var spinner: UIActivityIndicatorView!
    var retryButton: UIButton!
    let targetURL = "https://carbon-ledger-exchange.replit.app"

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        setupSpinner()
        setupRetryButton()
        loadSite()
    }

    func setupWebView() {
        let config = WKWebViewConfiguration()
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        view.addSubview(webView)
    }

    func setupSpinner() {
        spinner = UIActivityIndicatorView(style: .large)
        spinner.center = view.center
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
    }

    func setupRetryButton() {
        retryButton = UIButton(type: .system)
        retryButton.setTitle("Retry", for: .normal)
        retryButton.frame = CGRect(x: view.center.x - 50, y: view.center.y + 40, width: 100, height: 44)
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(retryLoad), for: .touchUpInside)
        view.addSubview(retryButton)
    }

    func loadSite() {
        guard let url = URL(string: targetURL) else { return }
        spinner.startAnimating()
        retryButton.isHidden = true
        webView.load(URLRequest(url: url))
    }

    @objc func retryLoad() { loadSite() }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        spinner.stopAnimating()
        retryButton.isHidden = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()
        retryButton.isHidden = false
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()
        retryButton.isHidden = false
    }
}
