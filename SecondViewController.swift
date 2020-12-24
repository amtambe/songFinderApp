//
//  SecondViewController.swift
//  Song Finder
//
//  Created by Arjun Tambe on 7/11/16.
//  Copyright © 2016 Arjun Tambe. All rights reserved.
//

/* FEATURES TO INTEGRATE:
    -save and display search history; allow search history elements to be clicked to automatically search, like spotify
    -now playing display bar somewhere, and allow user to see more info including cover art
    -forward and backward feature, and a play queue [need to discuss how queue will work]
    -allow play/pause control from the control panel
    -display play time in the control panel
    -soundcloud uses the web app, instead of the ios app. won't allow saved music to play from it
    -add youtube
 */

import Foundation
import MediaPlayer
import UIKit

class SecondViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var resultsArray = [SongData]()
    var trackManager = TrackManager()
    
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet weak var resultsTable: UITableView!
    @IBOutlet var playPauseButton: UIButton!
    let tapRecognizer = UITapGestureRecognizer()
    
    var spotifyResults: [AnyObject!] = []
    var appleMusicResults: [AnyObject!] = []
    var soundCloudResults: [AnyObject!] = []
    var localResults: [AnyObject!] = []

    var findResultsGroup = dispatch_group_create()

    override func viewDidLoad() {
        if (loggedInSpotify) {
            completeSpotifyLogin()
        }
        
        searchBar.delegate = self
        
        resultsTable.dataSource = self
        resultsTable.delegate = self
        
        let selector = #selector(self.handleTap(_:))
        let tapGesture = UITapGestureRecognizer(target: self, action: selector)
        tapGesture.cancelsTouchesInView = false
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
    }
    
    func handleTap(sender: UITapGestureRecognizer) {
        self.searchBar.endEditing(true)
    }

    
    func completeSpotifyLogin() {
        if (spotifyPlayer == nil) {
            spotifyPlayer = SPTAudioStreamingController(clientId: spotifyID)
        }
        spotifyPlayer!.loginWithSession(SPTAuth.defaultInstance().session, callback: { (error) in
            if error != nil {
                print ("error logging in: \(error)")
                return;
            }
        })
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        //clear results
        
    }

    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        let query = searchBar.text
        
        if (loggedInSpotify) {
            searchSpotify(query!)
        }
        if (loggedInAppleMusic) {
            searchAppleMusic(query!)
        }
        if (loggedInSoundCloud) {
            searchSoundCloud(query!)
        }
        searchLocalMusic(query!)
        
        self.searchBar.endEditing(true)
        
        dispatch_group_notify(findResultsGroup, dispatch_get_main_queue()) {
            if (loggedInSpotify) {
                self.convertSongData(&self.spotifyResults, platform: Platform.spotify)
            }
            if (loggedInAppleMusic) {
                self.convertSongData(&self.appleMusicResults, platform: Platform.appleMusic)
            }
            if (loggedInSoundCloud) {
                self.convertSongData(&self.soundCloudResults, platform: Platform.soundCloud)
            }
            self.convertSongData(&self.localResults, platform: Platform.local)
            self.resultsArray = self.compileResults()
            self.resultsTable.reloadData()
        }
    }
    
    func convertSongData(inout resultArray: [AnyObject!], platform: Platform) {
        var newArray = [SongData]()
        
        for i in 0..<resultArray.count {
            let song = SongData(song: resultArray[i], songPlatform: platform)
            newArray.append(song)
            print(song.getName())
        }
        resultArray = newArray
    }
    
    func compileResults() -> [SongData] {
        var returnArray = [SongData]()
        
        for i in 0..<2 {
            if (loggedInSpotify) {
                if (spotifyResults.count > i) {
                    returnArray.append((spotifyResults[i] as! SongData))
                }
            }
            if (loggedInAppleMusic) {
                if (appleMusicResults.count > i) {
                    returnArray.append((appleMusicResults[i] as! SongData))
                }
            }
            if (loggedInSoundCloud) {
                if (soundCloudResults.count > i) {
                    returnArray.append((soundCloudResults[i] as! SongData))
                }
            }
            if (localResults.count > i) {
                returnArray.append(localResults[i] as! SongData)
            }
        }
        return returnArray
    }
    

    
    func searchAppleMusic(input: String) {
        dispatch_group_enter(self.findResultsGroup)
        let queryURL = convertToHTML(input)
        let url = NSURL(string: queryURL)!
        let request: NSURLRequest = NSURLRequest(URL: url)
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            if error != nil {
                print (error)
                return
            }
    
            do {
                let resultJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                if resultJSON.count>0 && resultJSON["results"]!.count>0 {
                    if (self.appleMusicResults.count > 0) {
                        self.appleMusicResults.removeAll()
                    }
                    self.appleMusicResults = resultJSON["results"] as! [Dictionary<String, AnyObject>]
                    dispatch_group_leave(self.findResultsGroup)
                }
                
            } catch {
                print ("error")
            }
        }
        task.resume()
    }
    
    
    //converts string to HTML for searchAppleMusic
    private func convertToHTML(input: String) -> String{
        let itunesSearchTerm = input.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        let result = itunesSearchTerm.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
        return("https://itunes.apple.com/search?term=\(result)&media=music&entity=song&attribute=songTerm")
    }

    //Searches spotify based on an input string
    func searchSpotify(searchTerm: String) {
        dispatch_group_enter(findResultsGroup)
        SPTSearch.performSearchWithQuery(searchTerm, queryType: SPTSearchQueryType.QueryTypeTrack, accessToken: SPTAuth.defaultInstance().session.accessToken) { (error, searchResult) in
            if (error != nil) {
                print("error: \(error)")
            } else {
                if (self.spotifyResults.count > 0) {
                    self.spotifyResults.removeAll()
                }
                if ((searchResult as! SPTListPage).totalListLength > 0) {
                    self.spotifyResults = (searchResult as! SPTListPage).items
                } else {
                    //need some handling if no results
                }
                dispatch_group_leave(self.findResultsGroup)
            }
        }
    }
    
    
    
    func searchSoundCloud(input: String) {
        let queryHTMLForm = input.stringByReplacingOccurrencesOfString(" ", withString: "%20")
        let startOfURL =
        "https://api.soundcloud.com/tracks.json?oauth_token=" + scToken! + "&client_id=" + soundcloudID + "&q="
        let url = NSURL(string: startOfURL + queryHTMLForm)
        
        dispatch_group_enter(findResultsGroup)
        var jsonString = ""
        do {
            jsonString = try String(contentsOfURL: url!, encoding: NSUTF8StringEncoding)
        } catch {
            print (error)
        }
        
        let data: NSData = jsonString.dataUsingEncoding(NSUTF8StringEncoding)!

        do {
            if (soundCloudResults.count > 0) {
                soundCloudResults.removeAll()
            }
            soundCloudResults = try (NSJSONSerialization.JSONObjectWithData(data, options:    NSJSONReadingOptions(rawValue: 0)) as! NSArray) as! [Dictionary<String, AnyObject>]
            dispatch_group_leave(findResultsGroup)
            
        } catch {
            print (error)
        }
    }
    
    func searchLocalMusic(searchTerm: String) {
        dispatch_group_enter(findResultsGroup)
        let query = MPMediaQuery.songsQuery()
        let predicate = MPMediaPropertyPredicate(value: searchTerm, forProperty: MPMediaItemPropertyTitle, comparisonType: MPMediaPredicateComparison.Contains)
        query.addFilterPredicate(predicate)
        
        if (localResults.count > 0) {
            localResults.removeAll()
        }
        localResults = query.items!
        dispatch_group_leave(findResultsGroup)
    }

    
    func numberOfSectionsInTableview(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView:UITableView, numberOfRowsInSection section:Int) -> Int
    {
        return resultsArray.count
    }
    
    
    func tableView(tableView: UITableView,
                   cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell: UITableViewCell = UITableViewCell(style:UITableViewCellStyle.Default, reuseIdentifier:"cell0")
        cell.textLabel?.text = "\(resultsArray[indexPath.row].getName()) ( \(resultsArray[indexPath.row].getPlatform())"
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedSong = resultsArray[indexPath.row] 
        trackManager.beginPlaying(selectedSong)
        playPauseButton.setBackgroundImage(UIImage(named: "pause.png"), forState: UIControlState.Normal)
    }
    
    
    @IBAction func playPauseButtonPressed(sender: AnyObject!) {
        if(trackManager.playing()) {
            pause()
        } else {
            resume()
        }
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {

        let type = event!.subtype
        if (type == UIEventSubtype.RemoteControlPlay) {
            resume()
        } else if (type == UIEventSubtype.RemoteControlPause) {
            pause()
        } else if (type == UIEventSubtype.RemoteControlNextTrack) {
            //handle next track command
        } else if (type == UIEventSubtype.RemoteControlPreviousTrack) {
            //handle previous track command
        }     }
    
    private func pause() {
        trackManager.pause()
        playPauseButton.setBackgroundImage(UIImage(named: "play.jpg"), forState: UIControlState.Normal)
    }
    
    private func resume() {
        trackManager.resume()
        playPauseButton.setBackgroundImage(UIImage(named: "pause.png"), forState: UIControlState.Normal)
    }
}
