import Foundation
import HTTP
import SimpleFunctional

/**
 Handles HTTPIO.

 This is not thread-safe. handle(output:) should be called in order on the same thread.
 */
public final class HTTPIOHandler: BaseIOHandler<HTTPIO> {
    
    public override func handle(output: Output) {
        switch output {
        case let .request(req): downloadBytes(request: req)
        case let .forceEndRequest(id): forceEnd(id: id)
        }
    }
    
    
    // MARK: - Private
    
    private let worker = MultiThreadedEventLoopGroup(numberOfThreads: 2)
    private var nextId: UInt = 0
    private var clientFutureForId = [UInt: EventLoopFuture<HTTPClient>]()
    
    private func downloadBytes(request: HTTPIO.Request) {
        let id = nextId
        nextId += 1
        
        runInput(.init(id: id, update: .requestStarted(request)))
        
        guard let url = URL(string: request.path) else {
            runInput(.init(id: id, update: .requestEnded(result: .failed(errorMessage: "Invalid path: \(request.path)"))))
            return
        }
        
        let clientFuture = HTTPClient.connect(hostname: request.hostname, on: worker)
        clientFutureForId[id] = clientFuture
        
        let httpResFuture = clientFuture.flatMap(to: HTTPResponse.self) { $0.send(HTTPRequest(url: url)) }
        
        httpResFuture.whenSuccess { [weak self] in
            self?.runInput(.init(id: id, update: .requestEnded(result: .responded(httpStatusCode: $0.status.code, bodyBytes: $0.body.data.map { [UInt8]($0) } ?? []))))
        }
        
        httpResFuture.whenFailure { [weak self] in
            self?.runInput(.init(id: id, update: .requestEnded(result: .failed(errorMessage: $0.localizedDescription))))
        }
        
        httpResFuture.always { [weak self] in
            self?.clientFutureForId[id] = nil
        }
    }
    
    private func forceEnd(id: UInt) {
        guard let clientFuture = clientFutureForId[id] else { return }
        
        let closeFuture = clientFuture.flatMap { $0.close() }
        closeFuture.whenSuccess { [weak self] in
            self?.runInput(.init(id: id, update: .requestEnded(result: .failed(errorMessage: "Connection was force ended."))))
        }
    }
}
