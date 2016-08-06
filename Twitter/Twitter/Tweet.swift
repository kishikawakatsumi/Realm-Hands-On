//
//  Tweet.swift
//  Twitter
//
//  Created by kishikawakatsumi on 3/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import UIKit
import RealmSwift

class Tweet: Object {
    dynamic var name = ""
    dynamic var text = ""
    dynamic var iconURL = ""
    dynamic var id = ""
    dynamic var createdAt = NSDate()

    dynamic var favorited = false

    static var dateFormatter: NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE MMM dd HH:mm:ss Z yyyy"
        return dateFormatter
    }

    convenience init(tweetDictionary: [String: AnyObject]) {
        self.init()
        let user = tweetDictionary["user"] as! [String: AnyObject]
        name = user["name"] as! String
        text = tweetDictionary["text"] as! String

        iconURL = user["profile_image_url_https"] as! String

        id = tweetDictionary["id_str"] as! String
        createdAt = Tweet.dateFormatter.dateFromString(tweetDictionary["created_at"] as! String)!

        favorited = tweetDictionary["favorited"] as! Bool
    }

    override class func primaryKey() -> String? {
        return "id"
    }
}
