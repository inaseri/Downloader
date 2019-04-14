//
//  PlaylistsViewController.swift
//  Downloader
//
//  Created by Iman on 4/9/19.
//  Copyright © 2019 iman. All rights reserved.
//

import UIKit

class PlaylistsViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    

    @IBOutlet weak var playlistTabelView: UITableView!
    
    var arrayOfPlaylists = [Dowonloader.plalistData]()
    var database: FMDatabase? = FMDatabase(path: DatabaseUtility.getPath("PlaylistsSong.db"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getPlaylists()
        playlistTabelView.delegate = self
        playlistTabelView.dataSource = self
        playlistTabelView.reloadData()
    }
    
    func getPlaylists() {
        database?.open()
        let query = "SELECT playlist_name,audio_url,sort FROM PlaylistsSong"
        print(query)
        let resultSet: FMResultSet! = database?.executeQuery(query, withArgumentsIn: [])
        if (resultSet != nil) {
            while resultSet.next() {
                let playlistName = resultSet.string(forColumnIndex: 0)
                let fileName = URL(string: resultSet.string(forColumnIndex: 1)!)
                let sort = resultSet.int(forColumnIndex: 2)
                arrayOfPlaylists.append(Dowonloader.plalistData(playlistName: playlistName, fileName: fileName, srot: sort))
            }
        }
        database?.close()
        print(arrayOfPlaylists)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfPlaylists.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: PlaylistNameTableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell 1", for: indexPath) as! PlaylistNameTableViewCell
        cell.textLabel?.text = arrayOfPlaylists[indexPath.row].playlistName
        return cell
    }
    
    @IBAction func creatPlaylist(_ sender: Any) {
        let alert = UIAlertController(title: "ایجاد پلی لیست جدید", message: nil, preferredStyle: UIAlertController.Style.alert)
        alert.addTextField { (textFiled) in
            textFiled.placeholder = "نام پلی لیست خود را وارد کنید..."
        }
        alert.addAction(UIAlertAction(title: "ایجاد", style: .default, handler: { [weak alert] (_) in
            guard let playlistName = alert?.textFields![0] else { return } // Force unwrapping because we know it exists.
            if playlistName.text != "" {
                let viewControllers = self.storyboard?.instantiateViewController(withIdentifier: "Saved File") as! SavedFileViewController
                viewControllers.fromPlaylist = true
                viewControllers.playlistName = playlistName.text
                self.navigationController?.pushViewController(viewControllers, animated: true)
            }
        }))
        alert.addAction(UIAlertAction(title: "انصراف", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
