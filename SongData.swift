//
//  SongData.swift
//  Song Finder
//
//  Created by Arjun Tambe on 7/19/16.
//  Copyright © 2016 Arjun Tambe. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class SongData {
    
    private var name: String!
    private var artistName = [String]()
    private var platform: Platform!
    private var trackID: String!
    private var albumName: String!
    private var mediaItem: MPMediaItem?
    private var duration: Double? //in seconds
    private var nowPlayingInfo: Dictionary<String, AnyObject>?
    
    init(song: AnyObject, songPlatform: Platform) {
        if (songPlatform == Platform.spotify) {
            self.parseSpotify(song as! SPTPartialTrack)
        } else if (songPlatform == Platform.appleMusic) {
            parseAppleMusic(song as! NSDictionary)
        } else if (songPlatform == Platform.soundCloud) {
            parseSoundCloud(song as! NSDictionary)
        } else if (songPlatform == Platform.local) {
            parseLocal(song as! MPMediaItem)
        }
        
    }
    
    func parseLocal(song: MPMediaItem) {
        self.name = song.title
        if(song.albumArtist != nil) {
            self.artistName.append(song.albumArtist!)
        } else {
            self.artistName.append("Unknown Artist")
        }
        if(song.albumTitle != nil) {
            self.albumName = song.albumTitle
        } else {
            self.albumName = "Unknown Album"
        }
        self.trackID = nil
        self.platform = Platform.local
        self.mediaItem = song
        self.duration = song.playbackDuration
    }
    
    func parseSpotify(song: SPTPartialTrack) {
        self.platform = Platform.spotify
        self.name = song.name
        for i in 0..<song.artists.count {
            artistName.append(song.artists[i].name)
        }
        
        self.albumName = song.album.name
        self.trackID = song.playableUri.absoluteString
        self.duration = song.duration
        
        nowPlayingInfo = [MPMediaItemPropertyArtist : artistName[0],  MPMediaItemPropertyTitle : name, MPMediaItemPropertyAlbumTitle : albumName, MPMediaItemPropertyPlaybackDuration : duration!, MPNowPlayingInfoPropertyPlaybackRate : 1, MPNowPlayingInfoPropertyElapsedPlaybackTime : 0]
    }
    
    
    func parseAppleMusic(song: NSDictionary) {
        platform = Platform.appleMusic
        name = song["trackName"] as? String
        artistName.append((song["artistName"] as? String)!)
        albumName = song["collectionName"] as? String
        let trackIDAsInt = song["trackId"] as! Int
        trackID = String(trackIDAsInt)
        duration = (song["trackTimeMillis"] as! Double) / 1000
        
        nowPlayingInfo = [MPMediaItemPropertyArtist : artistName[0],  MPMediaItemPropertyTitle : name, MPMediaItemPropertyAlbumTitle : albumName, MPMediaItemPropertyPlaybackDuration : duration!, MPNowPlayingInfoPropertyPlaybackRate : 1, MPNowPlayingInfoPropertyElapsedPlaybackTime : 0]

    }
    
    func parseSoundCloud(song: NSDictionary) {
        print (song)
        platform = Platform.soundCloud
        name = song["title"] as? String
        artistName.append((song["user"] as! NSDictionary)["username"] as! String)
        albumName = nil
        trackID = song["stream_url"] as? String
        duration = (song["duration"] as? Double)! / 1000
        
        nowPlayingInfo = [MPMediaItemPropertyArtist : artistName[0],  MPMediaItemPropertyTitle : name, MPMediaItemPropertyPlaybackDuration : duration!, MPNowPlayingInfoPropertyPlaybackRate : 1, MPNowPlayingInfoPropertyElapsedPlaybackTime : 0]

    }
    
    
    func getName() -> String {
        return name!
    }
    
    func getArtistName() -> String {
        var returnString = artistName[0]
        if (artistName.count > 1) {
             returnString += "ft. "
        }
        for i in 1..<artistName.count {
            returnString += artistName[i]
            if (i < artistName.count - 1) {
                returnString += ", "
            }
        }
        return returnString
    }

    func getAlbumName() -> String {
        return albumName!
    }
    
    func getTrackID() -> String {
        return trackID!
    }
    
    func getPlatform() -> Platform {
        return platform
    }
    
    
    func play() {
        if (platform == Platform.spotify) {
            playSpotify()
        } else if (platform == Platform.appleMusic) {
            playAppleMusic()
        } else if (platform == Platform.soundCloud) {
            playSoundCloud()
        } else if (platform == Platform.local){
            playLocal()
        }
    }
    
    func playLocal() {
        let collection = MPMediaItemCollection(items: [mediaItem!])
        appleMusicPlayer.setQueueWithItemCollection(collection)
        appleMusicPlayer.play()
    }

    func playSpotify() {

        spotifyPlayer!.playURIs([NSURL(string: trackID)!], fromIndex: 0, callback: { (errorTwo) in
            if (errorTwo != nil) {
                print ("playback error: \(errorTwo)")
                return;
            }
        })
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nowPlayingInfo
        
        //        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPNowPlayingInfoPropertyElapsedPlaybackTime : (spotifyPlayer?.currentPlaybackPosition)!]

        

    }
    
    
    
    
    func playAppleMusic() {
        appleMusicPlayer.setQueueWithStoreIDs([trackID])
        appleMusicPlayer.play()
    }
    
    func playSoundCloud() {
        
        let completeURL = trackID + "?oauth_token=" + scToken!
        let url = NSURL(string: completeURL)
        
        do {
            let data = try NSData(contentsOfURL: url!, options: NSDataReadingOptions(rawValue: 0))
            soundCloudPlayer = try AVAudioPlayer(data: data, fileTypeHint: AVFileTypeMPEGLayer3)
            
        } catch {
            print (error)
        }
        
        do {
            UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            
            try AVAudioSession.sharedInstance().setActive(true)
            
            
            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nowPlayingInfo
            //[MPMediaItemPropertyArtist : artistName[0],  MPMediaItemPropertyTitle : name, MPMediaItemPropertyPlaybackDuration : duration!]

        }
        catch {
            print(error)
        }
        
        soundCloudPlayer!.prepareToPlay()
        soundCloudPlayer!.play()

    }
    
    func resume() {
        if (platform == Platform.spotify) {
            spotifyPlayer?.setIsPlaying(true, callback: { (error) in
                if (error != nil) {
                    print(error)
                }
            })
        } else if (platform == Platform.appleMusic || platform == Platform.local) {
            appleMusicPlayer.play()
        } else if (platform == Platform.soundCloud) {
            soundCloudPlayer?.play()
        }
        nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 1
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nowPlayingInfo
    }
    
    
    func pause() {
        if (platform == Platform.spotify) {
            spotifyPlayer?.setIsPlaying(false, callback: { (error) in
                if (error != nil) {
                    print(error)
                }
            })
            nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = spotifyPlayer?.currentPlaybackPosition
        } else if (platform == Platform.appleMusic || platform == Platform.local) {
            appleMusicPlayer.pause()
        } else if (platform == Platform.soundCloud) {
            nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = soundCloudPlayer?.currentTime
            soundCloudPlayer?.pause()
            
        }
        nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 0
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = nowPlayingInfo
        
    }
    
    
}