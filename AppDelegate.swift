//
//  AppDelegate.swift
//  Song Finder
//
//  Created by Arjun Tambe on 7/11/16.
//  Copyright © 2016 Arjun Tambe. All rights reserved.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
                
        let urlAsString = url.absoluteString
        
        if (urlAsString.containsString("spotify")) {
            print(urlAsString)
            authenticateSpotify(url)
        } else if (urlAsString.containsString("soundcloud")) {
            authenticateSoundCloud(url)
        } else {
            print ("error")
        }
        return true
    }

    func authenticateSpotify(url: NSURL) {
        let auth = SPTAuth.defaultInstance()
        
        if auth.canHandleURL(url) {
            auth.handleAuthCallbackWithTriggeredAuthURL(url, callback: { (error, session) in
                if (error != nil) {
                    print ("error: \(error)")
                } else {
                    loggedInSpotify = true
                    auth.session = session
                    let data = NSKeyedArchiver.archivedDataWithRootObject(session)
                    NSUserDefaults.standardUserDefaults().setObject(data, forKey: "DEFAULT_SESSION")
                    sptTokenTimer = NSTimer.scheduledTimerWithTimeInterval(session.expirationDate.timeIntervalSinceNow, target: self, selector: #selector(LoginViewController.renewSpotifySession), userInfo: nil, repeats: false)


                }
            })
        } else {
            print ("error authenticating")
        }
    }
    
    

    
    func authenticateSoundCloud(url: NSURL) {
        let array = url.absoluteString.componentsSeparatedByString("code=")
        var code: String = array[1]
            
        let length = code.endIndex.predecessor()
            
        code = code.substringToIndex(length)
        
        NSUserDefaults.standardUserDefaults().setObject(code, forKey: "SC_CODE")
        
        let loginVC = LoginViewController()
        
        loginVC.doOauthWithCode(code)
    }
    
    
    

}

