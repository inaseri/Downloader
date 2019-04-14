//
//  NowPlayViewController.swift
//  Downloader
//
//  Created by Iman on 4/4/19.
//  Copyright © 2019 iman. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import MobileCoreServices
import Network

var linkForDownloadGlobal: String!
var arrayForDownload = [String]()

class NowPlayViewController: UIViewController, AVAudioPlayerDelegate {

    // View Variables
    @IBOutlet weak var albumeArt: UIImageView!
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var endTimeLabel: UILabel!
    
    // Variable for player and notficatin center and slider
    var audioSession = AVAudioSession.sharedInstance()
    var nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    var remoCommandCenter = MPRemoteCommandCenter.shared()
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    var player = AVPlayer()
    var playerItem:AVPlayerItem?
    var timer: Timer?
    
    // Globale variables
    var urlForPlay = ""
    var downloadLink: String!
    var titleForBacground: String!
    var artistForBackground: String!
    var currentTimeForBackground: Float!
    
    // Globale variabeles for check net is connetcted or not
    let monitor = NWPathMonitor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        albumeArt.layer.masksToBounds = true
        albumeArt.layer.cornerRadius = CGFloat(15)
        // Active Player In Notfication Center
        try! self.audioSession.setActive(true)
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.allowAirPlay)
        } catch {
            print("error: \(error)")
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
        self.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    
    // This function use for show Detail of now play in notfication center
    func updateNowPlayingInfo() {
        nowPlayingInfoCenter.nowPlayingInfo = [MPMediaItemPropertyTitle: titleForBacground,
                                               MPMediaItemPropertyArtist: artistForBackground,
                                               MPMediaItemPropertyPlaybackDuration: currentTimeForBackground
        ]
        remoCommandCenter.seekForwardCommand.isEnabled = false
        remoCommandCenter.seekBackwardCommand.isEnabled = false
        remoCommandCenter.previousTrackCommand.isEnabled = false
        remoCommandCenter.nextTrackCommand.isEnabled = false
        remoCommandCenter.togglePlayPauseCommand.isEnabled = false
        remoCommandCenter.playCommand.addTarget(self, action: #selector(playTrack))
        remoCommandCenter.pauseCommand.addTarget(self, action: #selector(puseTrack))
    }
    
    func getLinkForStream() {
        let url = URL(string: urlForPlay)
        let playerItem:AVPlayerItem = AVPlayerItem(url: url!)
        player = AVPlayer(playerItem: playerItem)
        updateSliderTimer()
        let metaDataList = playerItem.asset.commonMetadata
        for item in metaDataList {
            
            guard let key = item.commonKey?.rawValue, let value = item.value else{
                continue
            }
            switch key {
            case "title" : songNameLabel.text = value as? String
            case "artist": artistNameLabel.text = value as? String
            case "artwork" where value is Data : albumeArt.image = UIImage(data: value as! Data)
            default:
                continue
            }
        }
        
        // These codes use for set duration of trak
        let duration = Float(CMTimeGetSeconds(playerItem.asset.duration))
        slider.minimumValue = 0
        slider.maximumValue = duration
        let mins = duration / 60
        let secs = duration.truncatingRemainder(dividingBy: 60)
        let timeFormatter = NumberFormatter()
        timeFormatter.minimumIntegerDigits = 2
        timeFormatter.minimumFractionDigits = 0
        timeFormatter.roundingMode = .down
        guard let minStr = timeFormatter.string(from: NSNumber(value: mins)), let secStr = timeFormatter.string(from: NSNumber(value: secs)) else { return }
        endTimeLabel.text = "\(minStr).\(secStr)"
        player.play()
        updateNowPlayingInfo()
        scheduledTimerWithTimeInterval()
    }
  
    @objc func playTrack() {
        if player.rate == 0 {
            player.play()
            slider.isContinuous = true
            updateSliderTimer()
            scheduledTimerWithTimeInterval()
        }
    }
    
    @objc func puseTrack() {
        player.pause()
        timer?.invalidate()
    }
    
    // This function use for update slider timer in every second
    @objc func updateSliderTimer() {
        let currnetTimeSecond = CMTimeGetSeconds(player.currentTime())
        let mins = currnetTimeSecond / 60
        let secs = currnetTimeSecond.truncatingRemainder(dividingBy: 60)
        let timeFormatter = NumberFormatter()
        timeFormatter.minimumIntegerDigits = 2
        timeFormatter.minimumFractionDigits = 0
        timeFormatter.roundingMode = .down
        guard let minStr = timeFormatter.string(from: NSNumber(value: mins)), let secStr = timeFormatter.string(from: NSNumber(value: secs)) else { return }
        currentTimeLabel.text = "\(minStr).\(secStr)"
        slider.value = Float(currnetTimeSecond)
        if let currentItem = player.currentItem {
            let duration = currentItem.duration
            if (CMTIME_IS_VALID(duration)) {
                return
            }
            let currentTime = currentItem.currentTime()
            currentTimeForBackground = Float(CMTimeGetSeconds(currentTime)) / Float(CMTimeGetSeconds(duration))
            slider.setValue(Float(CMTimeGetSeconds(currentTime)) / Float(CMTimeGetSeconds(duration)), animated: true)
        }
    }
    
    // This Function Use For Update Every Second Of Slider Now Play
    func scheduledTimerWithTimeInterval() {
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateSliderTimer), userInfo: nil, repeats: true)
    }
    
    @IBAction func streamButton(_ sender: Any) {
        let alert = UIAlertController(title: "پخش انلاین", message: "برای پخش انلاین لینک خود را وارد کنید", preferredStyle: UIAlertController.Style.alert)
        alert.addTextField { (textFiled) in
            textFiled.placeholder = "لینک خود را وارد کنید"
        }
        alert.addAction(UIAlertAction(title: "پخش", style: .default, handler: { [weak alert] (_) in
            guard let url = alert?.textFields![0] else { return } // Force unwrapping because we know it exists.
            if url.text != "" && url.text?.suffix(4) == ".mp3" {
                self.urlForPlay = (url.text)!
                self.getLinkForStream()
                self.player.play()
            } else {
                let alert = UIAlertController(title: "خطا", message: "لینک دانلود خود را بررسی کنید", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "تایید", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "انصراف", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func changeSlider(_ sender: UISlider) {
        let currnetValue = sender.value
        let mins = currnetValue / 60
        let secs = currnetValue.truncatingRemainder(dividingBy: 60)
        let timeFormatter = NumberFormatter()
        timeFormatter.minimumIntegerDigits = 2
        timeFormatter.minimumFractionDigits = 0
        timeFormatter.roundingMode = .down
        guard let minStr = timeFormatter.string(from: NSNumber(value: mins)), let secStr = timeFormatter.string(from: NSNumber(value: secs)) else { return }
        currentTimeLabel.text = "\(minStr).\(secStr)"
        slider.setValue(currnetValue, animated: true)
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            self.slider.setValue(currnetValue, animated: true)
        }, completion: nil)
        let timeToSeek: CMTime = CMTimeMake(value: Int64(currnetValue), timescale: 1)
        player.seek(to: timeToSeek)
    }
    
    @IBAction func playButton(_ sender: Any) {
        playTrack()
    }
    
    @IBAction func pauseButton(_ sender: Any) {
        puseTrack()
    }

}
