//
//  InDownloadTableViewCell.swift
//  Downloader
//
//  Created by Iman on 4/5/19.
//  Copyright © 2019 iman. All rights reserved.
//

import UIKit

class InDownloadTableViewCell: UITableViewCell, URLSessionTaskDelegate, URLSessionDownloadDelegate {

    @IBOutlet weak var fileLink: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    
    // Variables For Download File And Save Theme
    let config = URLSessionConfiguration.background(withIdentifier: "com.iman.Downloader.background.id")
    var urlSession: URLSession {
        config.isDiscretionary = true
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }
    var urlForDownLoad: String!
    var i = 0
    var progress: Float = 0.0
    var task: URLSession! = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        creatDowonloadUrl()
        if arrayForDownload.count > 0 {
            downloadNow()
        }
    }

    func downloadNow() {
        let documentsUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        // your destination file url
        let audioUrl = URL(string: urlForDownLoad)
        let destination = documentsUrl.appendingPathComponent(audioUrl!.lastPathComponent)
        if FileManager().fileExists(atPath: destination.path) {
            print("file alerdy exist at path")
            arrayForDownload.remove(at: i - 1)
        } else {
            if let url = URL(string: urlForDownLoad!) {
                task = urlSession
                task.downloadTask(with: url).resume()
            }
        }
    }

    // This Is Use For Make Url Download Form Array
    func creatDowonloadUrl() {
        if arrayForDownload.count > i {
            urlForDownLoad = arrayForDownload[i]
            i = i + 1
            print("i in creat download url: \(i)\n\n")
        }
    }

    // This Is Use For Make Progress View
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            OperationQueue.main.addOperation({
                let progressDic:[String: Float] = ["progress": self.progress]
                NotificationCenter.default.post(name: NSNotification.Name("UpdateProgressView"), object: nil, userInfo: progressDic)
            })
            print("Progress \(downloadTask) \(progress)")
        }
    }

    // This Is Use For Download And Save File In Document Directory
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        debugPrint("Download finished: \(location)")
        let documentsUrl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        // your destination file url
        let audioUrl = URL(string: urlForDownLoad)
        let destination = documentsUrl.appendingPathComponent(audioUrl!.lastPathComponent)
        print("Destination is: \(destination)\n\n\n")
        if FileManager().fileExists(atPath: destination.path) {
            print("file alerdy exist at path")
        } else {
            print("sss")
            do {
                try FileManager.default.moveItem(at: location, to: destination)
                print("file saved to documents")
                arrayForDownload.remove(at: i - 1)
            } catch {
                print("file dont save")
            }
        }
    }

    // This function use for send data for bacground download
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let sessionIdentifier = urlSession.configuration.identifier
        if let sessionId = sessionIdentifier, let app = UIApplication.shared.delegate as? AppDelegate , let handler = app.complationHandler.removeValue(forKey: sessionId) {
            handler()
        }
    }
    
}
