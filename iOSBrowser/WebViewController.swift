//
//  ViewController.swift
//  iOSBrowser
//
//  Created by ANDRES AROCHO QUINONES on 6/28/17.
//  Copyright © 2017 Manking. All rights reserved.
//

import UIKit
import PureLayout
import WebKit

private let KVOEstimatedProgress = "estimatedProgress"
private let KVOTitle = "title"

class WebViewController: UIViewController,WKUIDelegate, WKNavigationDelegate {

    let webView = WKWebView()
    let bottom_bar = UIToolbar()
    let txt_searchBar = UITextField()
    let progress_view = UIProgressView()
    
    let btn_back = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonPressed))
    
    let btn_forward = UIBarButtonItem(title: "Forward", style: .plain, target: self, action: #selector(forwardButtonPressed))
    
    let btn_refresh = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refreshButtonPressed))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        searchKeywordOrURL("http://apple.com")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Setup view
    func setupView()
    {
        webView.allowsLinkPreview = true
        webView.allowsBackForwardNavigationGestures = true
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.addObserver(self, forKeyPath: KVOTitle, options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
                
        btn_back.isEnabled = false
        btn_forward.isEnabled = false
        
        bottom_bar.setItems([btn_back,btn_forward,btn_refresh], animated: false)
        
        txt_searchBar.tintColor = UIColor(red: 25.0/255.0, green: 141.0/255.0, blue: 224.0/255.0, alpha: 1.0)
        txt_searchBar.backgroundColor = UIColor(red: 245.0/255.0, green: 245.0/255.0, blue: 245.0/255.0, alpha: 1.0)
        txt_searchBar.borderStyle = .none
        txt_searchBar.clearButtonMode = .whileEditing
        txt_searchBar.font = UIFont.systemFont(ofSize: 14, weight: UIFontWeightMedium)
        txt_searchBar.textAlignment = .center
        txt_searchBar.autocorrectionType = UITextAutocorrectionType.no
        txt_searchBar.keyboardType = UIKeyboardType.webSearch
        txt_searchBar.autocapitalizationType = UITextAutocapitalizationType.none
        txt_searchBar.layer.cornerRadius = 5
        txt_searchBar.addTarget(self, action: #selector(didBeginEditingTextField(sender:)), for: .editingDidBegin)
        txt_searchBar.addTarget(self, action: #selector(searchURL), for: .editingDidEndOnExit)
        
        progress_view.trackTintColor = UIColor.clear
        
        self.view.addSubview(webView)
        self.view.addSubview(bottom_bar)
        self.view.addSubview(txt_searchBar)
        self.view.addSubview(progress_view)
        
        txt_searchBar.autoPinEdge(toSuperviewEdge: .top, withInset: 30)
        txt_searchBar.autoPinEdge(toSuperviewEdge: .left, withInset: 20)
        txt_searchBar.autoPinEdge(toSuperviewEdge: .right, withInset: 20)
        txt_searchBar.autoSetDimension(.height, toSize: 34)
        
        progress_view.autoPinEdge(.top, to: .bottom, of: txt_searchBar, withOffset: 10)
        progress_view.autoPinEdge(toSuperviewEdge: .left, withInset: 0)
        progress_view.autoPinEdge(toSuperviewEdge: .right, withInset: 0)
        progress_view.autoSetDimension(.height, toSize: 2)
        
        bottom_bar.autoPinEdge(toSuperviewEdge: .bottom, withInset: 0)
        bottom_bar.autoPinEdge(toSuperviewEdge: .left, withInset: 0)
        bottom_bar.autoPinEdge(toSuperviewEdge: .right, withInset: 0)
        
        webView.autoPinEdge(.top, to: .bottom, of: progress_view, withOffset: 0)
        webView.autoPinEdge(.bottom, to: .top, of: bottom_bar, withOffset: 0)
        webView.autoPinEdge(toSuperviewEdge: .left, withInset: 0)
        webView.autoPinEdge(toSuperviewEdge: .right, withInset: 0)
        
        
    }
    
    //MARK: - Search urls or keyword
    func searchKeywordOrURL(_ address: String)
    {
        if(address.lengthOfBytes(using: String.Encoding.utf8) > 0)
        {
            let originalSearch = address;
            
            let urlValidator = isURLValid(originalSearch)
            
            if(urlValidator.0)
            {
                let enteredURL = urlValidator.1
                if let url = enteredURL
                {
                    webView.load(URLRequest(url: url))
                    txt_searchBar.text = webView.url?.absoluteString
                    
                } else {
                    webView.load(URLRequest(url: getKeywordSearchURL(originalSearch)))
                    txt_searchBar.text = webView.url?.absoluteString
                }
            }
            else
            {
                webView.load(URLRequest(url: getKeywordSearchURL(originalSearch)))
            }
        }
    }
    
    //MARK: - WKWebViewDelegate
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!){
        txt_searchBar.text = webView.url?.absoluteString
    
        if(!txt_searchBar.isEditing)
        {
            txt_searchBar.text = webView.url?.absoluteString
        }
        
        
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!)
    {
        if(!txt_searchBar.isEditing)
        {
            txt_searchBar.text = webView.url?.absoluteString
        }
        
        monitorWebViewLoading()
        btn_back.isEnabled = webView.canGoBack
        btn_forward.isEnabled = webView.canGoForward
    }
    
    
    //MARK: - Update WebView Progress
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == KVOEstimatedProgress {
            updateProgressBar(Float((webView.estimatedProgress)))
        }
        
    }
    
    func updateProgressBar(_ progress: Float) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        monitorWebViewLoading()
        if progress == 1.0 {
            progress_view.setProgress(progress, animated: true)
            UIView.animate(withDuration: 1.5, animations:
                {
                    self.progress_view.alpha = 0.0
                    self.monitorWebViewLoading()
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }, completion: { finished in
                if finished {
                    self.progress_view.setProgress(0.0, animated: false)
                }
            })
        } else
        {
            if (progress_view.alpha) < 1.0
            {
                progress_view.alpha = 1.0
            }
            progress_view.setProgress(progress, animated: (progress > (self.progress_view.progress)) && true)
        }
    }
    
    
    //MARK: - Actions
    func searchURL(_ sender: UITextField)
    {
        if(sender.text!.lengthOfBytes(using: String.Encoding.utf8) > 0)
        {
            searchKeywordOrURL(sender.text!)
        }
        else
        {
            txt_searchBar.text = webView.url?.absoluteString
            
        }
    }
    
    func backButtonPressed()
    {
        if(webView.canGoBack)
        {
            webView.goBack()
        }
    }
    
    func forwardButtonPressed()
    {
        if(webView.canGoForward)
        {
            webView.goForward()
        }
    }
    
    func cancelButtonPressed()
    {
        webView.stopLoading()
        monitorWebViewLoading()
        
    }
    
    func refreshButtonPressed()
    {
        webView.reload()
        monitorWebViewLoading()
    }
    
    // MARK: Monitor webview loading
    func monitorWebViewLoading()
    {
        if(webView.isLoading)
        {
            btn_refresh.title = "Cancel"
            btn_refresh.action = #selector(cancelButtonPressed)
        }
        else
        {
            btn_refresh.title = "Refresh"
            btn_refresh.action = #selector(refreshButtonPressed)
        }
    }

    // MARK: Select All From Textfield
    func didBeginEditingTextField(sender: UITextField)
    {
        DispatchQueue.main.async {
            sender.selectAll(nil)
        }
    }

    //MARK: - Helpers
    func getKeywordSearchURL(_ keyword: String) -> URL
    {
        return URL(string: "http://google.com/search?q=" + keyword.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)!
    }
    
    func isURLValid(_ enteredURL: String) ->(Bool, URL?)
    {
        let linkDetector =  try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = linkDetector.matches(in: enteredURL, options: [], range: NSMakeRange(0, enteredURL.characters.count))
        
        if(matches.count > 0)
        {
            let match = matches[0]
            if(match.resultType == NSTextCheckingResult.CheckingType.link)
            {
                return (true, match.url)
            }
            else
            {
                return (false,nil)
            }
        }
        else
        {
            return (false, nil)
        }
    }
}

