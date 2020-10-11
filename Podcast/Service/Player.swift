//
//  Player.swift
//  Podcast
//
//  Created by Adrian Evensen on 24/05/2020.
//  Copyright © 2020 AdrianF. All rights reserved.
//

import Foundation
import AVKit
import MediaPlayer
import AVFoundation

class Player {
    static let shared = Player()
    
    fileprivate let player = AVPlayer()
    
    init() {
        let interval = CMTimeMake(2, 1)
        player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [unowned self] (time) in
            guard let duration = self.player.currentItem?.duration else { return }
            guard let _ = MPNowPlayingInfoCenter.default().nowPlayingInfo else { return }
            
            let elapsedSeconds = CMTimeGetSeconds(time)
            let durationSeconds = CMTimeGetSeconds(duration)
            
            if elapsedSeconds.isNaN || durationSeconds.isNaN {
                return
            }
            
            print("Elapsed time: \(elapsedSeconds)s, duration: \(durationSeconds)s")
            
            //MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyPlaybackDuration] = durationSeconds
            //MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedSeconds

        }
    }
    
    func play(ep: EpisodeDataSource) {
        guard let episodeURL = ep.episodeUrl, let url = URL(string: episodeURL) else { return }

        setupAudioSession()

        let newItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: newItem)
        player.play()
        
        var nowPlayingInfo = [String:Any]()
        
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0

        nowPlayingInfo[MPMediaItemPropertyTitle] = ep.name
        nowPlayingInfo[MPMediaItemPropertyArtist] = ep.artist ?? "What?"
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        setupRemote()
    }
    
    func pause() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0
        self.player.pause()
    }
    
    func resume() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 1
        player.play()
    }
    
    func playPause() {
        if player.timeControlStatus == .paused {
            resume()
        } else {
            pause()
        }
    }
    
    
}

fileprivate func setupAudioSession() {
    do {
        try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try AVAudioSession.sharedInstance().setActive(true)
    } catch let error {
        print("failed to set AVSession active: ", error)
    }
}

fileprivate func setupMediaPlayerNowPlayingInfo(for episode: Episode) {
    var nowPlayingInfo = [String:Any]()
    
    nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = episode.timeElapsed
    nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1
    nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = episode.timeLength
    
    nowPlayingInfo[MPMediaItemPropertyTitle] = episode.name
    nowPlayingInfo[MPMediaItemPropertyArtist] = episode.podcast?.name

    guard let podcastArtworkData = episode.podcast?.artwork else { return }
    guard let podcastArtwork = UIImage(data: podcastArtworkData) else { return }
    
    let mediaPlayerArtwork = MPMediaItemArtwork(boundsSize: podcastArtwork.size) { (_) -> UIImage in
        return podcastArtwork
    }
    nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaPlayerArtwork
    
    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
}

fileprivate func setupRemote() {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            Player.shared.resume()
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            Player.shared.pause()
            return .success
        }
        
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [30]
        commandCenter.skipForwardCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            
            return .success
        }
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [10]
        commandCenter.skipBackwardCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            Player.shared.playPause()
            return .success
        }
    
        
}
