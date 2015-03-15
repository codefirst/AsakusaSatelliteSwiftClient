//
//  TwitterAuthViewController.swift
//  AsakusaSatelliteSwiftClient
//
//  Created by BAN Jun on 2015/03/15.
//  Copyright (c) 2015年 codefirst. All rights reserved.
//

import Foundation
import UIKit


private let kAuthTwitterPath = "/auth/twitter"
private let kAccountPath = "/account"


public class TwitterAuthViewController: UIViewController, UIWebViewDelegate {
    let webview = UIWebView(frame: CGRectZero)
    let rootURL: NSURL
    let completion: (String? -> Void)
    
    // MARK: init

    public init(rootURL: NSURL, completion: (String? -> Void)) {
        self.rootURL = rootURL
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    public override func viewDidLoad() {
        title = NSLocalizedString("Sign in with Twitter", comment: "")
        
        webview.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        webview.frame = view.bounds
        webview.delegate = self
        view.addSubview(webview)
        
        if let url = NSURL(string: kAuthTwitterPath, relativeToURL: rootURL) {
            // load /auth/twitter with referer /account
            // oauth callback redirects to referer
            let request = NSMutableURLRequest(URL: url)
            request.setValue(kAccountPath, forHTTPHeaderField: "Referer")
            webview.loadRequest(request)
        } else {
            let ac = UIAlertController(
                title: NSLocalizedString("Cannot Load", comment: ""),
                message: NSLocalizedString("Invalid URL: ", comment: "") + "\(rootURL)",
                preferredStyle: .Alert)
            ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: { _ in
                ac.dismissViewControllerAnimated(true, completion: nil)
            }))
            self.presentViewController(ac, animated: true, completion: nil)
        }
    }
    
    // MARK: UIWebViewDelegate
    
    private func isRedirectedBackToAsakusaSatellite(request: NSURLRequest) -> Bool {
        let reqURLString = request.URL.absoluteString
        let rootURLString = rootURL.absoluteString!
        
        return reqURLString?.hasPrefix(rootURLString) == true && request.URL.path == kAccountPath
    }
    
    public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if isRedirectedBackToAsakusaSatellite(request) {
            // TODO: display HUD
            NSLog("Getting API Key...")
        }
        return true
    }
    
    public func webViewDidStartLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    public func webViewDidFinishLoad(webView: UIWebView) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        if isRedirectedBackToAsakusaSatellite(webview.request!) {
            // did load /account on AsakusaSatellite
            // TODO: display HUD
            NSLog("Completed")
            
            // get apiKey from text field
            let js = "$('#account_secret_key').attr('value')"
            let apiKey = webview.stringByEvaluatingJavaScriptFromString(js)
            
            webView.delegate = nil // unlink delegate before removing self
            navigationController?.popViewControllerAnimated(true)
            completion((apiKey?.isEmpty ?? true) ? nil : apiKey)
        }
    }
    
    public func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        let ac = UIAlertController(
            title: NSLocalizedString("Cannot Load", comment: ""),
            message: error.localizedDescription,
            preferredStyle: .Alert)
        ac.addAction(UIAlertAction(title: "OK", style: .Default, handler: { _ in
            ac.dismissViewControllerAnimated(true, completion: nil)
        }))
        self.presentViewController(ac, animated: true, completion: nil)
    }
}
