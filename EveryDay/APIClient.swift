//
//  APIClient.swift
//  EveryDay
//
//  Created by Chris Melamed on 3/22/24.
//

import Foundation

class APIClient {
    static let apiKey: String = {
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let key = plist["ANTHROPIC_API_KEY"] as? String,
              key != "YOUR_ANTHROPIC_API_KEY_HERE" else {
            fatalError("Please add your Anthropic API key to Config.plist")
        }
        return key
    }()
    
    
    static func sendMessageToAssistant(message: String, systemPrompt: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let requestBody: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 4000,
            "messages": [
                ["role": "user", "content": message]
            ],
            "system": systemPrompt,
            "temperature": 0.9,
            "stream": false
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                print("HTTP Status Code: \(statusCode)")
                
                if statusCode >= 400 {
                    var errorMessage = "HTTP Error: \(statusCode)"
                    
                    if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let errorDetails = jsonResponse["error"] as? [String: Any],
                       let errorType = errorDetails["type"] as? String,
                       let errorDescription = errorDetails["message"] as? String {
                        errorMessage += " - \(errorType): \(errorDescription)"
                    }
                    
                    completion(.failure(NSError(domain: errorMessage, code: statusCode, userInfo: nil)))
                    return
                }
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let content = jsonResponse["content"] as? [[String: Any]],
                   let textBlock = content.first(where: { $0["type"] as? String == "text" }),
                   let responseText = textBlock["text"] as? String {
                    completion(.success(responseText))
                } else {
                    completion(.failure(NSError(domain: "Failed to decode response", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    
    static func generateTitle(content: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: "https://api.anthropic.com/v1/complete") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let prompt = "\n\nHuman: Please generate a title for the following journal entry:\n\n\(content) the response should include ONLY the title\n\nAssistant:"
        let requestBody: [String: Any] = [
            "prompt": prompt,
            "model": "claude-v1",
            "max_tokens_to_sample": 50,
            "temperature": 0.7,
            "stream": false
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            
            //print
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let completionValue = jsonResponse["completion"] as? String {
                    let title = completionValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    completion(.success(title))
                } else {
                    completion(.failure(NSError(domain: "Failed to decode title", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    static func generateTags(content: String, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let url = URL(string: "https://api.anthropic.com/v1/complete") else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        
        let prompt = "\n\nHuman: Please generate 3 to 5 tags for the following journal entry:\n\n\(content) the response should include ONLY the tags separated by commas, no other text. \n\nAssistant:"
        let requestBody: [String: Any] = [
            "prompt": prompt,
            "model": "claude-v1",
            "max_tokens_to_sample": 50
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            // Print the response data
            print("Tags Response: \(String(data: data, encoding: .utf8) ?? "")")
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let tagsString = jsonResponse["completion"] as? String {
                    let tags = tagsString.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
                    completion(.success(tags))
                } else {
                    completion(.failure(NSError(domain: "Failed to decode tags", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    
}
