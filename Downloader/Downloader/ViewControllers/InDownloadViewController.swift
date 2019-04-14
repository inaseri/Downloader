//
//  InDownloadViewController.swift
//  Downloader
//
//  Created by Iman on 4/5/19.
//  Copyright © 2019 iman. All rights reserved.
//

import UIKit

class InDownloadViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var inDownloadTableView: UITableView!
    let notification = NotificationCenter.default
    var progressForTable: Float = 0.0
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        NotificationCenter.default.addObserver(self, selector: #selector(getNotfication(notification:)), name: NSNotification.Name(rawValue: "UpdateProgressView"), object: nil)
    }
    
    // handle notification
    @objc func getNotfication(notification: NSNotification) {
        if let progress = notification.userInfo?["progress"] as? Float {
            progressForTable = progress
            inDownloadTableView.reloadData()
        }
    }
        
    
    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 400
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayForDownload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: InDownloadTableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell 0", for: indexPath) as! InDownloadTableViewCell
        cell.fileLink.text = arrayForDownload[indexPath.row]
        cell.progressView.setProgress(progressForTable, animated: true)
        cell.selectionStyle = .none
        return cell
    }
}
