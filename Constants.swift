//
//  Constants.swift
//  Song Finder
//
//  Created by Arjun Tambe on 7/11/16.
//  Copyright © 2016 Arjun Tambe. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

var loggedInSpotify = false
var loggedInAppleMusic = false
var loggedInSoundCloud = false

var scToken: String?
var scTokenExpiryTime: NSDate?

var sptSession: SPTSession?
var sptTokenTimer: NSTimer?

enum Platform {
    case spotify
    case appleMusic
    case soundCloud
    case local
}


let spotifyID = "INSERT"
let spotifySecret = "INSERT"
let spotifyRedirect = "INSERT ://callback"
let sptEncryptionKey = "INSERT"

let soundcloudID = "INSERT"
let soundcloudSecret = "INSERT"
let soundCloudRedirect = "INSERT ://callback"

var soundCloudPlayer: AVAudioPlayer?
let appleMusicPlayer = MPMusicPlayerController.systemMusicPlayer()
var spotifyPlayer: SPTAudioStreamingController?


