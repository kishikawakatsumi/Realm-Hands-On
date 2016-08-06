//
//  FavoritesViewController.swift
//  Twitter
//
//  Created by kishikawakatsumi on 3/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import UIKit
import RealmSwift

class FavoritesViewController: UITableViewController {

    var likes: Results<Tweet>?
    var notificationToken: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerNib(UINib(nibName: "TimelineCell", bundle: nil), forCellReuseIdentifier: "timelineCell")
        tableView.rowHeight = 90
        tableView.estimatedRowHeight = 90

        let realm = try! Realm()
        likes = realm.objects(Tweet).filter("favorited = %@", true).sorted("createdAt", ascending: false)
        notificationToken = likes?.addNotificationBlock { [weak self] (change) in
            switch change {
            case .Initial(_):
                self?.tableView.reloadData()
            case .Update(_, deletions: _, insertions: _, modifications: _):
                self?.tableView.reloadData()
            case .Error(_):
                return
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likes?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("timelineCell", forIndexPath: indexPath) as! TimelineCell

        let tweet = likes![indexPath.row]

        cell.nameLabel.text = tweet.name
        cell.tweetTextView.text = tweet.text

        NSURLSession.sharedSession().dataTaskWithRequest(NSURLRequest(URL: NSURL(string: tweet.iconURL)!)) { (data, response, error) -> Void in
            if let _ = error {
                return
            }

            dispatch_async(dispatch_get_main_queue()) {
                let image = UIImage(data: data!)!
                cell.iconView.image = image
            }
        }.resume()

        return cell
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

}
