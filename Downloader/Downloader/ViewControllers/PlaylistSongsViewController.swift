//
//  PlaylistSongsViewController.swift
//  Downloader
//
//  Created by Iman on 5/13/19.
//  Copyright © 2019 iman. All rights reserved.
//

import UIKit

class PlaylistSongsViewController: UIViewController {

    var database: FMDatabase? = FMDatabase(path: DatabaseUtility.getPath("PlaylistsSong.db"))
    
    var arrayOfUrls = [Dowonloader.playlist]()
    var playlistId: Int32!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getUrls()
    }
    
    func getUrls() {
        database?.open()
        let query = "SELECT id,url,sort FROM PlaylistsUrl"
        let resultSet: FMResultSet! = database?.executeQuery(query, withArgumentsIn: [])
        if (resultSet != nil) {
            while resultSet.next() {
                _ = resultSet.int(forColumnIndex: 0)
                let url = URL(string: resultSet.string(forColumnIndex: 1)!)
                let sort = Int(resultSet.int(forColumnIndex: 2))
                arrayOfUrls.append(Dowonloader.playlist(sort: sort, url: url))
            }
        }
        database?.close()
        print("arrayOfUrls in did select: \(arrayOfUrls)")
    }

}
