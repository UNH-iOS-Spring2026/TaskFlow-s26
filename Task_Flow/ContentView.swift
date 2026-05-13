//
//  ContentView.swift
//  Task_Flow
//
//  Created by Aravind Ganipisetty
//

import SwiftUI
import WebKit

// MARK: - WebView Wrapper

// This wrapper allows a UIKit WKWebView to be used inside SwiftUI.
struct WebView: UIViewRepresentable {
    let url: URL

    // Creates the WKWebView instance when SwiftUI loads this view.
    func makeUIView(context: Context) -> WKWebView {
        let web = WKWebView()

        // Allows the user to swipe back and forward between web pages.
        web.allowsBackForwardNavigationGestures = true

        return web
    }

    // Loads or reloads the web page when the SwiftUI view updates.
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

// MARK: - Content View

// Main screen that displays the Task Flow website inside the app.
struct ContentView: View {
    var body: some View {
        WebView(url: URL(string: "https://taskflow-productivity.netlify.app/")!)
            .ignoresSafeArea()
    }
}
