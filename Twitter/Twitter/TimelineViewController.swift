//
//  TimelineViewController.swift
//  Twitter
//
//  Created by kishikawakatsumi on 3/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import UIKit
import Accounts
import Social
import RealmSwift

class TimelineViewController: UITableViewController {

    var timeline: Results<Tweet>?
    var notificationToken: NotificationToken?

    var account: ACAccount?

    deinit {
        notificationToken?.stop()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let accountStore = ACAccountStore()
        let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: accountType, options: nil) { (granted, error) -> Void in
            if granted {
                let accounts = accountStore.accounts(with: accountType)
                if let account = accounts?.first as? ACAccount {
                    self.account = account
                    self.getHomeTimeline()
                } else {
                    self.showAlert("No Twitter account")
                }
            } else {
                self.showAlert("No account access")
            }
        }

        tableView.register(UINib(nibName: "TimelineCell", bundle: nil), forCellReuseIdentifier: "timelineCell")
        tableView.rowHeight = 90
        tableView.estimatedRowHeight = 90

        let realm = try! Realm()
        timeline = realm.objects(Tweet.self).sorted(byKeyPath: "createdAt", ascending: false)
        notificationToken = timeline?.addNotificationBlock { [weak self] (change) in
            switch change {
            case .initial(_):
                self?.tableView.reloadData()
            case .update(_, deletions: _, insertions: _, modifications: _):
                self?.tableView.reloadData()
            case .error(_):
                return
            }
        }

        refreshControl?.addTarget(self, action: #selector(TimelineViewController.refresh(_:)), for: .valueChanged)
    }

    func refresh(_ sender: UIRefreshControl) {
        if let _ = self.account {
            getHomeTimeline()
        }
    }

    func getHomeTimeline() {
        let requestURL = URL(string: "https://api.twitter.com/1/statuses/home_timeline.json")
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, url: requestURL, parameters: nil)
        request?.account = account

        request?.perform { (data, response, error) -> Void in
            if let error = error {
                self.showAlert(error.localizedDescription)
                return
            }

            do {
                let results = try JSONSerialization.jsonObject(with: data!, options: [])
                if let results = results as? NSDictionary {
                    let errors = results["errors"] as! [[String: AnyObject]]
                    let message = errors.last!["message"] as! String
                    self.showAlert(message)
                    return
                }

                let timeline = results as! [[String: AnyObject]]

                let realm = try! Realm()
                try! realm.write {
                    timeline.forEach { (tweetDictionary) -> () in
                        let tweet = Tweet(tweetDictionary: tweetDictionary)
                        realm.add(tweet, update: true)
                    }
                }
            } catch let error as NSError {
                self.showAlert(error.localizedDescription)
            }

            DispatchQueue.main.async {
                self.refreshControl?.endRefreshing()
            }
        }
    }

    func postFavorite(_ id: String) {
        let realm = try! Realm()
        guard let tweet = realm.object(ofType: Tweet.self, forPrimaryKey: id) else {
            return
        }

        let requestURL: URL
        if tweet.favorited {
            requestURL = URL(string: "https://api.twitter.com/1.1/favorites/destroy.json")!
        } else {
            requestURL = URL(string: "https://api.twitter.com/1.1/favorites/create.json")!
        }

        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, url: requestURL, parameters: ["id": id])
        request?.account = account

        request?.perform { (data, response, error) -> Void in
            if let error = error {
                self.showAlert(error.localizedDescription)
                return
            }

            let realm = try! Realm()
            if let tweet = realm.object(ofType: Tweet.self, forPrimaryKey: id) {
                try! realm.write {
                    tweet.favorited = !tweet.favorited
                }
            }
        }
    }

    func showAlert(_ message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeline?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "timelineCell", for: indexPath) as! TimelineCell

        let tweet = timeline![indexPath.row]

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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tweet = timeline![indexPath.row]
        postFavorite(tweet.id)

        tableView.deselectRow(at: indexPath, animated: true)
    }

}
