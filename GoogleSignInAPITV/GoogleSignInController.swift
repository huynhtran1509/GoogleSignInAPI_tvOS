//
//  GoogleSignInController.swift
//  GoogleSignInAPITV
//
//  Created by Nat Hillard on 4/2/17.
//  Copyright © 2017 WillowTree Apps. All rights reserved.
//

import Foundation
import PromiseKit

struct GoogleSignInController {
    func requestPresentationCode() -> Promise<(String, String, Int)> {
        return Promise { fulfill, reject in
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
            
            URLSession.shared.dataTask(with: request).asDictionary().then { dictionary -> Void in
                print("Response:\(dictionary)")
                guard let userCode = dictionary["user_code"] as? String,
                      let deviceCode = dictionary["device_code"] as? String,
                      let interval = dictionary["interval"] as? Int else {
                    let error = NSError(domain: "Login", code: 0, userInfo: [NSLocalizedDescriptionKey : "Generic login failure"])
                    reject(error)
                    return 
                }
                fulfill(userCode, deviceCode, interval)
            }
        }
    }
    
    func requestAccessToken(fromDeviceCode deviceCode:String, atInterval interval:Int) -> Promise<String> {
        var retryCount = 0
        return Promise { fulfill, reject in
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
            
            URLSession.shared.dataTask(with: request).asDictionary().then { dictionary -> Promise<String> in
                print("Response:\(dictionary)")
                guard let accessToken = dictionary["access_token"] as? String else {
                    throw LoginError.accessTokenFormat
                }
                return Promise(value:accessToken)
            }.recover { error -> Promise<String> in
                guard (error as! PMKURLError).canRetry && retryCount < 3 else { throw error }
                retryCount += 1
                return after(interval: TimeInterval(interval)).then { _ -> Promise<String> in
                    self.requestAccessToken(fromDeviceCode: deviceCode, atInterval: interval)
                }
            }.catch {error in
                print ("Error: \(error)")
            }
        }
    }
}

enum LoginError : LocalizedError {
    case accessTokenFormat
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

