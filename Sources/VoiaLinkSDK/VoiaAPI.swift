//
//  VoiaAPI.swift
//
//  Copyright (c) 2024 Voia Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
// DEALINGS IN THE SOFTWARE.
//

import Foundation
import Alamofire
import UIKit

@available(iOS 17.0, *)
class VoiaAPI {
    
    let clientSecretKey : String
    var progressTrackers: [String: VoiaProgress]
    
    init(secretKey: String) {
        clientSecretKey = secretKey
        progressTrackers = [:]
        print("secret registered")
        
    }
    
    func headers() -> HTTPHeaders {
        let headers: HTTPHeaders = [
            "Authorization": "bearer \(clientSecretKey)"
        ]
        return headers
    }
    
    func createProject(songName: String?, artist: String?, completion: @escaping (_ str: String?) -> Void) {
        let url = URL(string: "https://api.voia.com/api/project")
        var params:[String: String] = [:]
        if artist != nil {
            params["artist"] = artist
        }
        if songName != nil {
            params["song"] = songName
        }
        print("creating a project")
        AF.request(url!, method: .post, parameters: params, encoder: URLEncodedFormParameterEncoder(destination: .queryString), headers: headers())
            .validate(statusCode: 200..<300).responseString() { videoID in
            switch videoID.result {
            case .success(_):
                print("project created")
                completion(videoID.value)
            case .failure(let error):
                print("Failed to create project. \(error.localizedDescription)")
            }
        }
    }

    func getSignedURL(_ videoID: String, completion: @escaping (_ str: String?) -> Void) {
        let url = URL(string: "https://api.voia.com/api/signurl")
        let params:[String: Any] = ["videoid": videoID, "ext": "mp3"]
        AF.request(url!, method: .get, parameters: params, headers: headers())
            .validate(statusCode: 200..<300).responseString() { signedURL in
            switch signedURL.result {
            case .success(_):
                completion(signedURL.value)
            case .failure(let error):
                let nodesc = "no description"
                print("Failed to sign URL. \(error.errorDescription ?? nodesc)")
            }
        }
    }

    func uploadAudio(source: URL, dest: URL, completion: @escaping () -> Void) {
        var audioData: Data
        if source.isFileURL {
            do {
                audioData = try Data(contentsOf: source)
            } catch {
                print("Failed to read audio file")
                return
            }
            print("uploading from \(source)")
            AF.upload(multipartFormData: { multiPart in
                multiPart.append(audioData, withName: "key",fileName: "audio.mp3" ,mimeType: "audio/mpeg")
            }, to: dest, method: .put, headers: headers()).response { apiResponse in
                switch apiResponse.result{
                case .success(_):
                    completion()
                case .failure(_):
                    print("Failed to upload audio")
                }
            }
        } else {
            let url = URL(string: "https://api.voia.com/api/copyaudio")
            let params:[String: String] = ["src": source.absoluteString, "dest": dest.absoluteString]
            print("copying from \(source)")
            AF.request(url!, method: .post, parameters: params, encoder: URLEncodedFormParameterEncoder(destination: .queryString), headers: headers())
                .validate(statusCode: 200..<300).response { response in
                switch response.result {
                case .success(_):
                    completion()
                case .failure(let error):
                    let nodesc = "no description"
                    print("Failed to copy audio \(error.errorDescription ?? nodesc)")
                }
            }
        }
    }

    func redirectToVoia(_ videoID: String) {
        let url = URL(string: "https://voia.sng.link/Cle3b/dk59?_dl=campaign&pcn=Moshe7&pcrn=Miriam3&_smtype=3&campaign_id=\(videoID)")
        print("redirect to \(url!)")
        UIApplication.shared.open(url!)
    }
    
    func createProgressTracker(_ videoID: String) {
        progressTrackers[videoID] = VoiaProgress(videoID: videoID, api: self)
        print("progress tracker created for \(videoID)")
    }

    func progressTracker(_ videoID: String) -> VoiaProgress {
        if let tracker = progressTrackers[videoID] {
            return tracker
        } else {
            createProgressTracker(videoID)
            return progressTrackers[videoID]!
        }
    }

    func createVideo(audioURL: URL, songName: String?, userScreenName: String?, completion: @escaping (_ videoID: String?, _ error: VoiaSDKError?) -> Void) {
        createProject(songName: songName, artist: userScreenName) { videoId in
            guard let videoId else {
                print("no video ID for signurl :(")
                completion(nil, .apiCallFailed)
                return
            }
            print("get signed url for \(videoId)")
            self.getSignedURL(videoId) { signedURL in
                guard let signedURL else {
                    completion(nil, .apiCallFailed)
                    return
                }
                print("upload audio to \(signedURL)")
                self.uploadAudio(source: audioURL, dest: URL(string: signedURL)!) {
                    self.redirectToVoia(videoId)
                    self.createProgressTracker(videoId)
                    completion(videoId, nil)
                }
            }
        }
    }

    func getStatusFor(videoID: String) -> VoiaLinkSDK.VideoStatus {
        return progressTracker(videoID).videoStatus
    }

    func downloadVideo(video: String, completion: @escaping (_ str: URL?) -> Void) {
        print("not implemented")
        completion(nil)
    }
    
    func getStatus(_ videoID: String, _ cinematicID: String?, completion: @escaping (_ status: VoiaProgress.Status?) -> Void) {
        let url = URL(string: "https://api.voia.com/api/progress")
        var  params:[String: Any] = ["project": videoID]
        if cinematicID != nil {
            params["cinematic"] = cinematicID
        }
        AF.request(url!, method: .get, parameters: params, headers: headers())
            .responseDecodable(of: VoiaProgress.Status.self) { status in
                switch status.result {
                case .success(_):
                    completion(status.value)
                case .failure(_):
                    if status.response?.statusCode == 400 {
                        completion(VoiaProgress.Status(cinematicId: nil, url: nil, progress: -1))
                    }
                }
            }
    }
}
