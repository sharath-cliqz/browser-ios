//
//  InterceptorURLProtocol.swift
//  Client
//
//  Created by Mahmoud Adam on 8/12/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit


class InterceptorURLProtocol: URLProtocol {
    
    static let customURLProtocolHandledKey = "customURLProtocolHandledKey"
    static let excludeUrlPrefixes = ["https://lookback.io/api", "http://localhost"]
    
    //MARK: - NSURLProtocol handling
    override class func canInit(with request: URLRequest) -> Bool {
	if request.url?.absoluteString == "http:/" {
            return false
        }
        guard (
            URLProtocol.property(forKey: customURLProtocolHandledKey, in: request) == nil
             && request.mainDocumentURL != nil) else {
            return false
        }
        guard isExcludedUrl(request.url) == false else {
            return false
        }
        guard BlockedRequestsCache.sharedInstance.hasRequest(request) == false else {
            return true
        }
        
        if Engine.sharedInstance.getWebRequest().shouldBlockRequest(request) == true {
            
            BlockedRequestsCache.sharedInstance.addBlockedRequest(request)
            
            return true
        }
        
        return false
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return super.requestIsCacheEquivalent(a, to: b)
    }
    
    override func startLoading() {
        BlockedRequestsCache.sharedInstance.removeBlockedRequest(self.request)
        returnEmptyResponse()
    }
    override func stopLoading() {
    
    }
    
    
    //MARK: - private helper methods
    class func isExcludedUrl(_ url: URL?) -> Bool {
        if let scheme = url?.scheme, !scheme.startsWith("http") {
            return true
        }

        if let urlString = url?.absoluteString {
            for prefix in excludeUrlPrefixes {
                if urlString.startsWith(prefix) {
                    return true
                }
            }
        }
        
        return false
    }
    // MARK: Private helper methods
    fileprivate func returnEmptyResponse() {
        // To block the load nicely, return an empty result to the client.
        // Nice => UIWebView's isLoading property gets set to false
        // Not nice => isLoading stays true while page waits for blocked items that never arrive
        
        guard let url = request.url else { return }
        let response = URLResponse(url: url, mimeType: "text/html", expectedContentLength: 1, textEncodingName: "utf-8")
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }
    
    
}
