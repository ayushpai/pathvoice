//
//  SpeechService.swift
//  pathvoice
//
//  Created by Ayush Pai on 6/21/25.
//

import Foundation
import AVFoundation

class SpeechService: NSObject, ObservableObject {
    private let apiKey = "" // Replace with your LMNT API key
    private let baseURL = "https://api.lmnt.com/v1/ai/speech/bytes"
    
    @Published var isSpeaking = false
    @Published var isAudioPlaying = false
    @Published var errorMessage: String?
    
    private var audioPlayer: AVAudioPlayer?
    private var cachedAudioData: Data?
    private var currentText: String = ""
    
    override init() {
        super.init()
    }
    
    func speakText(_ text: String, voice: String = "ava") {
        guard !text.isEmpty else { 
            print("🔇 SpeechService: Empty text provided, skipping")
            return 
        }
        
        print("🎤 SpeechService: Starting speakText with voice: \(voice)")
        print("📝 SpeechService: Text length: \(text.count) characters")
        
        // Check if we have cached audio for this exact text
        if text == currentText, let cachedData = cachedAudioData {
            print("💾 SpeechService: Using cached audio data (\(cachedData.count) bytes)")
            // Use cached audio
            playAudio(data: cachedData)
            return
        }
        
        print("🔄 SpeechService: No cache found, generating new audio")
        isSpeaking = true
        errorMessage = nil
        
        let requestBody: [String: Any] = [
            "voice": voice,
            "text": text,
            "model": "blizzard",
            "language": "auto",
            "format": "mp3",
            "sample_rate": 24000,
            "seed": 42,
            "top_p": 0.3,
            "temperature": 0.3
        ]
        
        print("📡 SpeechService: Request body: \(requestBody)")
        
        guard let url = URL(string: baseURL) else {
            print("❌ SpeechService: Invalid URL")
            errorMessage = "Invalid URL"
            isSpeaking = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        print("🌐 SpeechService: Making request to: \(url)")
        print("🔑 SpeechService: Using API key: \(String(apiKey.prefix(10)))...")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("📦 SpeechService: Request body encoded successfully")
        } catch {
            print("❌ SpeechService: Failed to encode request: \(error)")
            errorMessage = "Failed to encode request: \(error.localizedDescription)"
            isSpeaking = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                print("📥 SpeechService: Received response")
                
                if let error = error {
                    print("❌ SpeechService: Network error: \(error)")
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    self?.isSpeaking = false
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 SpeechService: HTTP Status: \(httpResponse.statusCode)")
                    print("📋 SpeechService: Response headers: \(httpResponse.allHeaderFields)")
                }
                
                guard let data = data else {
                    print("❌ SpeechService: No audio data received")
                    self?.errorMessage = "No audio data received"
                    self?.isSpeaking = false
                    return
                }
                
                print("✅ SpeechService: Received audio data (\(data.count) bytes)")
                
                // Cache the audio data and text
                self?.cachedAudioData = data
                self?.currentText = text
                print("💾 SpeechService: Audio data cached")
                
                // Play the audio
                self?.playAudio(data: data)
            }
        }.resume()
    }
    
    private func playAudio(data: Data) {
        print("🎵 SpeechService: Starting playAudio")
        
        do {
            // Configure audio session
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("🔊 SpeechService: Audio session configured")
            
            // Create audio player
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            print("🎧 SpeechService: Audio player created")
            
            let success = audioPlayer?.play() ?? false
            print("▶️ SpeechService: Audio play started: \(success)")
            
            isSpeaking = true
            isAudioPlaying = true
            print("🎯 SpeechService: State updated - isSpeaking: \(isSpeaking), isAudioPlaying: \(isAudioPlaying)")
        } catch {
            print("❌ SpeechService: Failed to play audio: \(error)")
            errorMessage = "Failed to play audio: \(error.localizedDescription)"
            isSpeaking = false
            isAudioPlaying = false
        }
    }
    
    func stopSpeaking() {
        print("⏹️ SpeechService: stopSpeaking called")
        audioPlayer?.stop()
        isSpeaking = false
        isAudioPlaying = false
        print("🎯 SpeechService: State updated - isSpeaking: \(isSpeaking), isAudioPlaying: \(isAudioPlaying)")
    }
    
    func pauseSpeaking() {
        print("⏸️ SpeechService: pauseSpeaking called")
        audioPlayer?.pause()
        isSpeaking = false
        print("🎯 SpeechService: State updated - isSpeaking: \(isSpeaking), isAudioPlaying: \(isAudioPlaying)")
        // Don't change isAudioPlaying - keep content visible
    }
    
    func resumeSpeaking() {
        print("▶️ SpeechService: resumeSpeaking called")
        audioPlayer?.play()
        isSpeaking = true
        isAudioPlaying = true
        print("🎯 SpeechService: State updated - isSpeaking: \(isSpeaking), isAudioPlaying: \(isAudioPlaying)")
    }
}

extension SpeechService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("🏁 SpeechService: Audio finished playing, success: \(flag)")
        DispatchQueue.main.async {
            self.isSpeaking = false
            print("🎯 SpeechService: State updated - isSpeaking: \(self.isSpeaking), isAudioPlaying: \(self.isAudioPlaying)")
            // Keep isAudioPlaying true so content stays visible until new attraction
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("❌ SpeechService: Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
        DispatchQueue.main.async {
            self.errorMessage = "Audio playback error: \(error?.localizedDescription ?? "Unknown error")"
            self.isSpeaking = false
            self.isAudioPlaying = false
            print("🎯 SpeechService: State updated - isSpeaking: \(self.isSpeaking), isAudioPlaying: \(self.isAudioPlaying)")
        }
    }
} 
