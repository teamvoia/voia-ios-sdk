//
//  VoiaLinkSDK.swift
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

public enum VoiaSDKError: Error {
    case missingClientSecret
    case apiCallFailed
}

/// The Voia Link SDK interface class. This SDK enables app developers to
/// redirect users to the Voia app in order to create virtual videos.
///
@available(iOS 17.0, *)
public class VoiaLinkSDK {

    var api : VoiaAPI?
    
    /// Shared instance of this SDK.
    public static let shared = VoiaLinkSDK()

    /// Delegate for tracking async video renders.
    public weak var delegate: VoiaLinkSDKDelegate?

    /// Initialize the SDK with the Client Secret Key provided by Voia. This
    /// function must be called before any other function to enable access to
    /// the Voia cloud and app.
    ///
    public func register(clientSecretKey: String) {
        api = VoiaAPI(secretKey: clientSecretKey)
    }

    /// Start the process for creating a new video. This will redirect the user
    /// to the Voia app, promting them to install the app if needed.
    ///
    /// - Parameters:
    ///   - audioURL: URL to audio file to be used as the video's soundtrack.
    ///               We support file://, http:// and https:// URLs.
    ///   - videoName: Name to be embedded on the video itself, e.g. song name.
    ///   - screenName: User screen name to be embeddedo on the video itself.
    ///   - completion: A callback to handle the videoID which will be used to track progress and get results
    ///
    /// - Returns: Video ID that can be used to track render status.
    ///
    public func createVideo(
        audioURL: URL,
        videoName: String? = nil,
        screenName: String? = nil,
        completion: @escaping (_ videoID: String?, _ error: VoiaSDKError?) -> Void
    ) {
        guard let api else {
            completion(nil, .missingClientSecret)
            return
        }
        api.createVideo(audioURL: audioURL, songName: videoName, userScreenName: screenName, completion: completion)
    }

    /// Status of the video cloud rendering process.
    ///
    public enum VideoStatus {
        case Error(String)
        case RenderComplete(URL)
        case RenderInProgress(Double)
        case Unknown
    }

    /// Get the current status of a previously created video.
    ///
    /// - Parameter videoID: Video ID returned upon video creation.
    /// - Returns: Video render status.
    ///
    public func getStatusFor(videoID: String) throws -> VideoStatus {
        guard let api else {
            throw VoiaSDKError.missingClientSecret
        }
        return api.getStatusFor(videoID: videoID)
    }

    /// Methods for sharing videos out of the app.
    ///
    public enum ShareMethod {

        /// Share directly through a locally installed Instagram app. This
        /// required an Instagram app ID available from Meta.
        ///
        case Instagram(instagramAppID: String)

        /// Share through a standard system share sheet. This supports local
        /// file storage as well as any installed applications that support
        /// video sharing like iMessage, iMovie and more.
        ///
        case System
    }

    /// Share a video out of the app.
    ///
    /// - Parameters:
    ///   - videoID: Video ID returned upon video creation.
    ///   - through: Sharing method.
    ///
    public func share(videoID: String, through: ShareMethod) {
        guard let api else {
            return
        }
        api.downloadVideo(video: videoID) { localURL in
            guard let localURL else {
                return
            }
            switch through {
            case .Instagram(let appID):
                self.shareToInstagram(localURL: localURL, appID: appID)
            case .System:
                self.shareWithApple(localURL: localURL)
            }
        }
    }
    
    /// Opens the Instagram app reels share page for the downloaded video
    ///
    /// - Parameters:
    ///   - localURL: location of downloaded video
    ///   - appID: Calling app's Instagram app ID
    ///
    private func shareToInstagram(localURL: URL, appID: String) {
        // coming soon
    }

    /// Opens the apple sharing sheet for the downloaded video
    ///
    /// - Parameters:
    ///   - localURL: location of downloaded video
    ///
    private func shareWithApple(localURL: URL) {
        // coming soon
    }

}

/// Delegate protocol for tracking cloud render status.
///
public protocol VoiaLinkSDKDelegate: AnyObject {

    /// High quality cloud render did start. Cloud render can take multiple
    /// minutes to complete.
    ///
    /// - Parameter videoID: Video ID returned upon video creation.
    ///
    func videoRenderDidStart(videoID: String)

    /// High quality cloud render progress changed.
    ///
    /// - Parameters:
    ///   - videoID: Video ID returned upon video creation.
    ///   - progress: Partial progress between 0 and 1.
    ///
    func videoRenderDidProgress(videoID: String, progress: Double)

    /// High quality cloud render failed.
    ///
    /// - Parameters:
    ///   - videoID: Video ID returned upon video creation.
    ///   - error: Error message.
    ///
    func videoRenderDidFail(videoID: String, error: String)

    /// High quality cloud render completed successfuly and the high quality
    /// video is ready to download.
    ///
    /// - Parameters:
    ///   - videoID: Video ID returned upon video creation.
    ///   - publicURL: Publically accessible URL for the rendered video.
    ///
    func videoRenderDidComplete(videoID: String, publicURL: URL)
}
