//
//  LoginViewController.swift
//  Song Finder
//
//  Created by Arjun Tambe on 7/11/16.
//  Copyright © 2016 Arjun Tambe. All rights reserved.
//

import UIKit
import MediaPlayer
import StoreKit
import Foundation


class LoginViewController: UIViewController {
    
    
    
    
    @IBAction func nextPressed() {
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func loginSpotify(sender: AnyObject!) {
        
        let data = try NSUserDefaults.standardUserDefaults().dataForKey("DEFAULT_SESSION")
        if (data != nil) {
            sptSession = try NSKeyedUnarchiver.unarchiveObjectWithData(data!) as! SPTSession
        }
        
        

        let sptTokenTimeLeft = try sptSession?.expirationDate.timeIntervalSinceNow
        
        let auth = SPTAuth.defaultInstance()
        auth.clientID = spotifyID
        auth.redirectURL = NSURL(string: spotifyRedirect)
        auth.requestedScopes = [SPTAuthStreamingScope]
        auth.tokenSwapURL = NSURL(string: "https://peaceful-crag-10208.herokuapp.com/swap")
        auth.tokenRefreshURL = NSURL(string: "https://peaceful-crag-10208.herokuapp.com/refresh")

        if (sptSession == nil) {
        
            let spotifyLoginURL = auth.loginURL
            //NSURL(string: "spotify-action://authorize?client_id=856932c036fa44c295d806c4c827704c&scope=streaming&redirect_uri=song-finder-app-spotify%3A%2F%2Fcallback&nosignup=true&nolinks=true&response_type=token")
            print(spotifyLoginURL)
        
            let application = UIApplication.sharedApplication()
        
            if (application.canOpenURL(spotifyLoginURL!)) {
                application.openURL(spotifyLoginURL!)
            } else {
                //error handling needed
            }
        } else if (sptTokenTimeLeft <= 0) {
            renewSpotifySession()
        } else {
            loggedInSpotify = true
            auth.session = sptSession
        }
    }
    
    func renewSpotifySession() {
        let auth = SPTAuth.defaultInstance()

        auth.renewSession(sptSession) { (error, session) in
            if (error != nil || session == nil) {
                print ("error: \(error)")
                loggedInSpotify = false
            } else {
                loggedInSpotify = true
                auth.session = session
                let data = NSKeyedArchiver.archivedDataWithRootObject(session)
                NSUserDefaults.standardUserDefaults().setObject(data, forKey: "DEFAULT_SESSION")
                sptTokenTimer = NSTimer.scheduledTimerWithTimeInterval(session.expirationDate.timeIntervalSinceNow, target: self, selector: #selector(LoginViewController.renewSpotifySession), userInfo: nil, repeats: false)

            }
        }
    }
    
    @IBAction func loginAppleMusic(sender: AnyObject!) {
        if (SKCloudServiceController.authorizationStatus() != SKCloudServiceAuthorizationStatus.Authorized) {
            SKCloudServiceController.requestAuthorization() {
                (status: SKCloudServiceAuthorizationStatus) -> Void in
                print(status)
            }
        }
        
        let cloudController = SKCloudServiceController()
        cloudController.requestCapabilitiesWithCompletionHandler { (capability, error) in
            if error != nil {
                print (error)
                return
            }
            if (capability.contains(SKCloudServiceCapability.MusicCatalogPlayback) && capability.contains(SKCloudServiceCapability.AddToCloudMusicLibrary)) {
                loggedInAppleMusic = true
            }
            if (capability.isEmpty) {
                print ("Apple Music is not authorized for this device")
            }
            else {
                if (!capability.contains(SKCloudServiceCapability.MusicCatalogPlayback)) {
                    print ("Cannot play back music from Apple Music.")
                }
                if (!capability.contains(SKCloudServiceCapability.AddToCloudMusicLibrary)) {
                    print ("Cannot add music to your music library")
                }
            }
        }
    }
    

    @IBAction func loginSoundCloud(sender: AnyObject!) {
        scToken = NSUserDefaults.standardUserDefaults().objectForKey("SC_TOKEN") as? String
//        scTokenExpiryTime = NSUserDefaults.standardUserDefaults().objectForKey("SC_TOKEN_EXPIRY_TIME") as? NSDate
        // || scTokenExpiryTime?.timeIntervalSinceNow < 0
        if (scToken == nil || scToken!.isEmpty) {
            let loginURL = NSURL(string: "https://soundcloud.com/connect?scope=non-expiring&client_id=" + soundcloudID + "&redirect_uri=" + soundCloudRedirect + "&response_type=code")
            
            let application = UIApplication.sharedApplication()
            
            if (application.canOpenURL(loginURL!)) {
                application.openURL(loginURL!)
            }
        } else {
            loggedInSoundCloud = true
        }
        
    }
    
    func doOauthWithCode(scCode: String) {
        let url = NSURL(string: "https://api.soundcloud.com/oauth2/token/")
        let postString = "client_id=" + soundcloudID + "&client_secret=" + soundcloudSecret + "&grant_type=authorization_code&redirect_uri=" + soundCloudRedirect + "&code=" + scCode
        let postData = postString.dataUsingEncoding(NSUTF8StringEncoding)

        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        request.setValue(NSString(format: "%d", (postData?.length)!) as String, forHTTPHeaderField:"Content-Length")
        request.setValue("multipart/form-data", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = postData
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            data, response, error in
            
            if error != nil {
                print (error)
                return
            }
            
            let responseBody = NSString(data: data!, encoding: NSUTF8StringEncoding)
            print("response body: \(responseBody)")
            
            do {
                let resultJSON = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                scToken = resultJSON.objectForKey("access_token") as? String
                
                //commented out because scope changed to non expiring
//                let timeRemaining = try resultJSON.objectForKey("expires_in") as! NSTimeInterval
//                scTokenExpiryTime = NSDate(timeIntervalSinceReferenceDate: NSDate().timeIntervalSinceReferenceDate + timeRemaining)
                loggedInSoundCloud = true
                
                NSUserDefaults.standardUserDefaults().setObject(scToken, forKey: "SC_TOKEN")
//                NSUserDefaults.standardUserDefaults().setObject(scTokenExpiryTime, forKey: "SC_TOKEN_EXPIRY_TIME")
                
            } catch {
                print ("error")
            }
        }
        task.resume()
    }
}