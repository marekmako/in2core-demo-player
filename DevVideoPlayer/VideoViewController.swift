//
//  VideoViewController.swift
//  DevVideoPlayer
//
//  Created by Marek Mako on 21/03/2017.
//  Copyright © 2017 Marek Mako. All rights reserved.
//

import UIKit
import AVFoundation

class VideoViewController: UIViewController {
    
    fileprivate let sampleVideoUrl = URL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")! // testing purpose
    
    fileprivate var videoPlayer: AVPlayer?
    
    fileprivate var playerItemKVOContext = 0
    
    fileprivate var videoSliderCurrentValueTimer: Timer?
    
    fileprivate var inOutVideoRangeCollection: InOutVideoRangeCollection?
    
    fileprivate var currPlayingSequence: (start: Float, end: Float)?
    
    // MARK: - outlets
    @IBOutlet weak var videoPreview: UIView!
    
    @IBOutlet weak var videoSlider: VideoSlider!
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var pauseButton: UIButton!
    
    // MARK: - actions
    @IBAction func onPlay() {
        if videoPlayer?.rate == 0 {
            videoPlayer?.play()
        }
    }
    
    @IBAction func onPause() {
        if videoPlayer?.rate != 0 {
            videoPlayer?.pause()
        }
    }

    @IBAction func onSliderTouchDown() {
        stopVideoSliderValueTimer()
    }
    
    @IBAction func videoSliderValueChanged(_ sender: VideoSlider) {
        playerSeek(to: sender.value)
        tryStartVideoSliderValueTimer()
    }
    
    @objc fileprivate func onSliderTap(recognizer: UIGestureRecognizer) {
        let point = recognizer.location(in: videoSlider)
        
        // active range
        let range = inOutVideoRangeCollection?.lookupForNearestRange(xCoord: point.x)
        inOutVideoRangeCollection?.setActive(range: range!)
        videoSlider.setNeedsDisplay()
        
        // move player to range start position
        currPlayingSequence = range?.getPlaySquence(duration: videoSlider.maximumValue)
        playerSeek(to: currPlayingSequence!.start)
        
        tryStartVideoSliderValueTimer()
    }
    
    // MARK: - DEMO ACTIONS
    
    @IBAction func fullTrackClick() {
        inOutVideoRangeCollection = InOutVideoRangeCollection(collection: [
            InOutVideoRange(in: 0, out: 1)])
        
        videoSlider.setInOutVideoRangeCollection(collection: inOutVideoRangeCollection!)
        
        // video setup
        let inOutVideoRange = inOutVideoRangeCollection?.first()
        inOutVideoRangeCollection!.setActive(range: inOutVideoRange!)
        currPlayingSequence = inOutVideoRange?.getPlaySquence(duration: videoSlider.maximumValue)
        playerSeek(to: currPlayingSequence!.start)
    }
    
    @IBAction func oneSequeceClick() {
        inOutVideoRangeCollection = InOutVideoRangeCollection(collection: [
            InOutVideoRange(in: 0.2, out: 0.8)])
        
        videoSlider.setInOutVideoRangeCollection(collection: inOutVideoRangeCollection!)
        
        // video setup
        let inOutVideoRange = inOutVideoRangeCollection?.first()
        inOutVideoRangeCollection!.setActive(range: inOutVideoRange!)
        currPlayingSequence = inOutVideoRange?.getPlaySquence(duration: videoSlider.maximumValue)
        playerSeek(to: currPlayingSequence!.start)
    }
    
    @IBAction func multipleSequenceClick() {
        inOutVideoRangeCollection = InOutVideoRangeCollection(collection: [
            InOutVideoRange(in: 0.2, out: 0.4), InOutVideoRange(in: 0.6, out: 0.8)])
        
        videoSlider.setInOutVideoRangeCollection(collection: inOutVideoRangeCollection!)
        
        // video setup
        let inOutVideoRange = inOutVideoRangeCollection?.first()
        inOutVideoRangeCollection!.setActive(range: inOutVideoRange!)
        currPlayingSequence = inOutVideoRange?.getPlaySquence(duration: videoSlider.maximumValue)
        playerSeek(to: currPlayingSequence!.start)
    }
    
}



// MARK: - Lifecycle
extension VideoViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK - test
        inOutVideoRangeCollection = InOutVideoRangeCollection(collection: [
            InOutVideoRange(in: 0, out: 1)])
        // END test
        
        initControllButtons()
        
        videoSlider.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onSliderTap)))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        prepareToPlay()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // clean up
        if videoSliderCurrentValueTimer != nil {
            videoSliderCurrentValueTimer!.invalidate()
            videoSliderCurrentValueTimer = nil
        }
    }
    
    // MARK: - UI Settings
    
    private func initControllButtons() {
        videoSlider.value = 0
        videoSlider.isContinuous = false
        videoSlider.isEnabled = false
        playButton.isEnabled = false
        pauseButton.isEnabled = false
    }
    
    fileprivate func activateControllButtons() {
        videoSlider.isEnabled = true
        playButton.isEnabled = true
        pauseButton.isEnabled = true
    }
}



// MARK: - Videoplayer & Slider
extension VideoViewController {
    
    fileprivate func prepareToPlay() {
        let asset = AVAsset(url: sampleVideoUrl)
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.addObserver(self,
                               forKeyPath: #keyPath(AVPlayer.status),
                               options: [.old, .new],
                               context: &playerItemKVOContext)
        videoPlayer = AVPlayer(playerItem: playerItem)
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // handle only player context
        guard context == &playerItemKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        // handle only status
        if keyPath == #keyPath(AVPlayer.status) {
            var status: AVPlayerItemStatus = .unknown
            
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            }
            
            switch status {
            case .readyToPlay:
                setupVideoPlayerAndSlider()
                activateControllButtons()
                break
                
            case .failed:
                // TODO: handle video load error, alert
                let alert = UIAlertController(title: "Unable to load video!", message: "Try later or check your internet connection", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alert, animated: true, completion: nil)
                break
                
            case .unknown:
                // hasn’t been loaded, not an error
                break
            }
        }
    }
    
    private func setupVideoPlayerAndSlider() {
        guard let player = videoPlayer else {
            // TODO: programmer error, log
            return
        }
    
        // set player layer frame
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoPreview.bounds
        videoPreview.layer.addSublayer(playerLayer)
        
        // slider setup
        videoSlider.maximumValue = Float(CMTimeGetSeconds(player.currentItem!.duration))
        tryStartVideoSliderValueTimer()
        videoSlider.setInOutVideoRangeCollection(collection: inOutVideoRangeCollection!)
        
        // video setup
        tryMoveToFirstTrack()
    }
    
    fileprivate func tryMoveToFirstTrack() {
        let inOutVideoRange = inOutVideoRangeCollection?.first()
        
        guard inOutVideoRange != nil else {
            return
        }
        
        inOutVideoRangeCollection?.setActive(range: inOutVideoRange!)
        currPlayingSequence = inOutVideoRange!.getPlaySquence(duration: videoSlider.maximumValue)
        playerSeek(to: currPlayingSequence!.start)
    }
    
    fileprivate func playerSeek(to: Float) {
        let seekToTime = CMTimeMakeWithSeconds(Float64(to), 1)
        videoPlayer?.seek(to: seekToTime)
    }
    
    fileprivate func tryStartVideoSliderValueTimer() {
        // timer running
        if (videoSliderCurrentValueTimer != nil && videoSliderCurrentValueTimer!.isValid) {
            return
            
        } else {
            videoSliderCurrentValueTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [unowned self] (_) in
                guard self.videoPlayer != nil else {
                    return
                }
                
                self.videoSlider.value = Float(CMTimeGetSeconds(self.videoPlayer!.currentTime()))
                
                guard self.currPlayingSequence != nil else {
                    return
                }
                
                if self.videoSlider.value >= self.currPlayingSequence!.end {
                    let seekToTime = CMTimeMakeWithSeconds(Float64(self.currPlayingSequence!.start), 1)
                    self.videoPlayer?.seek(to: seekToTime)
                }
            }
        }
    }
    
    fileprivate func stopVideoSliderValueTimer() {
        videoSliderCurrentValueTimer?.invalidate()
        videoSliderCurrentValueTimer = nil
    }
}
