//
//  ModelManager_Balaghah.swift
//  
//
//  Created by Iman on 1/5/19.
//

import UIKit

let sharedInstance_Downloader = ModelManager_Downloader()
var selectedTranslator_ID = 1
var categoryForDB = 1
var topic_IDForDB: Int32?

class ModelManager_Downloader: NSObject {
    
    var database: FMDatabase? = nil
    var arrayOfPlaylistData = [Dowonloader.PlaylistsName]()
    
    class func getInstance() -> ModelManager_Downloader {
        if sharedInstance_Downloader.database == nil {
            sharedInstance_Downloader.database = FMDatabase(path: DatabaseUtility.getPath("PlaylistsSong.db"))
        }
        return sharedInstance_Downloader
    }
    
//    func getData() -> [Dowonloader.PlaylistsName] {
//        arrayOfPlaylistData.removeAll()
//        getPlaylists()
//        return arrayOfPlaylistData
//    }
    
//    private func getPlaylists() {
//        sharedInstance_Downloader.database?.open()
//        let query = "SELECT playlist_name,audio_url,sort FROM PlaylistsSong"
//        let resultSet: FMResultSet! = sharedInstance_Downloader.database?.executeQuery(query, withArgumentsIn: [])
//        if (resultSet != nil) {
//            while resultSet.next() {
//                let playlistName = resultSet.string(forColumnIndex: 0)
//                let fileName = URL(string: resultSet.string(forColumnIndex: 1)!)
//                let sort = resultSet.int(forColumnIndex: 2)
////                arrayOfPlaylistData.append(Dowonloader.PlaylistsName(playlistName: playlistName, fileName: fileName, srot: sort))
//            }
//        }
//        print(arrayOfPlaylistData)
//        sharedInstance_Downloader.database?.close()
//    }
    
}

