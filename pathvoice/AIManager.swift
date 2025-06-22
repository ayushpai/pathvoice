//
//  AIManager.swift
//  pathvoice
//
//  Created by Ayush Pai on 6/21/25.
//

import Foundation

struct GeminiRequest: Codable {
    let contents: [GeminiContent]
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

class AIManager: ObservableObject {
    private let apiKey = "" // Replace with your actual Gemini API key
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"
    
    @Published var currentTourGuideText: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var timer: Timer?
    private var currentAttractionId: String?
    private var speechService: SpeechService?
    
    init() {
        startPeriodicUpdates()
    }
    
    deinit {
        stopPeriodicUpdates()
    }
    
    func setSpeechService(_ speechService: SpeechService) {
        self.speechService = speechService
    }
    
    func startPeriodicUpdates() {
        // Update every 1 minute (60 seconds)
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.generateTourGuideContent()
        }
    }
    
    func stopPeriodicUpdates() {
        timer?.invalidate()
        timer = nil
    }
    
    func generateTourGuideContent() {
        // This will be called by the timer every minute
        // We'll need to get the current top attraction from the main app
        // For now, this will be called from ContentView when places are updated
    }
    
    func generateTourGuideForAttraction(_ attraction: Place) {
        // Check if this is the same attraction as before
        let attractionId = "\(attraction.displayName.text)_\(attraction.formattedAddress)"
        if attractionId == currentAttractionId {
            // Same attraction, don't regenerate
            return
        }
        
        // Update current attraction ID
        currentAttractionId = attractionId
        
        isLoading = true
        errorMessage = nil
        
        let systemPrompt = """
        You are an enthusiastic and knowledgeable tour guide providing real-time commentary to someone driving through the area. 
        
        Your role is to:
        - Provide interesting, engaging commentary about the location
        - Give historical context and fun facts
        - Make the driver feel like they have a personal tour guide
        - Keep your response around 100 words
        - Be conversational and engaging
        - Mention what's to the left and right if relevant
        - Focus on the specific attraction they're near
        
        Current location information:
        - Name: \(attraction.displayName.text)
        - Address: \(attraction.formattedAddress)
        - Type: \(attraction.primaryType ?? "Tourist Attraction")
        - Categories: \(attraction.types.joined(separator: ", "))
        
        Provide an engaging tour guide commentary as if you're speaking to someone driving by this location right now.
        """
        
        let requestBody = GeminiRequest(
            contents: [
                GeminiContent(
                    parts: [
                        GeminiPart(text: systemPrompt)
                    ]
                )
            ]
        )
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            errorMessage = "Failed to encode request: \(error.localizedDescription)"
            isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = "Network error: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data else {
                    self?.errorMessage = "No data received"
                    return
                }
                
                do {
                    let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
                    if let firstCandidate = geminiResponse.candidates.first,
                       let firstPart = firstCandidate.content.parts.first {
                        self?.currentTourGuideText = firstPart.text
                        
                        // Automatically speak the tour guide text
                        self?.speechService?.speakText(firstPart.text)
                    } else {
                        self?.errorMessage = "No content received from Gemini"
                    }
                } catch {
                    self?.errorMessage = "Failed to decode response: \(error.localizedDescription)"
                    print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                }
            }
        }.resume()
    }
    
    func generateTourGuideForAttractions(_ attractions: [Place]) {
        guard let topAttraction = attractions.first else {
            errorMessage = "No attractions available"
            return
        }
        
        generateTourGuideForAttraction(topAttraction)
    }
    
    func autoGenerateForTopAttraction(_ attractions: [Place]) {
        guard let topAttraction = attractions.first else {
            return
        }
        
        generateTourGuideForAttraction(topAttraction)
    }
} 
