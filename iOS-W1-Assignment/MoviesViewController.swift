//
//  MoviesViewController.swift
//  iOS-W1-Assignment
//
//  Created by Van Do on 10/12/16.
//  Copyright © 2016 Van Do. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD
import ReachabilitySwift

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var moviesTableView: UITableView!
    @IBOutlet weak var errorLabel: UILabel!
    
    let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
    let apiEndpoint = "https://api.themoviedb.org/3/movie/now_playing?api_key="
    let baseUrl = "https://image.tmdb.org/t/p/w342"
    let reachability: Reachability! = Reachability()
    
    var refreshControl: UIRefreshControl!
    
    var movies : [NSDictionary] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(receiveNotification(_:)), name: ReachabilityChangedNotification, object: reachability)
        
        do{
            try reachability.startNotifier()
        } catch{
            print("could not start reachability notifier")
        }
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(loadMovies(_:)), for:UIControlEvents.valueChanged)
        
        moviesTableView.insertSubview(refreshControl, at: 0)
        
        moviesTableView.dataSource = self
        moviesTableView.delegate = self
        
        loadMovies(refreshControl)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func receiveNotification(_ note: NSNotification) {
        let reach = note.object as! Reachability
        
        if (reach.isReachableViaWiFi || reach.isReachableViaWWAN) {
            UIView.animate(withDuration: 1) { self.errorLabel.isHidden = true }
        }
        else {
            UIView.animate(withDuration: 1) { self.errorLabel.isHidden = false }
        }
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count;
    }
    
    
    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "movieCell") as! MovieTableViewCell
        
        cell.titleLabel.text = movies[indexPath.row]["title"] as? String
        cell.overviewLabel.text = movies[indexPath.row]["overview"] as? String
        
       let posterUrl = baseUrl + ((movies[indexPath.row]["poster_path"] as? String) ?? "")
        cell.posterImageView.setImageWith(URL(string: posterUrl)!)
        
        return cell
    }
    
    public func loadMovies(_ refreshControl: UIRefreshControl) {
        let urlOrNil = URL(string: apiEndpoint + apiKey)
        
        if let url = urlOrNil, reachability.isReachable {
            let request = URLRequest(
                url: url,
                cachePolicy: NSURLRequest.CachePolicy.reloadIgnoringLocalCacheData,
                timeoutInterval: 10)
            
            let session = URLSession(
                configuration: URLSessionConfiguration.default,
                delegate: nil,
                delegateQueue: OperationQueue.main)
            
            MBProgressHUD.showAdded(to: self.view, animated: true)
            
            let task = session.dataTask(
                with: request,
                completionHandler: { (dataOrNil, response, error) in
                    if let data = dataOrNil {
                        if let responseDictionary = (try! JSONSerialization.jsonObject(with: data, options: [])) as? NSDictionary {
                            print("response: \(responseDictionary)")
                            if let moviesArray = responseDictionary["results"] as? [NSDictionary] {
                                MBProgressHUD.hide(for: self.view, animated: true)
                                
                                self.movies = moviesArray
                                self.moviesTableView.reloadData()
                                self.refreshControl.endRefreshing()
                            }
                        }
                    }
            })
            
            task.resume()
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let detailVC = segue.destination as! DetailViewController
        let indexPath = moviesTableView.indexPathForSelectedRow
        
        if let indexPath = indexPath {
            detailVC.overview = movies[indexPath.row]["overview"] as? String
            
            let posterUrl = baseUrl + ((movies[indexPath.row]["poster_path"] as? String) ?? "")
            detailVC.posterUrl = posterUrl
        }
    }
}
