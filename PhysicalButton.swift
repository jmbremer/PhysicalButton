//
//  PhysicalButton.swift
//  Wrapper around https://github.com/jpsim/JPSVolumeButtonHandler to support physcial volume
//  button taps in a rather restricted area, as volume buttons should be blocked from their
//  normal function as little as possible.
//
//  Notice some issues with the underlying implementation as I observed here: https://github.com/jpsim/JPSVolumeButtonHandler/issues/37
//
//  Mor info on the underlying tech:
//  https://developer.apple.com/library/ios/documentation/MediaPlayer/Reference/MPMusicPlayerController_ClassReference/#//apple_ref/c/data/MPMusicPlayerControllerVolumeDidChangeNotification
//  https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVAudioSession_ClassReference/#//apple_ref/occ/instm/AVAudioSession/setActive:error:
//  (http://stackoverflow.com/questions/28193626/cleanest-way-of-capturing-volume-up-down-button-press-on-ios-8)
//  http://stackoverflow.com/questions/772832/program-access-to-iphone-volume-buttons
//
//  Created by J. Marco Bremer (marco@bluemedialabs.com) in 2016.
//
//  To the extent possible under law, the author(s) have dedicated all copyright and related
//  and neighboring rights to this software to the public domain worldwide. This software is
//  distributed without any warranty.
//  You should have received a copy of the CC0 Public Domain Dedication along with this
//  software. If not, see <http://creativecommons.org/publicdomain/zero/1.0/>
//
import Foundation


/// A wrapper around JPSVolumeButtonHandler that lets us easily enable, disable and reactivate physical volume buttons at the volume level the user currently set outside the stopwatch. It's a singleton that needs to be initialized from the watch view once when this view is loaded. That's because the physical button needs to hook into timing by providing an alternative way to call the button-pressed callback.
/// NEW: Apparently the author added start/stop functionality himself in late 2016. So, there's no need anymore to re-create the entire object with every enable/disable. For a very defensive use of the volume button handling, I am also only creating the handler on first actual use. So, if the handler should break anything internally in some future iOS update, at least users that have never relied on this are unaffected.
/// See also: https://github.com/jpsim/JPSVolumeButtonHandler
class PhysicalButton: CustomDebugStringConvertible {
    
    static let shared = PhysicalButton()
    
    
    var action: (() -> Void) = {} {
        didSet {
            // Is the handler already there, that is, is this module already in use?..
            if let handler = volumeButtonHandler {
                // ..If so, then add the action to the handler right away.
                handler.upBlock = action
                handler.downBlock = action
            }
            // Otherwise, just save the action here and see it added when the handler is created when the module goes into use (isInUse = true).
        }
    }
    // Determines whether physical button support is available at all (vs. volume button listening being on right now).
    var isInUse = false {
        didSet(wasInUse) {
            if isInUse && volumeButtonHandler == nil {
                setUp()
                if let handler = volumeButtonHandler {
                    if isOn {
                        handler.start(true)
                    }
                } else {
                    // This is supported by Swift:
                    isInUse = false
                    volumeButtonHandler = nil 
                }
            }
        }
    }
    var isOn = false {
        didSet(wasOn) {
            if isInUse {
                guard let handler = volumeButtonHandler else {
                    assert(false, "When physical button support is in use, the handler must exist")
                    log.error("Physical button support in use, but handler not set up")
                    // This should never happen, but is needed to make the compiler happy:
                    isInUse = false
                    return
                }
                if isOn {
                    handler.start(true)
                } else {
                    handler.stop()
                }
            } // Otherwise, just save isOn.
        }
    }
    var isSetUp: Bool { return (volumeButtonHandler != nil) }
    
    private var volumeButtonHandler: JPSVolumeButtonHandler?
    // For whatever reason, there sometimes seem to be multiple taps recognized with only one physical button press. This is to prevent such within a very short amount of time. It doesn't work (fully) though.
    // (The cause, however, seems to be that a previous handler wasn't properly removed. Still...)
    static private let MinimumTapInterval = 0.3
    private var previousButtonTap = Date()
    
    var debugDescription: String {
        return "PhysicalButton(isInUse: \(isInUse), isOn: \(isOn))"
    }
    
    
    /*+********************************************************************
     * INSTANCE
     **********************************************************************/
    
    private init() {
        // Add observers to recognize when the app goes to background or comes back.
        NotificationCenter.default.addObserver(self, selector: #selector(PhysicalButton.appEnteredBackground), name:NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PhysicalButton.appEnteringForeground), name:NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc   // This is to get rid of a complaint on the #selector
    fileprivate func appEnteredBackground() {
        log.debug("Physical button support going into background mode...")
        tearDown()
    }
    @objc
    fileprivate func appEnteringForeground() {
        log.debug("Physical button support going into foreground mode...")
        assert(volumeButtonHandler == nil)
        if isInUse {
            setUp()
            if isOn {
                if let handler = volumeButtonHandler {
                    handler.start(true)
                } else {
                    log.warning("Setup of volume button handler failed somehow!?! Switching off volume button handling...")
                    isOn = false
                    isInUse = false
                }
            }
        }
    }
    
    private func setUp() {
        log.debug("Actually setting up physical button support as all requirements met...")
        volumeButtonHandler = JPSVolumeButtonHandler(up: {
            let rightNow = Date()
            let elapsedTime = rightNow.timeIntervalSince(self.previousButtonTap)
            if elapsedTime >= PhysicalButton.MinimumTapInterval {
                log.debug("Volume up button pressed...")
                self.action()
                self.previousButtonTap = rightNow
            } else {
                log.debug("Ignoring apparent rapid repeat up button press within \(elapsedTime)s...")
            }
        }, downBlock: {
            let rightNow = Date()
            let elapsedTime = rightNow.timeIntervalSince(self.previousButtonTap)
            if elapsedTime >= PhysicalButton.MinimumTapInterval {
                log.debug("Volume down button pressed...")
                self.action()
                self.previousButtonTap = rightNow
            } else {
                log.debug("Ignoring apparent rapid repeat down button press within \(elapsedTime)s...")
            }
        })
    }
    
    func tearDown() {
        if let handler = volumeButtonHandler {
            log.debug("Actually tearing down physical button support as at least one requirement isn't met anymore...")
            handler.stop()
            volumeButtonHandler = nil
        }
    }
    
}
