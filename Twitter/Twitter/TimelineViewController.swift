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
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) { (granted, error) -> Void in
            if granted {
                let accounts = accountStore.accountsWithAccountType(accountType)
                if let account = accounts.first as? ACAccount {
                    self.account = account
                    self.getHomeTimeline()
                } else {
                    self.showAlert("No Twitter account")
                }
            } else {
                self.showAlert("No account access")
            }
        }

        tableView.registerNib(UINib(nibName: "TimelineCell", bundle: nil), forCellReuseIdentifier: "timelineCell")
        tableView.rowHeight = 90
        tableView.estimatedRowHeight = 90

        let realm = try! Realm()
        timeline = realm.objects(Tweet).sorted("createdAt", ascending: false)
        notificationToken = timeline?.addNotificationBlock { [weak self] (results, error) -> () in
            if let _ = error {
                return
            }
            self?.tableView.reloadData()
        }

        refreshControl?.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
    }

    func refresh(sender: UIRefreshControl) {
        if let _ = self.account {
            getHomeTimeline()
        }
    }

    func getHomeTimeline() {
        let requestURL = NSURL(string: "https://api.twitter.com/1/statuses/home_timeline.json")
        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: requestURL, parameters: nil)
        request.account = account

        request.performRequestWithHandler { (data, response, error) -> Void in
            if let error = error {
                self.showAlert(error.localizedDescription)
                return
            }

            do {
                let results = try NSJSONSerialization.JSONObjectWithData(data, options: [])
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

            dispatch_async(dispatch_get_main_queue()) {
                self.refreshControl?.endRefreshing()
            }
        }
    }

    func postFavorite(id: String) {
        let realm = try! Realm()
        guard let tweet = realm.objectForPrimaryKey(Tweet.self, key: id) else {
            return
        }

        let requestURL: NSURL
        if tweet.favorited {
            requestURL = NSURL(string: "https://api.twitter.com/1.1/favorites/destroy.json")!
        } else {
            requestURL = NSURL(string: "https://api.twitter.com/1.1/favorites/create.json")!
        }

        let request = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, URL: requestURL, parameters: ["id": id])
        request.account = account

        request.performRequestWithHandler { (data, response, error) -> Void in
            if let error = error {
                self.showAlert(error.localizedDescription)
                return
            }

            let realm = try! Realm()
            if let tweet = realm.objectForPrimaryKey(Tweet.self, key: id) {
                try! realm.write {
                    tweet.favorited = !tweet.favorited
                }
            }
        }
    }

    func showAlert(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return timeline?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("timelineCell", forIndexPath: indexPath) as! TimelineCell

        let tweet = timeline![indexPath.row]

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

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tweet = timeline![indexPath.row]
        postFavorite(tweet.id)

        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}
