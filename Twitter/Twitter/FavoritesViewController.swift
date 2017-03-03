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

        tableView.register(UINib(nibName: "TimelineCell", bundle: nil), forCellReuseIdentifier: "timelineCell")
        tableView.rowHeight = 90
        tableView.estimatedRowHeight = 90

        let realm = try! Realm()
        likes = realm.objects(Tweet.self).filter("favorited = %@", true).sorted(byKeyPath: "createdAt", ascending: false)
        notificationToken = likes?.addNotificationBlock { [weak self] (change) in
            switch change {
            case .initial(_):
                self?.tableView.reloadData()
            case .update(_, deletions: _, insertions: _, modifications: _):
                self?.tableView.reloadData()
            case .error(_):
                return
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return likes?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "timelineCell", for: indexPath) as! TimelineCell

        let tweet = likes![indexPath.row]

        cell.nameLabel.text = tweet.name
        cell.tweetTextView.text = tweet.text

        URLSession.shared.dataTask(with: URLRequest(url: URL(string: tweet.iconURL)!)) { (data, response, error) -> Void in
            if let _ = error {
                return
            }

            DispatchQueue.main.async {
                let image = UIImage(data: data!)!
                cell.iconView.image = image
            }
        }.resume()

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

}
