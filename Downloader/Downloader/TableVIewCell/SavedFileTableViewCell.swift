//
//  SavedFileTableViewCell.swift
//  Downloader
//
//  Created by Iman on 4/5/19.
//  Copyright © 2019 iman. All rights reserved.
//

import UIKit

class SavedFileTableViewCell: UITableViewCell {
    @IBOutlet weak var imageOfMusicImageView: UIImageView!
    @IBOutlet weak var nameOfMusicLabel: UILabel!
    @IBOutlet weak var inPlayingImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageOfMusicImageView.layer.cornerRadius = 15
        imageOfMusicImageView.layer.masksToBounds = true
        nameOfMusicLabel.layer.shadowOffset = CGSize(width: 0, height: 5)
        nameOfMusicLabel.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        nameOfMusicLabel.layer.shadowOpacity = 0.5
        inPlayingImageView.layer.shadowOpacity = 0.5
        inPlayingImageView.layer.shadowColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        inPlayingImageView.layer.shadowOffset = CGSize(width: 0, height: 5)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
