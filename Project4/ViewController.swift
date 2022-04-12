//
//  ViewController.swift
//  Project4
//
//  Created by Furkan Eruçar on 29.03.2022.
//

import UIKit
import WebKit // Web sayfası oluşturacağımız için WebKit Framework'ünü kullanıyoruz

class ViewController: UIViewController, WKNavigationDelegate { // So, the complete meaning of this line is "create a new subclass of UIViewController called ViewController, and tell the compiler that we promise we’re safe to use as a WKNavigationDelegate."

    var webView: WKWebView! // WKWebView part of Webkit
    var progressView: UIProgressView! // Web sitesinin yüklenme bar'ını eklemek için bunu koyuyoruz
    var websites = ["apple.com", "hackingwithswift.com"]
    
    override func loadView() {
        webView = WKWebView() // In our example, we're using WKWebView: Apple's powerful, flexible and efficient web renderer.
        webView.navigationDelegate = self // "when any web page navigation happens, please tell me – the current view controller.”
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Open", style: .plain, target: self, action: #selector(openTapped)) //  The first step to doing this is to give the user the option to choose from one of our selected websites, and that means adding a button to the navigation bar.
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil) // The first line is new, or at least part of it is: we're creating a new bar button item using the special system item type .flexibleSpace, which creates a flexible space. It doesn't need a target or action because it can't be tapped.
        let refresh = UIBarButtonItem(barButtonSystemItem: .refresh, target: webView, action: #selector(webView.reload)) // The second line you've seen before, although now it's calling the reload() method on the web view rather than using a method of our own.
        
        let rewind = UIBarButtonItem(barButtonSystemItem: .rewind, target: webView, action: #selector(webView.goBack))
        let fastForward = UIBarButtonItem(barButtonSystemItem: .fastForward, target: webView, action: #selector(webView.goForward))
        
        // // Burada web sitesinin yüklenme barını oluşturuyoruz.
        progressView = UIProgressView(progressViewStyle: .default) // The first line creates a new UIProgressView instance, giving it the default style. There is an alternative style called .bar, which doesn't draw an unfilled line to show the extent of the progress view, but the default style looks best here.
        progressView.sizeToFit() // The second line tells the progress view to set its layout size so that it fits its contents fully.
        let progressButton = UIBarButtonItem(customView: progressView) // The last line creates a new UIBarButtonItem using the customView parameter, which is where we wrap up our UIProgressView in a UIBarButtonItem so that it can go into our toolbar.
        
        toolbarItems = [progressButton, spacer, rewind, refresh, fastForward] // the first creates an array containing the flexible space and the refresh button, then sets it to be our view controller's toolbarItems array. "toolbarItems" comes from the parent class UIViewController. // With the new progressButton item created, we can put it into our toolbar items anywhere we want it.
        navigationController?.isToolbarHidden = false // The second sets the navigation controller's isToolbarHidden property to be false, so the toolbar will be shown – and its items will be loaded from our current view.
        
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil) // The addObserver() method takes four parameters: who the observer is (we're the observer, so we use self), what property we want to observe (we want the estimatedProgress property of WKWebView), which value we want (we want the value that was just set, so we want the new one), and a context value.
            // Swift has a special keyword, #keyPath, which works like the #selector keyword you saw previously: it allows the compiler to check that your code is correct – that the WKWebView class actually has an estimatedProgress property.
            // context is easier: if you provide a unique value, that same context value gets sent back to you when you get your notification that the value has changed.
        
        let url = URL(string: "https://" + websites[0])! // The first line creates a new data type called URL, which is Swift’s way of storing the location of files.
        webView.load(URLRequest(url: url)) // The second line does two things: it creates a new URLRequest object from that URL, and gives it to our web view to load.
        webView.allowsBackForwardNavigationGestures = true // The third line enables a property on the web view that allows users to swipe from the left or right edge to move backward or forward in their web browsing.
        
        
    }
    
    
    @objc func openTapped() {
        
        let ac = UIAlertController(title: "Open page...", message: nil, preferredStyle: .actionSheet) // We used the UIAlertController class in project 2, but here it's slightly different for three reason:
        
        // 1. We're using nil for the message, because this alert doesn't need one.
        // 2. We're using the preferredStyle of .actionSheet because we're prompting the user for more information.
        // 3. We're adding a dedicated Cancel button using style .cancel. It doesn’t provide a handler parameter, which means iOS will just dismiss the alert controller if it’s tapped.
        
        for website in websites {
            ac.addAction(UIAlertAction(title: website, style: .default, handler: openPage))
        }
        
        
        ac.addAction((UIAlertAction(title: "Cancel", style: .cancel)))
        ac.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem // is used only on iPad, and tells iOS where it should make the action sheet be anchored.
        present(ac, animated: true)
    }
    
    
    func openPage(action: UIAlertAction) { // This method takes one parameter, which is the UIAlertAction object that was selected by the user. Obviously it won't be called if Cancel was tapped, because that had a nil handler rather than openPage.
        guard let actionTitle = action.title else { return }
        guard let url = URL(string: "https://" + actionTitle) else { return }
        webView.load(URLRequest(url: url))
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        title = webView.title
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) { // Once you have registered as an observer using KVO, you must implement a method called observeValue(). This tells you when an observed value has changed,
        if keyPath == "estimatedProgress" {
            progressView.progress = Float(webView.estimatedProgress)
        }
    }
    
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url // First, we set the constant url to be equal to the URL of the navigation. This is just to make the code clearer.
        
        if let host = url?.host { // Second, we use if let syntax to unwrap the value of the optional url.host. Remember I said that URL does a lot of work for you in parsing URLs properly? Well, here's a good example: this line says, "if there is a host for this URL, pull it out" – and by "host" it means "website domain" like apple.com. Note: we need to unwrap this carefully because not all URLs have hosts.
            for website in websites { // Third, we loop through all sites in our safe list, placing the name of the site in the website variable.
                if host.contains(website) { // Fourth, we use the contains() String method to see whether each safe website exists somewhere in the host name. You give the contains() method a string to check, and it will return true if it is found inside whichever string you used with contains(). You've already met the hasPrefix() method in project 1, but hasPrefix() isn't suitable here because our safe site name could appear anywhere in the URL. For example, slashdot.org redirects to m.slashdot.org for mobile devices, and hasPrefix() would fail that test.
                    decisionHandler(.allow) // Fifth, if the website was found then we call the decision handler with a positive response - we want to allow loading.
                    return // Sixth, if the website was found, after calling the decisionHandler we use the return statement. This means "exit the method now." The return statement is new, but it's one you'll be using a lot from now on. It exits the method immediately, executing no further code. If you said your method returns a value, you'll use the return statement to return that value.
                }
            }
        }
        
        decisionHandler(.cancel) // Last, if there is no host set, or if we've gone through all the loop and found nothing, we call the decision handler with a negative response: cancel loading.
            
    }


}

