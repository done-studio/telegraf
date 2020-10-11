//
//  WebView.swift
//  Podcast
//
//  Created by Adrian Evensen on 24/05/2020.
//  Copyright © 2020 AdrianF. All rights reserved.
//

import SwiftUI
import WebKit
import SafariServices

struct WebView: UIViewRepresentable {

    typealias UIViewType = WKWebView
    let url: String
    let webView = WKWebView()
    let present: (URL) -> Void

    func makeUIView(context: UIViewRepresentableContext<WebView>) -> WebView.UIViewType {
        webView.allowsBackForwardNavigationGestures = true
        
        let css = """
<style>
    body{
font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, 'Open Sans', 'Helvetica Neue', sans-serif;
        font-size: 2rem;
    
    }
</style>
"""
        webView.loadHTMLString(url + css, baseURL:  nil)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: UIViewRepresentableContext<WebView>) {
        
        
    }
}

extension WebView {
    func makeCoordinator() -> Coordinator {
        return Coordinator(vc: webView, present: present)
    }
    
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let present: (URL) -> Void

        
        init(vc: WKWebView, present: @escaping (URL) -> Void) {
            self.present = present
            super.init()
            vc.navigationDelegate = self
        }
   
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            
            
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, preferences: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
            if navigationAction.navigationType == .linkActivated{
                decisionHandler(.cancel, preferences)
                if let url = navigationAction.request.url {
                    present(url)
                }
                return
            }
            
            decisionHandler(.allow, preferences)
        }
        
        
        
    }
    
}
