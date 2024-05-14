import XCTest
import Alamofire
@testable import VoiaLinkSDK

@available(iOS 17.0, *)
final class VoiaLinkSDKTests: XCTestCase {
    func testCreation() throws {
        VoiaLinkSDK.shared.register(clientSecretKey: "mySecret")
        let expectation = self.expectation(description: "Creating project")
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        let remoteURL = URL(string: "https://file-examples.com/storage/fe92070d83663e82d92ecf7/2017/11/file_example_MP3_2MG.mp3")
        print("!!!!")
        print(destination)
        AF.download(remoteURL!, to: destination).response { response in
            print("got response")
            if response.error == nil {
                VoiaLinkSDK.shared.createVideo(audioURL: response.fileURL!, videoName: "mysong", screenName: "The Beatles") { videoID, error in
                    guard let videoID else {
                        print("FAILED to get id")
                        expectation.fulfill()
                        return
                    }
                    expectation.fulfill()
                    print(videoID)
                }
            } else {
                print(response.error)
            }
        }
//       VoiaLinkSDK.shared.createVideo(audioURL: remoteURL!, videoName: "mysong", screenName: "The Beatles") { videoID, error in
        waitForExpectations(timeout: 20, handler: nil)
    }
}
