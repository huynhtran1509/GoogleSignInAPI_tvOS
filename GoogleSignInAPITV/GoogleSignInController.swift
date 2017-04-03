//
//  GoogleSignInController.swift
//  GoogleSignInAPITV
//
//  Created by Nat Hillard on 4/2/17.
//  Copyright © 2017 WillowTree Apps. All rights reserved.
//

import Foundation
import PromiseKit


enum LoginConstants {
    static let maxRetryCount = 5
}

enum LoginError : LocalizedError {
    case accessTokenFormat
    case retryCountExceeded
    var errorDescription: String? {
        switch self {
        case .accessTokenFormat:  return "unexpected access token response"
        case .retryCountExceeded: return "Retried more than \(LoginConstants.maxRetryCount) times"
        }
    }
}

struct GoogleSignInController {
    func requestPresentationCode() -> Promise<NSDictionary> {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "accounts.google.com"
        components.path = "/o/oauth2/device/code"
        
        let params = ["client_id" : "1023522800191-ooltcd9al83vdljjphnmt6cic03fasfk.apps.googleusercontent.com",
                      "scope" : "email profile"
        ]
        
        components.queryItems = params.map({name, val in
            URLQueryItem(name: name, value: val)
        })
        
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
            
        return URLSession.shared.dataTask(with: request).asDictionary()
    }
    
    func requestAccessToken(fromDeviceCode deviceCode:String, atInterval interval:Int, retryCount:Int = 0) -> Promise<String> {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.googleapis.com"
        components.path = "/oauth2/v4/token"
        
        let params = ["client_id" : "1023522800191-ooltcd9al83vdljjphnmt6cic03fasfk.apps.googleusercontent.com",
                      "client_secret" : "zqnVCzroDFo2jCkzFB7hdRyy",
                      "code" : deviceCode,
                      "grant_type" : "http://oauth.net/grant_type/device/1.0"
        ]
        components.queryItems = params.map({name, val in
            URLQueryItem(name: name, value: val)
        })
        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        
        print ("Requesting access token, try \(retryCount+1) of \(LoginConstants.maxRetryCount)...")
        return URLSession.shared.dataTask(with: request).asDictionary().then { dictionary -> Promise<String> in
            print("Response:\(dictionary)")
            guard let accessToken = dictionary["access_token"] as? String else {
                throw LoginError.accessTokenFormat
            }
            return Promise(value:accessToken)
        }.recover { error -> Promise<String> in
            guard let pmkError = error as? PMKURLError, pmkError.canRetry else {
                    throw error
            }
            guard retryCount < LoginConstants.maxRetryCount else {
                throw LoginError.retryCountExceeded
            }
            return after(interval: TimeInterval(interval)).then { _ -> Promise<String> in
                self.requestAccessToken(fromDeviceCode: deviceCode, atInterval: interval, retryCount: retryCount+1)
            }
        }
    }
}

/*
 // The below was suggested by https://github.com/mxcl/PromiseKit/issues/594 , but needs coaxing
extension Promise {
    func poll<T>(_ test: @escaping () -> Promise<T>) -> Promise<T> {
        var x = 0
        
        func iteration() -> Promise<T> {
            return test().recover { error -> Promise<T> in
                guard let pmkError = error as? PMKURLError,
                       pmkError.canRetry && x < 3 else {
                        throw error
                }
                x += 1
                return after(interval: 0.1).then(execute: iteration)
            }
        }
        
        return iteration()
    }
}
 */

extension PMKURLError {
    var canRetry : Bool {
        switch self {
            case .badResponse(_, let data?, _):
                if let responseJSON = try? JSONSerialization.jsonObject(with: data),
                   let googleResponse = responseJSON as? [String:Any],
                   let errorDescription = googleResponse["error"] as? String,
                   errorDescription == "authorization_pending" 
                {
                    return true
                } else {
                    return false
            }
        default:
            print("unexpected error")
            return false
        }
    }
}

