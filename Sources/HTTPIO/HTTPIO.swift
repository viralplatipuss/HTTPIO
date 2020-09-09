import Foundation
import SimpleFunctional

/// IO type for making simple HTTP requests.
public struct HTTPIO: IO {
    
    enum Input {
        enum RequestResult {
            case failed(errorMessage: String)
            case responded(httpStatusCode: UInt, bodyBytes: [UInt8])
        }
        
        case requestStarted(id: UInt, hostname: String, path: String)
        case requestEnded(id: UInt, result: RequestResult)
    }
    
    enum Output {
        /// Make an HTTP request to download bytes.
        /// This will always produce a requestStarted input. The id of which can be used to identify the response later.
        case requestBytes(hostname: String, path: String)
        
        /// Attempts to forcefully end an existing HTTP connection, if it exists for the given id.
        /// If the connection was able to be force ended, this will be a failure input result.
        case forceEndRequest(id: UInt)
    }
}
