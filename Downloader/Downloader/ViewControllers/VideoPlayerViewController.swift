//
//  VideoPlayerViewController.swift
//  Downloader
//
//  Created by Iman on 5/11/19.
//  Copyright © 2019 iman. All rights reserved.
//

import UIKit
import AVKit
import PhotosUI

class VideoPlayerViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FileManagerDelegate, UIDocumentInteractionControllerDelegate {
    
    @IBOutlet weak var videioPlayerTableView: UITableView!
    @IBOutlet weak var downloadVideo: UIBarButtonItem!
    
    var recordings = [URL]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listRecordings()
        videioPlayerTableView.reloadData()
        
    }
    
    // This function use for get saved file and put them in array
    func listRecordings() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            self.recordings = urls.filter( { (name: URL) -> Bool in
                videioPlayerTableView.reloadData()
                return name.lastPathComponent.hasSuffix("mp4")
            })
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("something went wrong listing recordings")
        }
    }
    
    func fileManager(_ fileManager: FileManager, shouldMoveItemAt srcURL: URL, to dstURL: URL) -> Bool {
        print("should move \(srcURL) to \(dstURL)")
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recordings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: VideoPlayerTableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell 3", for: indexPath) as! VideoPlayerTableViewCell
        cell.textLabel?.text = recordings[indexPath.row].lastPathComponent
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = AVPlayer(url: recordings[indexPath.row])
        let videoPlyer = AVPlayerViewController()
        videoPlyer.player = video
        present(videoPlyer, animated: true) {
            video.play()
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let favorite = UITableViewRowAction(style: .normal, title: "ذخیره در گالری") { action, index in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: self.recordings[index.row])
            }) { completed, error in
                if completed {
                    let alert = UIAlertController(title: "ذخیره شده", message: "فایل شما با موفقیت در گالری سیو شد", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "تایید", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
        
        favorite.backgroundColor = UIColor.blue
        let delete = UITableViewRowAction(style: .normal, title: "حذف") { action, index in
            let alert = UIAlertController(title: "حذف", message: nil, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "حذف", style: UIAlertAction.Style.destructive, handler: { (action) in
                let fileName = self.recordings[index.row]
                let fileManager = FileManager.default
                do {
                    try fileManager.removeItem(at: fileName)
                    self.listRecordings()
                    tableView.reloadData()
                } catch {
                    print("error in: \(error)")
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        delete.backgroundColor = UIColor.red
        
        let share = UITableViewRowAction(style: .normal, title: "اشتراک گذاری") { (action, index) in
            let activityController = UIActivityViewController(activityItems: [self.recordings[index.row]], applicationActivities: nil)
            activityController.completionWithItemsHandler = { (nil, completed, _, error)
                in
                if completed {
                    print("completed")
                } else {
                    print("canceled")
                }
            }
            activityController.popoverPresentationController?.sourceView = self.view // so that iPads won't crash
            self.present(activityController, animated: true, completion: {
                print("presented")
            })
        }
        return [favorite, share, delete]
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        videioPlayerTableView.reloadData()
    }

    @IBAction func downloadVideo(_ sender: Any) {
        let alert = UIAlertController(title: "دانلود", message: "انتخاب کنید", preferredStyle: UIAlertController.Style.actionSheet)
        alert.addAction(UIAlertAction(title: "مشاهده لیست دانلود ها", style: UIAlertAction.Style.default, handler: { (action) in
            var vc: UIViewController = UIViewController()
            vc = self.storyboard?.instantiateViewController(withIdentifier: "Downloading List") as! InDownloadViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "دانلود فایل جدید", style: UIAlertAction.Style.default, handler: { (action) in
            let alert = UIAlertController(title: "دانلود ویدیو", message: "لینک و اسم فایل مورد نظر برای ذخیره را وارد کنید", preferredStyle: .alert)
            //2. Add the text field. You can configure it however you need.
            alert.addTextField(configurationHandler: { (linkForDwonload) in
                linkForDwonload.text = ""
                linkForDwonload.placeholder = "لینک دانلود"
            })
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "دانلود", style: .default, handler: { [weak alert] (_) in
                guard let link = alert?.textFields![0] else  { return }
                if link.text != "" && link.text?.suffix(4) == ".mp4" {
                    linkForDownloadGlobal = link.text
                    arrayForDownload.append(linkForDownloadGlobal)
                    var vc: UIViewController = UIViewController()
                    vc = self.storyboard?.instantiateViewController(withIdentifier: "Downloading List") as! InDownloadViewController
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let alert = UIAlertController(title: "خطا", message: "لینک دانلود خود را بررسی کنید", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "تایید", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                
            }))
            alert.addAction(UIAlertAction(title: "انصراف", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "دانلود فایل جدید از یوتویوب", style: UIAlertAction.Style.default, handler: { (action) in
            let alert = UIAlertController(title: "دانلود ویدیو", message: "لینک و اسم فایل مورد نظر برای ذخیره را وارد کنید", preferredStyle: .alert)
            //2. Add the text field. You can configure it however you need.
            alert.addTextField(configurationHandler: { (linkForDwonload) in
                linkForDwonload.text = ""
                linkForDwonload.placeholder = "لینک دانلود"
            })
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "دانلود", style: .default, handler: { [weak alert] (_) in
                guard let link = alert?.textFields![0] else  { return }
                if link.text != "" && link.text?.suffix(4) == ".mp4" {
                    linkForDownloadGlobal = link.text
                    arrayForDownload.append(linkForDownloadGlobal)
                    var vc: UIViewController = UIViewController()
                    vc = self.storyboard?.instantiateViewController(withIdentifier: "Downloading List") as! InDownloadViewController
                    self.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let alert = UIAlertController(title: "خطا", message: "لینک دانلود خود را بررسی کنید", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "تایید", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                
            }))
            alert.addAction(UIAlertAction(title: "انصراف", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "انصراف", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}
