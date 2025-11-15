//
//  PermissionsManager.swift
//  VoiceNotesApp
//
//  Manages app permissions for microphone, location, and speech recognition
//

import AVFoundation
import CoreLocation
import Speech

/// Handles requesting and checking permissions for various app features
class PermissionsManager: NSObject, ObservableObject {
    static let shared = PermissionsManager()
    
    @Published var microphonePermissionGranted = false
    @Published var speechRecognitionPermissionGranted = false
    @Published var locationPermissionGranted = false
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        checkAllPermissions()
    }
    
    /// Checks all permissions status
    func checkAllPermissions() {
        checkMicrophonePermission()
        checkSpeechRecognitionPermission()
        checkLocationPermission()
    }
    
    // MARK: - Microphone Permission
    
    func checkMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphonePermissionGranted = true
        case .denied, .undetermined:
            microphonePermissionGranted = false
        @unknown default:
            microphonePermissionGranted = false
        }
    }
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    self.microphonePermissionGranted = granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    // MARK: - Speech Recognition Permission
    
    func checkSpeechRecognitionPermission() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechRecognitionPermissionGranted = true
        case .denied, .restricted, .notDetermined:
            speechRecognitionPermissionGranted = false
        @unknown default:
            speechRecognitionPermissionGranted = false
        }
    }
    
    func requestSpeechRecognitionPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.speechRecognitionPermissionGranted = (status == .authorized)
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    // MARK: - Location Permission
    
    func checkLocationPermission() {
        let status = locationManager.authorizationStatus
        locationPermissionGranted = (status == .authorizedWhenInUse || status == .authorizedAlways)
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
}

// MARK: - CLLocationManagerDelegate

extension PermissionsManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationPermission()
    }
}

