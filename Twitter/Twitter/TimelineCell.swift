//
//  TimelineCell.swift
//  Twitter
//
//  Created by kishikawakatsumi on 3/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import UIKit

class TimelineCell: UITableViewCell {
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var tweetTextView: UITextView!

    override func prepareForReuse() {
        iconView.image = nil
        nameLabel.text = nil
        tweetTextView.text = nil
    }
}
