//
//  BadViewController.swift
//  BadSwitch
//
//  Created by user on 2021/04/15.
//

import Cocoa
import AVKit

class Pixel {
    internal init(sw: NSSwitch, state: Bool) {
        self.sw = sw
        sw.focusRingType = .none // performance
        self.state = state
    }
    
    var sw: NSSwitch
    lazy var swAnimator = sw.animator() // performance
    var state: Bool {
        didSet {
            if oldValue != state {
                swAnimator.state = state ? .on : .off
            }
        }
    }
}

class BadViewController: NSViewController {
    let data: BadAppleData
    let displayLink: CVDisplayLink = {
        var displayLink: CVDisplayLink!
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        return displayLink!
    }()
    var previousFrame: Int64 = -1
    var renderedFrames = 0
    var pixels = [Pixel]()

    lazy var player = AVPlayer(url: data.url.appendingPathComponent("music.mp4"))
    let playWindow = NSWindow(contentRect: .zero, styleMask: [], backing: .buffered, defer: false, screen: nil)
    
    init(data: BadAppleData) {
        self.data = data
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        var sws = [[NSSwitch]]()
        for y in 0..<data.height {
            var v = [NSSwitch]()
            for x in 0..<data.width {
                let sw = NSSwitch()
                sw.setAccessibilityElement(false)
                v.append(sw)
                pixels.append(.init(sw: sw, state: false))
            }
            sws.append(v)
        }
        view = NSGridView(views: sws)
    }
    
    override func viewDidLoad() {
        let playView = AVPlayerView()
        playView.player = player
        playWindow.contentView = playView
        
        CVDisplayLinkSetOutputHandler(displayLink) { (displayLink, ts, ts2, flags, flagsPointer) -> CVReturn in
//            if self.tasks.count > 0 {
//                DispatchQueue.main.sync {
//                    self.tasks.removeFirst()()
//                }
//            } else
            if self.player.status == .readyToPlay {
                let currentTime = self.player.currentTime()
                let data = self.data
                let frame = (Int64(currentTime.value) * Int64(data.fps)) / Int64(currentTime.timescale)
                if data.frames.count > frame, frame >= 0, self.previousFrame != frame {
                    self.previousFrame = frame
                    let name = data.frames[Int(frame)]
                    let image = Array(try! Data(contentsOf: data.url.appendingPathComponent("\(name)")).map { $0 < 128 }.enumerated())
                    if image.count == self.pixels.count {
                        DispatchQueue.main.sync {
                            self.renderedFrames += 1
                            let start = Date()
                            // これ意味あるのかな
                            NSAnimationContext.beginGrouping()
                            for (i, bit) in image {
//                                if i % data.width == 0 {
//                                    if Int(-start.timeIntervalSinceNow * 1000) > 30 {
//                                        break
//                                    }
//                                }
                                let pixel = self.pixels[i]
                                pixel.state = bit
                            }
                            NSAnimationContext.endGrouping()
                            self.view.window?.title = "\(name) (\(Int(-start.timeIntervalSinceNow * 1000))ms, rendered \(self.renderedFrames) frames)"
                        }
                    }
                }
            }
            return kCVReturnSuccess
        }
        CVDisplayLinkStart(displayLink)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.view.window!.center()
            let f = self.view.window!.frame
            self.playWindow.setContentSize(.init(width: 200, height: 150))
            self.playWindow.setFrameOrigin(.init(x: f.maxX + 24, y: f.minY))
            self.playWindow.makeKeyAndOrderFront(nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.player.play()
        }
    }
    
//    func loop() {
//        for sw in switches {
//                sw.state = sw.state == .on ? .off : .on
//            }
//        }
//    }
}
