//
//  VoiaProgress.swift
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

@available(iOS 17.0, *)
class VoiaProgress {
    let videoID : String
    var cinematicID: String? = nil
    let api : VoiaAPI
    struct Status: Codable {
        let cinematicId: String?
        let url: String?
        let progress: Double
    }
    var videoStatus: VoiaLinkSDK.VideoStatus
    init(videoID: String, api: VoiaAPI) {
        self.videoID = videoID
        self.api = api
        videoStatus = .Unknown
        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { timer in
            api.getStatus(videoID, self.cinematicID) { status in
                guard let status else {
                    return
                }
                let noid = "None"
                print("progress for video \(self.videoID): \(status.progress). id \(status.cinematicId ?? noid)")
                if status.progress < 0 {
                    self.videoStatus = .Error("Project not found")
                    timer.invalidate()
                } else if status.progress == 1 && status.url != nil {
                    let url = URL(string: status.url!)!
                    self.videoStatus = .RenderComplete(url)
                    VoiaLinkSDK.shared.delegate?.videoRenderDidComplete(videoID: self.videoID, publicURL: url)
                    timer.invalidate()
                } else if status.cinematicId != nil {
                    if self.cinematicID == nil {
                        VoiaLinkSDK.shared.delegate?.videoRenderDidStart(videoID: self.videoID)
                    } else {
                        VoiaLinkSDK.shared.delegate?.videoRenderDidProgress(videoID: self.videoID, progress: status.progress)
                    }
                    self.cinematicID = status.cinematicId
                    self.videoStatus = .RenderInProgress(status.progress)
                }
            }
        }
    }
}
