import Foundation
import Network

// MARK: - HTTP Server for StreamDeck Integration
class HTTPServer {
    static let shared = HTTPServer()
    
    private var listener: NWListener?
    private let port: UInt16 = 8080
    private let queue = DispatchQueue(label: "HTTPServer", qos: .utility)
    
    // Manager references
    private let activityTracker = ActivityTracker.shared
    private let templateManager = TemplateManager.shared
    private let preferences = TimeDeckPreferences.shared
    
    private init() {}
    
    // MARK: - Server Control
    func startServer() {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            print("❌ Invalid port number: \(self.port)")
            return
        }
        
        do {
            listener = try NWListener(using: .tcp, on: nwPort)
            listener?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("🌐 TimeDeck HTTP API Server running on http://localhost:\(self.port)")
                case .failed(let error):
                    print("❌ HTTP Server failed: \(error)")
                default:
                    break
                }
            }
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleConnection(connection)
            }
            
            listener?.start(queue: queue)
        } catch {
            print("❌ Failed to start HTTP server: \(error)")
        }
    }
    
    func stopServer() {
        listener?.cancel()
        listener = nil
        print("🛑 HTTP Server stopped")
    }
    
    // MARK: - Connection Handling
    private func handleConnection(_ connection: NWConnection) {
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                self.receiveRequest(connection)
            case .failed(let error):
                print("Connection failed: \(error)")
            default:
                break
            }
        }
        
        connection.start(queue: queue)
    }
    
    private func receiveRequest(_ connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                let request = String(data: data, encoding: .utf8) ?? ""
                let response = self?.processRequest(request) ?? self?.errorResponse(500, "Internal Server Error")
                self?.sendResponse(connection, response!)
            }
            
            if isComplete {
                connection.cancel()
            } else if error == nil {
                self?.receiveRequest(connection)
            }
        }
    }
    
    private func sendResponse(_ connection: NWConnection, _ response: String) {
        let data = response.data(using: .utf8)!
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Send error: \(error)")
            }
            connection.cancel()
        })
    }
    
    // MARK: - Request Processing
    private func processRequest(_ request: String) -> String {
        let lines = request.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else {
            return errorResponse(400, "Bad Request")
        }
        
        let components = requestLine.components(separatedBy: " ")
        guard components.count >= 3 else {
            return errorResponse(400, "Bad Request")
        }
        
        let method = components[0]
        let path = components[1]
        
        print("🌐 API Request: \(method) \(path)")
        
        // Parse request body for POST requests
        var body: [String: Any] = [:]
        if method == "POST", let bodyStart = request.range(of: "\r\n\r\n") {
            let bodyString = String(request[bodyStart.upperBound...])
            if let bodyData = bodyString.data(using: .utf8) {
                body = (try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]) ?? [:]
            }
        }
        
        // Route the request
        switch (method, path) {
        // Status endpoints
        case ("GET", "/api/status"):
            return getActivityStatus()
        case ("GET", "/api/templates"):
            return getTemplates()
        
        // Activity control endpoints
        case ("POST", "/api/activities/start"):
            return startActivity(body: body)
        case ("POST", "/api/activities/end"):
            return endActivity()
        case ("POST", "/api/activities/pause"):
            return pauseResumeActivity()
        case ("POST", "/api/activities/fresh"):
            return startFresh()
        
        // Health check
        case ("GET", "/api/health"):
            return successResponse(["status": "ok", "message": "TimeDeck API is running"])
            
        // CORS preflight
        case ("OPTIONS", _):
            return corsResponse()
            
        default:
            return errorResponse(404, "Not Found")
        }
    }
    
    // MARK: - API Endpoints
    private func getActivityStatus() -> String {
        var statusData: [String: Any] = [
            "hasActiveActivity": activityTracker.currentActivityType != nil,
            "isInBreak": activityTracker.isInBreak
        ]
        
        if let activityInfo = activityTracker.getCurrentActivityInfo() {
            statusData["currentActivity"] = activityInfo.activity
            statusData["elapsedTime"] = activityInfo.timeString
        }
        
        return successResponse(statusData)
    }
    
    private func getTemplates() -> String {
        let templates = preferences.activityTemplates
        let templateData = templates.map { template in
            return [
                "name": template.name,
                "emoji": template.emoji,
                "category": template.category,
                "isQuickAction": template.isQuickAction
            ]
        }
        
        return successResponse([
            "templates": templateData,
            "count": templates.count
        ])
    }
    
    private func startActivity(body: [String: Any]) -> String {
        guard let activityName = body["activity"] as? String, !activityName.isEmpty else {
            return errorResponse(400, "Missing or empty 'activity' parameter")
        }
        
        DispatchQueue.main.async {
            self.activityTracker.startActivity(name: activityName)
        }
        
        return successResponse([
            "message": "Activity started",
            "activity": activityName
        ])
    }
    
    private func endActivity() -> String {
        guard activityTracker.currentActivityType != nil else {
            return errorResponse(400, "No active activity to end")
        }
        
        let currentActivity = activityTracker.currentActivityType!
        
        DispatchQueue.main.async {
            self.activityTracker.endCurrentActivity()
        }
        
        return successResponse([
            "message": "Activity ended",
            "activity": currentActivity
        ])
    }
    
    private func pauseResumeActivity() -> String {
        guard activityTracker.currentActivityType != nil else {
            return errorResponse(400, "No active activity to pause/resume")
        }
        
        let wasInBreak = activityTracker.isInBreak
        
        DispatchQueue.main.async {
            self.activityTracker.pauseResumeActivity()
        }
        
        return successResponse([
            "message": wasInBreak ? "Activity resumed" : "Activity paused",
            "activity": activityTracker.currentActivityType!,
            "isInBreak": !wasInBreak
        ])
    }
    
    private func startFresh() -> String {
        DispatchQueue.main.async {
            self.activityTracker.startFresh()
        }
        
        return successResponse([
            "message": "Started fresh - all activity logs cleared"
        ])
    }
    
    // MARK: - Response Helpers
    private func successResponse(_ data: [String: Any]) -> String {
        let responseData = [
            "success": true,
            "data": data,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ] as [String: Any]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: responseData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return errorResponse(500, "Failed to serialize response")
        }
        
        return httpResponse(200, jsonString, "application/json")
    }
    
    private func errorResponse(_ code: Int, _ message: String) -> String {
        let errorData = [
            "success": false,
            "error": [
                "code": code,
                "message": message
            ],
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ] as [String: Any]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: errorData, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return httpResponse(code, "{\"error\":\"Failed to serialize error\"}", "application/json")
        }
        
        return httpResponse(code, jsonString, "application/json")
    }
    
    private func corsResponse() -> String {
        return """
        HTTP/1.1 200 OK\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Methods: GET, POST, OPTIONS\r
        Access-Control-Allow-Headers: Content-Type\r
        Content-Length: 0\r
        \r\n
        """
    }
    
    private func httpResponse(_ statusCode: Int, _ body: String, _ contentType: String = "text/plain") -> String {
        let statusText = statusCode == 200 ? "OK" : (statusCode == 404 ? "Not Found" : "Error")
        
        return """
        HTTP/1.1 \(statusCode) \(statusText)\r
        Content-Type: \(contentType)\r
        Content-Length: \(body.utf8.count)\r
        Access-Control-Allow-Origin: *\r
        Access-Control-Allow-Methods: GET, POST, OPTIONS\r
        Access-Control-Allow-Headers: Content-Type\r
        Connection: close\r
        \r
        \(body)
        """
    }
}
