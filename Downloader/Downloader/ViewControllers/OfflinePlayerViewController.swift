//
//  OfflinePlayerViewController.swift
//  Downloader
//
//  Created by Iman on 4/5/19.
//  Copyright © 2019 iman. All rights reserved.
//

import UIKit
import MediaPlayer
import EventKitUI

var titleForShow: String!
var artistForShow: String!
var imageForSHow: Data!

class OfflinePlayerViewController: UIViewController, FileManagerDelegate, UIDocumentInteractionControllerDelegate, AVAudioPlayerDelegate{

    let notification = NotificationCenter.default
    var flagForPlayButton = true
    var items = [UIBarButtonItem]()
    let space1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    let rewindMusic = UIBarButtonItem(barButtonSystemItem: .rewind, target: self, action: #selector(rewind))
    var playOrPause = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(play_Pause))
    let forwardMusic = UIBarButtonItem(barButtonSystemItem: .fastForward, target: self, action: #selector(forward))
    let space2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    
    // Variables for play musics
    var timer: Timer?
    var recordings = [URL]()
    var audioSession = AVAudioSession.sharedInstance()
    var nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
    var remoCommandCenter = MPRemoteCommandCenter.shared()
    var artWorkName: String!
    
    // Variabes for show detail
    @IBOutlet weak var artWorkImageView: UIImageView!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var maxTimeLabel: UILabel!
    @IBOutlet weak var titleOfMusicLabel: UILabel!
    @IBOutlet weak var aritstOfMusicLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var toolBar: UIToolbar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        creatToolBar()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        reloadInputViews()
        try! self.audioSession.setActive(true)
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.allowAirPlay)
        } catch {
            print("error: \(error)")
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
        // These  lines use for update slier
        
        if sliderMaxValueGlobal != nil {
            slider.maximumValue = sliderMaxValueGlobal
            updateSliderTimer()
            scheduledTimerWithTimeInterval()
            slider.isContinuous = true
        }
        
        // Theses linse use for put string in labes in player
        if titleForShow == nil && artistForShow == nil {
            titleOfMusicLabel.text = "Not Playing"
            aritstOfMusicLabel.text = "Not Playing"
        } else {
            titleOfMusicLabel.text = titleForShow
            aritstOfMusicLabel.text = artistForShow
        }
        
        // These lines use for get max time of now play
        if sliderMaxValueGlobal != nil {
            let mins = sliderMaxValueGlobal / 60
            let secs = sliderMaxValueGlobal.truncatingRemainder(dividingBy: 60)
            let timeFormatter = NumberFormatter()
            timeFormatter.minimumIntegerDigits = 2
            timeFormatter.minimumFractionDigits = 0
            timeFormatter.roundingMode = .down
            guard let minStr = timeFormatter.string(from: NSNumber(value: mins)), let secStr = timeFormatter.string(from: NSNumber(value: secs)) else { return }
            maxTimeLabel.text = "\(minStr).\(secStr)"
        }
        
        // This line use for set artwork on now play
        if imageForSHow != nil {
            artWorkImageView.image = UIImage(data: imageForSHow!)
            artWorkImageView.layer.masksToBounds = true
            artWorkImageView.layer.cornerRadius = CGFloat(15)
        } else {
            artWorkImageView.layer.masksToBounds = true
            artWorkImageView.layer.cornerRadius = CGFloat(15)
        }
        updateNowPlayingInfo()
    }
    
    func creatToolBar() {
        items = [space1,rewindMusic,space1,playOrPause,space1,forwardMusic,space2]
        if titleForShow != nil {
            playOrPause = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(play_Pause))
            items = [space1,rewindMusic,space1,playOrPause,space1,forwardMusic,space2]
            toolBar.items = items
            play()
            flagForPlayButton = false
        }
        toolBar.items = items
        toolBar.tintColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
    }
    
    // This function use for show Detail of now play in notfication center
    func updateNowPlayingInfo() {
        nowPlayingInfoCenter.nowPlayingInfo = [MPMediaItemPropertyTitle: titleForShow,
                                               MPMediaItemPropertyArtist: artistForShow,
                                               MPMediaItemPropertyPlaybackDuration: sliderMaxValueGlobal,
                                               MPMediaItemPropertyBookmarkTime: sliderValueGlobal,
        ]
        remoCommandCenter.seekForwardCommand.isEnabled = false
        remoCommandCenter.seekBackwardCommand.isEnabled = false
        remoCommandCenter.previousTrackCommand.isEnabled = true
        remoCommandCenter.nextTrackCommand.isEnabled = true
        remoCommandCenter.togglePlayPauseCommand.isEnabled = true
        remoCommandCenter.nextTrackCommand.addTarget(self, action: #selector(forward))
        remoCommandCenter.previousTrackCommand.addTarget(self, action: #selector(rewind))
        remoCommandCenter.playCommand.addTarget(self, action: #selector(play))
        remoCommandCenter.pauseCommand.addTarget(self, action: #selector(pause))
    }
    
    // This is use for set slider value and the timer label and get the current time of song
    @objc func updateSliderTimer() {
        slider.value = sliderValueGlobal
        let mins = sliderValueGlobal / 60
        let secs = sliderValueGlobal.truncatingRemainder(dividingBy: 60)
        let timeFormatter = NumberFormatter()
        timeFormatter.minimumIntegerDigits = 2
        timeFormatter.minimumFractionDigits = 0
        timeFormatter.roundingMode = .down
        guard let minStr = timeFormatter.string(from: NSNumber(value: mins)), let secStr = timeFormatter.string(from: NSNumber(value: secs)) else { return }
        currentTimeLabel.text = "\(minStr).\(secStr)"
    }
    
    func scheduledTimerWithTimeInterval() {
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(updateSliderTimer), userInfo: nil, repeats: true)
    }
    
    @objc func forward() {
        notification.post(name: Notification.Name("forwardMusic"), object: nil)
    }
    
    @objc func play() {
        notification.post(name: Notification.Name("PlayMusic"), object: nil)
    }
    
    @objc func rewind() {
        notification.post(name: Notification.Name("RewindMusic"), object: nil)
    }
    
    @objc func pause() {
        notification.post(name: Notification.Name("StopMusic"), object: nil)
    }
    
    @IBAction func sliderChange(_ sender: UISlider) {
        sliderValueGlobal = sender.value
        notification.post(name: Notification.Name("SliderChange"), object: nil)
    }
    
    @objc func play_Pause() {
        if titleForShow != nil {
            if flagForPlayButton == true {
                playOrPause = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(play_Pause))
                items = [space1,rewindMusic,space1,playOrPause,space1,forwardMusic,space2]
                toolBar.items = items
                play()
                flagForPlayButton = false
            } else {
                playOrPause = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(play_Pause))
                items = [space1,rewindMusic,space1,playOrPause,space1,forwardMusic,space2]
                toolBar.items = items
                pause()
                flagForPlayButton = true
            }
        }
    }
}
