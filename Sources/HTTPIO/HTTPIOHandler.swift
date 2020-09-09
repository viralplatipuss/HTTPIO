import Foundation
import HTTP
import SimpleFunctional

/**
 Handles HTTPIO.

 This is not thread-safe. handle() should be called in order on the same thread.
 */
public final class HTTPIOHandler: IOHandling {
    typealias IOType = HTTPIO
    
    public func handle(output: HTTPIO.Output, inputClosure: @escaping (HTTPIO.Input) -> Void) {
        switch output {
        case let .requestBytes(hostname, path): downloadBytes(hostname: hostname, path: path, inputClosure: inputClosure)
        case let .forceEndRequest(id): forceEnd(id: id, inputClosure: inputClosure)
        }
    }
    
    
    // MARK: - Private
    
    private let worker = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    private var nextId: UInt = 0
    private var clientFutureForId = [UInt: EventLoopFuture<HTTPClient>]()
    
    private func downloadBytes(hostname: String, path: String, inputClosure: @escaping (HTTPIO.Input) -> Void) {
        let id = nextId
        nextId += 1
        
        inputClosure(.requestStarted(id: id, hostname: hostname, path: path))
        
        guard let url = URL(string: path) else {
            inputClosure(.requestEnded(id: id, result: .failed(errorMessage: "Invalid path: \(path)")))
            return
        }
        
        let clientFuture = HTTPClient.connect(hostname: hostname, on: worker)
        clientFutureForId[id] = clientFuture
        
        let httpResFuture = clientFuture.flatMap(to: HTTPResponse.self) { $0.send(HTTPRequest(url: url)) }
        
        httpResFuture.whenSuccess {
            inputClosure(.requestEnded(id: id, result: .responded(httpStatusCode: $0.status.code, bodyBytes: $0.body.data.map { [UInt8]($0) } ?? [])))
        }
        
        httpResFuture.whenFailure {
            inputClosure(.requestEnded(id: id, result: .failed(errorMessage: $0.localizedDescription)))
        }
        
        httpResFuture.always { [weak self] in
            self?.clientFutureForId[id] = nil
        }
    }
    
    private func forceEnd(id: UInt, inputClosure: @escaping (HTTPIO.Input) -> Void) {
        guard let clientFuture = clientFutureForId[id] else { return }
        
        let closeFuture = clientFuture.flatMap { $0.close() }
        closeFuture.whenSuccess {
            inputClosure(.requestEnded(id: id, result: .failed(errorMessage: "Connection was force ended.")))
        }
    }
}
