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
            
            URLSession.shared.dataTask(with: request).asDictionary().then { dictionary -> Void in
                print("Response:\(dictionary)")
                guard let accessToken = dictionary["access_token"] as? String else {
                    let error = NSError(domain: "Login", code: 0, userInfo: [NSLocalizedDescriptionKey : "Generic login failure"])
                    reject(error)
                    return
                }
                fulfill(accessToken)
            }.recover { error -> Void in
                guard (error as! PMKURLError).canRetry && retryCount < 3 else { throw error }
                retryCount += 1
            }.catch {error in
                print ("Error: \(error)")
            }
        }
    }
}

extension PMKURLError {
    var canRetry : Bool {
        switch self {
            case .badResponse(let request, let data?, let response):
                print ("Request: \(request)\nData:\(data)\nResponse:\(response)")
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

