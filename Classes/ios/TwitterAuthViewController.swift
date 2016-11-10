//
//  TwitterAuthViewController.swift
//  AsakusaSatelliteSwiftClient
//
//  Created by BAN Jun on 2015/03/15.
//  Copyright (c) 2015年 codefirst. All rights reserved.
//

import Foundation
import UIKit


open class TwitterAuthViewController: UIViewController, UIWebViewDelegate {
    let webview = UIWebView(frame: .zero)
    let rootURL: URL
    var authTwitterURL: URL { return URL(string: "auth/twitter", relativeTo: rootURL)! }
    var accountURL: URL { return URL(string: "account", relativeTo: rootURL)! }
    let completion: ((String?) -> Void)
    
    // MARK: init

    public init(rootURL: URL, completion: @escaping ((String?) -> Void)) {
        self.rootURL = rootURL
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    open override func viewDidLoad() {
        title = NSLocalizedString("Sign in with Twitter", comment: "")
        
        webview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webview.frame = view.bounds
        webview.delegate = self
        view.addSubview(webview)
        
        removeCookiesForURL(URL(string: "https://twitter.com")!)
        
        // load /auth/twitter with referer /account
        // oauth callback redirects to referer
        var request = URLRequest(url: authTwitterURL)
        request.setValue(accountURL.absoluteString, forHTTPHeaderField: "Referer")
        webview.loadRequest(request)
    }
    
    // MARK: UIWebViewDelegate
    
    private func isRedirectedBackToAsakusaSatellite(_ request: URLRequest) -> Bool {
        return request.url?.absoluteString == accountURL.absoluteString
    }
    
    open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if isRedirectedBackToAsakusaSatellite(request) {
            // TODO: display HUD
            NSLog("%@", "Getting API Key...")
        }
        return true
    }
    
    open func webViewDidStartLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    open func webViewDidFinishLoad(_ webView: UIWebView) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        if isRedirectedBackToAsakusaSatellite(webview.request!) {
            // did load /account on AsakusaSatellite
            // TODO: display HUD
            NSLog("%@", "Completed")
            
            // get apiKey from text field
            let js = "$('#account_secret_key').attr('value')"
            let apiKey = webview.stringByEvaluatingJavaScript(from: js)
            
            webView.delegate = nil // unlink delegate before removing self
            _ = navigationController?.popViewController(animated: true)
            completion((apiKey?.isEmpty ?? true) ? nil : apiKey)
        }
    }
    
    open func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        let ac = UIAlertController(
            title: NSLocalizedString("Cannot Load", comment: ""),
            message: error.localizedDescription,
            preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            ac.dismiss(animated: true, completion: nil)
        }))
        present(ac, animated: true, completion: nil)
    }
}

