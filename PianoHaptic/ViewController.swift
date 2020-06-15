//
//  ViewController.swift
//  PianoHaptic
//
//  Created by Muhammad Rajab Priharsanto on 17/05/20.
//  Copyright © 2020 Muhammad Rajab Priharsanto. All rights reserved.
//

import UIKit
import CoreHaptics

class ViewController: UIViewController
{
    @IBOutlet var pianoNotes: [UIButton]!
    let notes = ["F3","F#","G","G#","A","Bb","B","C","C#","D","Eb","E","F4","F#4","G4","G#4","A4","Bb4","B4"]
//    let notesReferences: [Float] = [1.0, 0.95, 0.9, 0.85, 0.825, 0.8, 0.75, 0.7, 0.65, 0.625, 0.6, 0.55, 0.5, 0.45, 0.425, 0.4, 0.35, 0.3, 0.25, 0.20]
    let notesReferences: [Float] = [1.0, 0.95, 0.9, 0.85, 0.825, 0.8, 0.75, 0.45, 0.42, 0.625, 0.32, 0.55, 0.22, 0.15, 0.425, 0.05, 0.35, -0.05, 0.25, -0.1]
    
    @IBOutlet weak var pianoView: UIView!
    
    var buttonReferences: String!
    @IBOutlet weak var chordLabel: UILabel!
    
    //============================
    //Property For Haptic Engine
    //============================
    // Haptic Engine & Player State:
    private var engine: CHHapticEngine!
    private var engineNeedsStart = true
    private var continuousPlayer: CHHapticAdvancedPatternPlayer!
    
    // Constants
    private let initialIntensity: Float = 1.0
    private let initialSharpness: Float = 0.5
    var dynamicIntensity: Float = 0.0
    var dynamicSharpness: Float = 0.0
    
    // Tokens to track whether app is in the foreground or the background:
    private var foregroundToken: NSObjectProtocol?
    private var backgroundToken: NSObjectProtocol?
    
    private lazy var supportsHaptics: Bool =
    {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return appDelegate.supportsHaptics
    }()
    //============================
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        prepareHaptics()
        // Do any additional setup after loading the view.
        
        for reference in pianoNotes
        {
            reference.addTarget(self, action: #selector(BtnPressed(_:)), for:.touchDown)
            reference.addTarget(self, action: #selector(BtnReleased(_:)), for:.touchUpInside)
            print("added")
        }
        
        let threeFingerTap = UITapGestureRecognizer(target: self, action: #selector(threeFingerTapDetected))
        threeFingerTap.numberOfTouchesRequired = 3
        pianoView.addGestureRecognizer(threeFingerTap)
    }

    //==================================
    //Function For Prepare Haptics
    //==================================
    func prepareHaptics()
    {
        if supportsHaptics
        {
            createAndStartHapticEngine()
            createContinuousHapticPlayer()
        }
        addObservers()
    }
    //==================================
    
    @objc func BtnPressed(_ sender: UIButton)
    {
        print("Pressed")
        buttonReferences = sender.currentTitle
        chordLabel.text = buttonReferences
        doingHaptics()
        if supportsHaptics
        {
            // Warm engine.
            do
            {
                // Begin playing continuous pattern.
                try self.continuousPlayer.start(atTime: CHHapticTimeImmediate)
                print("Haptic Continuous Player Started !")
            }
            catch let error
            {
                print("Error starting the continuous haptic player: \(error)")
            }
        }
    }
    
    @objc func BtnReleased(_ sender: UIButton)
    {
        print("Released")
        if supportsHaptics
        {
            // Stop playing the haptic pattern.
            do
            {
                try continuousPlayer.stop(atTime: CHHapticTimeImmediate)
                print("Haptic Continuous Player Stopped !")
                //leftButtonProperty.removeGestureRecognizer(tapGesture)
            }
            catch let error
            {
                print("Error stopping the continuous haptic player: \(error)")
            }
        }
    }
    
    @IBAction func buttonPressed(_ sender: UIButton)
    {

    }
    
    @objc func threeFingerTapDetected(sender: UITapGestureRecognizer)
    {
        print("Three")
    }
}

//=====================================================
//Extension For Preparing and Create Engine for Haptic
//=====================================================
extension ViewController
{
    /// - Tag: CreateAndStartEngine
           func createAndStartHapticEngine()
           {
               print("createAndStartHapticEngine Function Worked !")
               // Create and configure a haptic engine.
               do
               {
                   engine = try CHHapticEngine()
                   print("Haptic Engine Created !")
               }
               catch let error
               {
                   fatalError("Engine Creation Error: \(error)")
               }
               
               // Mute audio to reduce latency for collision haptics.
               //engine.playsHapticsOnly = true
               
               // The stopped handler alerts you of engine stoppage.
               engine.stoppedHandler =
                { reason in
                   print("Stop Handler: The engine stopped for reason: \(reason.rawValue)")
                   switch reason
                   {
                    case .audioSessionInterrupt: print("Audio session interrupt")
                    case .applicationSuspended: print("Application suspended")
                    case .idleTimeout: print("Idle timeout")
                    case .systemError: print("System error")
                    case .notifyWhenFinished: print("Playback finished")
                    @unknown default:
                       print("Unknown error")
                   }
               }
               
               // The reset handler provides an opportunity to restart the engine.
               engine.resetHandler =
                {
                   print("Reset Handler: Restarting the engine.")
                   
                   do
                   {
                       // Try restarting the engine.
                       try self.engine.start()
                       
                       // Indicate that the next time the app requires a haptic, the app doesn't need to call engine.start().
                       self.engineNeedsStart = false
                       print("Haptic Engine Restarted !")
                   }
                   catch
                   {
                       print("Failed to start the engine")
                   }
               }
               
               // Start the haptic engine for the first time.
               do
               {
                   try self.engine.start()
                   print("Haptic Engine Started for the first time !")
               }
               catch
               {
                   print("Failed to start the engine: \(error)")
               }
           }
           
           /// - Tag: CreateContinuousPattern
           func createContinuousHapticPlayer()
           {
               print("createContinuousHapticPlayer Function Worked !")
            
               // Create an intensity parameter:
               let intensity = CHHapticEventParameter(parameterID: .hapticIntensity,
                                                      value: initialIntensity)
               
               // Create a sharpness parameter:
               let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness,
                                                      value: initialSharpness)
               
               // Create a continuous event with a long duration from the parameters.
               let continuousEvent = CHHapticEvent(eventType: .hapticContinuous,
                                                   parameters: [intensity, sharpness],
                                                   relativeTime: 0,
                                                   duration: 100)
               
               print("Haptic Event Created !")
            
               do
               {
                   // Create a pattern from the continuous haptic event.
                   let pattern = try CHHapticPattern(events: [continuousEvent], parameters: [])
                   
                   // Create a player from the continuous haptic pattern.
                   continuousPlayer = try engine.makeAdvancedPlayer(with: pattern)
                
                print("Haptic Pattern Created !")
                   
               }
               catch let error
               {
                   print("Pattern Player Creation Error: \(error)")
               }

           }
        
        private func addObservers()
        {
            print("addObservers Function Worked !")
            backgroundToken = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                                                     object: nil,
                                                                     queue: nil)
            { _ in
                guard self.supportsHaptics
                else
                {
                    return
                }
                // Stop the haptic engine.
                self.engine.stop(completionHandler:
                { error in
                    if let error = error
                    {
                        print("Haptic Engine Shutdown Error: \(error)")
                        return
                    }
                    self.engineNeedsStart = true
                })
            }
            foregroundToken = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification,
                                                                     object: nil,
                                                                     queue: nil)
            { _ in
                guard self.supportsHaptics
                else
                {
                    return
                }
                // Restart the haptic engine.
                self.engine.start(completionHandler:
                    { error in
                    if let error = error
                    {
                        print("Haptic Engine Startup Error: \(error)")
                        return
                    }
                    self.engineNeedsStart = false
                })
            }
        }
}

//=====================================================
//Extension For Doing Haptic Work
//=====================================================
extension ViewController
{
    func doingHaptics()
    {
        print("Button References =", buttonReferences)
        var a = 0, b = 19
        print("notes =", notes.count)
        for reference in notes
        {
            if reference == buttonReferences
            {
                dynamicIntensity = notesReferences[a]
                dynamicSharpness = notesReferences[b]
                print("notes =", reference)
                print("Counter =", a)
                print("Intensity =", dynamicIntensity)
                print("Sharpness =", dynamicSharpness)
                break
            }
            dynamicIntensity = notesReferences[a]
            a+=1
            dynamicSharpness = notesReferences[b]
            b-=1
        }
        createDynamicHaptic()
    }
    
    func createDynamicHaptic()
    {
        //=====================
        //Prepare for Haptic
        //=====================
        if supportsHaptics
        {
            // Create dynamic parameters for the updated intensity & sharpness.
            let intensityParameter = CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                                                      value: dynamicIntensity,
                                                                      relativeTime: 0)

            let sharpnessParameter = CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                                                      value: dynamicSharpness,
                                                                      relativeTime: 0)
            print("Haptic Parameter Changed !")
                    
            print(dynamicIntensity)
            print(dynamicSharpness)
            
            // Send dynamic parameters to the haptic player.
            do
            {
                try continuousPlayer.sendParameters([intensityParameter, sharpnessParameter],
                                                                atTime: 0)
                print("Haptic Parameter Send !")
            }
            catch let error
            {
                print("Dynamic Parameter Error: \(error)")
            }
        }
    }
}
