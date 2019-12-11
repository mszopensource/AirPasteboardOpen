//
//  GithubRequests.swift
//  AirPasteBoard
//
//  Created by Shunzhe Ma on 12/6/19.
//  Copyright © 2019 Shunzhe Ma. All rights reserved.
//

import Foundation
import Alamofire

class GithubRequestHelper: NSObject {
    
    func createGist(utilObj: Util, githubToken: String, fileName: String, content: String, setPublic: Bool = false) {
        
        //Fetch user-defined host
        let githubHost = "api.github.com"
        guard let requestURL = URL(string: "https://" + githubHost + "/gists") else {return}
        
        // Add Headers
        let headers = [
            "Authorization":"Bearer " + githubToken,
            "Content-Type":"application/json; charset=utf-8",
        ]

        // JSON Body
        let body: [String : Any] = [
            "files": [
                fileName: [
                    "content": content
                ]
            ],
            "public": setPublic
        ]

        // Fetch Request
        Alamofire.request(requestURL, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
            .validate(statusCode: 200..<300)
            .responseJSON { response in
                if (response.result.error == nil) {
                    let data = response.data
                    // Success
                    // Parse result
                    do {
                        guard let responseData = data else {
                            utilObj.onFailedGistShare(reason: "Empty response data object."); return
                        }
                        let jsonResponse = try JSONSerialization.jsonObject(with: responseData, options: [])
                        guard let jsonArray = jsonResponse as? [String: Any] else {
                              utilObj.onFailedGistShare(reason: "Parsing failed."); return
                        }
                        guard let htmlURL = jsonArray["html_url"] as? String else {
                            //Check if we have an error message
                            if let errorMsg = jsonArray["message"] as? String {
                                utilObj.onFailedGistShare(reason: errorMsg); return
                            } else {
                                utilObj.onFailedGistShare(reason: "Parsing failed."); return
                            }
                        }
                        utilObj.onSuccessShare(url: htmlURL)
                    } catch {
                        utilObj.onFailedGistShare(reason: "The request went through but the app failed to parse the shared gist URL.")
                    }
                }
                else {
                    // Failure
                    print("URL Session Task Failed: %@", response.result.error!.localizedDescription);
                    utilObj.onFailedGistShare(reason: response.result.error!.localizedDescription)
                }
            }
        
    }
    
}
