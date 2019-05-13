//
//  SavedFileViewController.swift
//  Downloader
//
//  Created by Iman on 4/5/19.
//  Copyright © 2019 iman. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import EventKitUI
import Network

var sliderValueGlobal: Float!
var sliderMaxValueGlobal: Float!
var sliderChangeFlag: Bool!
var urlForOfflinePlay: URL?

class SavedFileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FileManagerDelegate, UIDocumentInteractionControllerDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var savedFileTableView: UITableView!
    @IBOutlet weak var toolBar: UIToolbar!
    
    // Global variables
    var titleForBacground: String!
    var artistForBackground: String!
    var artwok: Data!
    var counter = 0
    
    // Variables For Show Mini Player
    let ncObserver = NotificationCenter.default
    var flagForPlayButton = true
    var items = [UIBarButtonItem]()
    let titleOfNowPlay = UIBarButtonItem(title: titleForShow, style: UIBarButtonItem.Style.plain, target: self, action: #selector(showPlayer))
    let rewind = UIBarButtonItem(barButtonSystemItem: .rewind, target: self, action: #selector(rewindMusic))
    var playOrPause = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(play_Pause))
    let forward = UIBarButtonItem(barButtonSystemItem: .fastForward, target: self, action: #selector(forwardMusic))
    let space2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    
    // Varialbes for play audio
    var currentTime: Float!
    var timer: Timer?
    var recordings = [URL]()
    var player:AVAudioPlayer!
    var playSong = AVPlayer()
    var playerItem:AVPlayerItem?
    var fileForShare = [URL]()
    var audioSession = AVAudioSession.sharedInstance()
    var nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    var remoCommandCenter = MPRemoteCommandCenter.shared()
    
    // Globale variabeles for check net is connetcted or not
    let monitor = NWPathMonitor()
    
    // Globale variabelse for creat playlist
    var fromPlaylist = false
    var arrayOfPlaylists = [String]()
    var arrayOfSelected = [Dowonloader.playlist]()
    var selected: Int!
    var playlistName: String!
    var database: FMDatabase? = FMDatabase(path: DatabaseUtility.getPath("PlaylistsSong.db"))
    var playlistNameId: Int32!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        listRecordings()
        savedFileTableView.reloadData()
        ncObserver.addObserver(self, selector: #selector(self.pauseMusic), name: Notification.Name("StopMusic"), object: nil)
        ncObserver.addObserver(self, selector: #selector(self.playMusic), name: Notification.Name("PlayMusic"), object: nil)
        ncObserver.addObserver(self, selector: #selector(self.rewindMusic), name: Notification.Name("RewindMusic"), object: nil)
        ncObserver.addObserver(self, selector: #selector(self.sliderChange), name: Notification.Name("SliderChange"), object: nil)
        ncObserver.addObserver(self, selector: #selector(self.forwardMusic), name: Notification.Name("forwardMusic"), object: nil)
        // Play audio in notfication center
        try! self.audioSession.setActive(true)
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.allowAirPlay)
        } catch {
            print("error: \(error)")
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
        if fromPlaylist == true {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(creatPlaylist))
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButton))
            navigationItem.rightBarButtonItem?.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            navigationItem.leftBarButtonItem?.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        listRecordings()
        creatToolBar()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("We're connected!")
            } else {
                print("No connection.")
                let alert = UIAlertController(title: "خطا", message: "لطفا اتصال به اینترنت خود را بررسی کنید", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "ورود به تنظیمات", style: UIAlertAction.Style.default, handler: { (action) in
                    guard let settingsUrl = URL(string: "App-Prefs:root=WIFI") else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                            print("Settings opened: \(success)") // Prints true
                        })
                    }
                }))
                alert.addAction(UIAlertAction(title: "انصراف", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            print(path.isExpensive)
        }
        let queue = DispatchQueue(label: "Monitor")
        monitor.start(queue: queue)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        listRecordings()
    }
    
    func creatToolBar() {
        items = [titleOfNowPlay,space2,space2,space2,space2,space2,rewind,space2,playOrPause,space2,forward,space2]
        toolBar.items = items
        toolBar.tintColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
        titleOfNowPlay.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        if titleForShow == nil {
            titleOfNowPlay.title = "Not Playing"
        }
    }
    // This function use for show Detail of now play in notfication center
    func updateNowPlayingInfo() {
        nowPlayingInfoCenter.nowPlayingInfo = [MPMediaItemPropertyTitle: titleForShow,
                                               MPMediaItemPropertyArtist: artistForShow,
                                               MPMediaItemPropertyPlaybackDuration: player.duration,
                                               MPMediaItemPropertyBookmarkTime: player.currentTime,
        ]
        remoCommandCenter.seekForwardCommand.isEnabled = false
        remoCommandCenter.seekBackwardCommand.isEnabled = false
        remoCommandCenter.previousTrackCommand.isEnabled = true
        remoCommandCenter.nextTrackCommand.isEnabled = true
        remoCommandCenter.togglePlayPauseCommand.isEnabled = true
        remoCommandCenter.playCommand.addTarget(self, action: #selector(playMusic))
        remoCommandCenter.pauseCommand.addTarget(self, action: #selector(pauseMusic))
        remoCommandCenter.nextTrackCommand.addTarget(self, action: #selector(forwardMusic))
        remoCommandCenter.previousTrackCommand.addTarget(self, action: #selector(rewindMusic))
    }
    
    // This function use for get saved file and put them in array
    func listRecordings() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let urls = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
            self.recordings = urls.filter( { (name: URL) -> Bool in
                savedFileTableView.reloadData()
                return name.lastPathComponent.hasSuffix("mp3")
            })
            fileForShare = urls
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
        let cell: SavedFileTableViewCell = tableView.dequeueReusableCell(withIdentifier: "Cell 1", for: indexPath) as! SavedFileTableViewCell
        cell.nameOfMusicLabel.text = recordings[indexPath.row].lastPathComponent
        
        let url = recordings[indexPath.row]
        playerItem = AVPlayerItem(url: url)
        let metaDataList = playerItem?.asset.metadata
        for item in metaDataList! {
            guard let key = item.commonKey?.rawValue, let value = item.value else{
                continue
            }
            switch key {
            case "title" : cell.nameOfMusicLabel.text = value as? String
            case "artwork" where value is Data : let image: NSData? = value as! Data as NSData
            cell.imageOfMusicImageView.image = UIImage(data: image! as Data)
            default:
                continue
            }
        }
        
        if fromPlaylist == false {
            if counter == indexPath.row {
                cell.inPlayingImageView.image = #imageLiteral(resourceName: "ic-in play")
            } else {
                cell.inPlayingImageView.image = nil
            }
            return cell
        } else {
            let index = indexPath.row
            if selected == index {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if fromPlaylist == false {
            counter = indexPath.row
            let url = recordings[indexPath.row]
            urlForOfflinePlay = recordings[counter]
            do {
                self.player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = 1.0
                player.delegate = self
                player.play()
                sliderMaxValueGlobal = Float(player.duration)
                currentTime = Float(player.currentTime)
                getNowPlayInfo()
                updateNowPlayingInfo()
                updateSliderTimer()
                scheduledTimerWithTimeInterval()
                playOrPause = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(play_Pause))
                items = [titleOfNowPlay,space2,space2,space2,space2,space2,rewind,space2,playOrPause,space2,forward,space2]
                toolBar.items = items
                flagForPlayButton = false
            } catch let error as NSError {
                self.player = nil
                print(error.localizedDescription)
            } catch {
                print("AVAudioPlayer init failed")
            }
            getNowPlayInfo()
            savedFileTableView.reloadData()
        } else {
            selected = indexPath.row
            arrayOfSelected.append(Dowonloader.playlist(sort: selected, url: recordings[indexPath.row]))
            savedFileTableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        
        let favorite = UITableViewRowAction(style: .normal, title: "اشتراک گذاری") { action, index in
            // set up activity view controller
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            do {
                let urls = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
                self.recordings = urls.filter( { (name: URL) -> Bool in
                    return name.lastPathComponent.hasSuffix("mp3")
                })
                let controller = UIDocumentInteractionController(url: urls[index.row])
                controller.delegate = self
                controller.presentPreview(animated: true)
                print("presented")
            } catch let error as NSError {
                print(error.localizedDescription)
            } catch {
                print("something went wrong listing recordings")
            }
        }
        
        favorite.backgroundColor = UIColor.blue
        let delet = UITableViewRowAction(style: .normal, title: "حذف") { action, index in
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
        delet.backgroundColor = UIColor.red
        return [favorite, delet]
    }
    
    // This function use for share file after download
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    @objc func updateSliderTimer() {
        sliderValueGlobal = Float(player.currentTime)
    }
    
    // This Function Use For Update Every Second Of Slider Now Play
    func scheduledTimerWithTimeInterval() {
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateSliderTimer), userInfo: nil, repeats: true)
    }
    
    func getNowPlayInfo() {
        let url = recordings[counter]
        playerItem = AVPlayerItem(url: url)
        let metaDataList = playerItem?.asset.metadata
        for item in metaDataList! {
            guard let key = item.commonKey?.rawValue, let value = item.value else{
                continue
            }
            switch key {
            case "title" : titleForShow = value as? String
            case "artist": artistForShow = value as? String
            case "artwork" where value is Data : let image = value as! Data
                imageForSHow = image
                titleOfNowPlay.title = titleForShow
            default:
                continue
            }
        }
        updateNowPlayingInfo()
    }
    
    // This function use for play music for the first time in app
    @objc func playTrack() {
        urlForOfflinePlay = recordings[counter]
        do {
            self.player = try AVAudioPlayer(contentsOf: urlForOfflinePlay!)
            player.prepareToPlay()
            player.volume = 1.0
            player.delegate = self
            player.play()
            sliderMaxValueGlobal = Float(player.duration)
            currentTime = Float(player.currentTime)
            updateNowPlayingInfo()
            updateSliderTimer()
            scheduledTimerWithTimeInterval()
        } catch let error as NSError {
            self.player = nil
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }
    
    @objc func playMusic() {
        if urlForOfflinePlay == nil {
            print("nothing for play")
        } else {
            do {
                urlForOfflinePlay = recordings[counter]
                self.player = try AVAudioPlayer(contentsOf: urlForOfflinePlay!)
                player.volume = 1.0
                player.delegate = self
                player.currentTime = TimeInterval(sliderValueGlobal)
                player.play()
                updateNowPlayingInfo()
                updateSliderTimer()
                scheduledTimerWithTimeInterval()
            } catch {
                print("Error in fill url for play")
            }
        }
    }
    
    @objc func pauseMusic() {
        if urlForOfflinePlay == nil {
            print("nothing for stop")
        } else {
            urlForOfflinePlay = recordings[counter]
            player.pause()
            updateNowPlayingInfo()
            updateSliderTimer()
            scheduledTimerWithTimeInterval()
        }
    }
    
    @objc func rewindMusic() {
        if counter == 0 {
            counter = 0
        } else {
            counter = counter - 1
            if counter <= recordings.count - 1 {
                playTrack()
                getNowPlayInfo()
            } else {
                counter = 0
                playTrack()
                getNowPlayInfo()
            }
        }
    }
    
    @objc func sliderChange() {
        if player != nil {
            player.stop()
            player.currentTime = TimeInterval(sliderValueGlobal)
            player.prepareToPlay()
            player.play()
        }
    }
    
    @objc func forwardMusic() {
        counter = counter + 1
        if counter <= recordings.count - 1 {
            playTrack()
            getNowPlayInfo()
        } else {
            counter = 0
            playTrack()
            getNowPlayInfo()
        }
    }
    
    // This function use play next track after end of song
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("called")
        if flag == true {
            counter = counter + 1
            if counter <= recordings.count - 1 {
                print("next track")
                playTrack()
                getNowPlayInfo()
            } else {
                counter = 0
                playTrack()
                getNowPlayInfo()
            }
        }
    }
    
    @objc func showPlayer() {
        let vc: OfflinePlayerViewController = self.storyboard?.instantiateViewController(withIdentifier: "Offline Player") as! OfflinePlayerViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func play_Pause() {
        if titleForShow != nil {
            if flagForPlayButton == true {
                playOrPause = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(play_Pause))
                items = [titleOfNowPlay,space2,space2,space2,space2,space2,rewind,space2,playOrPause,space2,forward,space2]
                toolBar.items = items
                playMusic()
                
                flagForPlayButton = false
            } else {
                playOrPause = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(play_Pause))
                items = [titleOfNowPlay,space2,space2,space2,space2,space2,rewind,space2,playOrPause,space2,forward,space2]
                toolBar.items = items
                pauseMusic()
                flagForPlayButton = true
            }
        }
    }
    
    @objc func creatPlaylist() {
        database?.open()
        print("database opend")
        if (database?.open())! {
            // This query use for save playlist name in db
            let result = (database?.executeUpdate("INSERT INTO PlaylistsName (name) VALUES (?)", withArgumentsIn: [playlistName]))!
            if !result {
                print("Error in save: \(String(describing: database?.lastErrorMessage()))")
            } else {
                print("dont error and playlistname saved")
            }
            // This query use for save url of song into db
            for item in arrayOfSelected {
                let url = item.url
                let sort = item.sort
                let result = (database?.executeUpdate("INSERT INTO PlaylistsUrl (url,sort) VALUES (?, ?)", withArgumentsIn: [url!,sort!]))!
                if !result {
                    print("Error in save: \(String(describing: database?.lastErrorMessage()))")
                } else {
                    print("dont error and playlistname saved")
                }
            }
            // This query use for get id form playlistUrls table
            let query = "SELECT id FROM PlaylistsUrl"
            var arrayOfIdUrls = [Int32]()
            let resultSet: FMResultSet! = database?.executeQuery(query, withArgumentsIn: [])
            if (resultSet != nil) {
                while resultSet.next() {
                    let id = resultSet.int(forColumnIndex: 0)
                    arrayOfIdUrls.append(id)
                }
            }
            // This query use for add both of id in one table that called connection
            for item2 in arrayOfIdUrls {
                let result = (database?.executeUpdate("INSERT INTO Connection (playlistsName_id,playlistsUrl_id) VALUES (?, ?)", withArgumentsIn: [playlistNameId,item2]))!
                if !result {
                    print("Error in save: \(String(describing: database?.lastErrorMessage()))")
                } else {
                    print("dont error and playlistname saved")
                }
            }
        }
        database?.close()
        print("db closed \n\n")
        navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func cancelButton() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func DownloadFile(_ sender: Any) {
        let alert = UIAlertController(title: "دانلود", message: "انتخاب کنید", preferredStyle: UIAlertController.Style.actionSheet)
        alert.addAction(UIAlertAction(title: "مشاهده لیست دانلود ها", style: UIAlertAction.Style.default, handler: { (action) in
            var vc: UIViewController = UIViewController()
            vc = self.storyboard?.instantiateViewController(withIdentifier: "Downloading List") as! InDownloadViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "دانلود فایل جدید", style: UIAlertAction.Style.default, handler: { (action) in
            let alert = UIAlertController(title: "دانلود موسیقی", message: "لینک و اسم فایل مورد نظر برای ذخیره را وارد کنید", preferredStyle: .alert)
            //2. Add the text field. You can configure it however you need.
            alert.addTextField(configurationHandler: { (linkForDwonload) in
                linkForDwonload.text = ""
                linkForDwonload.placeholder = "لینک دانلود"
            })
            // 3. Grab the value from the text field, and print it when the user clicks OK.
            alert.addAction(UIAlertAction(title: "دانلود", style: .default, handler: { [weak alert] (_) in
                guard let link = alert?.textFields![0] else  { return }
                if link.text != "" && link.text?.suffix(4) == ".mp3" {
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
