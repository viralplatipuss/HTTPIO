import Foundation
import SimpleFunctional

/// IO type for making simple HTTP requests.
public struct HTTPIO: IO {
    
    public struct Input {
        public enum Result {
            case failed(errorMessage: String)
            case responded(httpStatusCode: UInt, bodyBytes: [UInt8])
        }
        
        public enum Update {
            case requestStarted(Request)
            case requestEnded(result: Result)
        }
        
        public let id: UInt
        public let update: Update
    }
    
    public enum Output {
        /// Make an HTTP request.
        /// This will always produce a requestStarted input. The id of which can be used to identify the response later.
        case request(Request)
        
        /// Attempts to forcefully end an existing HTTP connection, if it exists for the given id.
        /// If the connection was able to be force ended, this will be a failure input result.
        case forceEndRequest(id: UInt)
    }
    
    public struct Request: Hashable {
        public let hostname: String
        public let path: String
    }
}
