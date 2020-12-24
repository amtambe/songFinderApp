//
//  TrackManager.swift
//  Song Finder
//
//  Created by Arjun Tambe on 7/27/16.
//  Copyright © 2016 Arjun Tambe. All rights reserved.
//

import Foundation

class TrackManager {
    private var currentSongPlaying: SongData?
    private var isPlaying: Bool = false
    
    var queue: [SongData] = []
    
    
    func resume() {
        if (currentSongPlaying != nil) {
            currentSongPlaying!.resume()
            isPlaying = true
        }
    }
    
    func pause() {
        currentSongPlaying!.pause()
        isPlaying = false

    }
    
    func beginPlaying(song: SongData) {
        currentSongPlaying = song
        song.play()
        isPlaying = true
    }
    
    
    func playing() -> Bool {
        return isPlaying
    }
    
}