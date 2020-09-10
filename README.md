# HTTPIO

HTTP IO type and handler for use with the SimpleFunctional library.

Provides a very basic IO handler for handling HTTP requests. Will be extended as needed to handle more complex requests.

This is powered using [Vapor's HTTP library](https://github.com/vapor/http), which means it is a multi-platform IO handler. Linux, Mac, iOS

```swift
public struct HTTPIO: IO {
    
    public enum Input {
        public enum RequestResult {
            case failed(errorMessage: String)
            case responded(httpStatusCode: UInt, bodyBytes: [UInt8])
        }
        
        case requestStarted(id: UInt, hostname: String, path: String)
        case requestEnded(id: UInt, result: RequestResult)
    }
    
    public enum Output {
        /// Make an HTTP request to download bytes.
        /// This will always produce a requestStarted input. The id of which can be used to identify the response later.
        case requestBytes(hostname: String, path: String)
        
        /// Attempts to forcefully end an existing HTTP connection, if it exists for the given id.
        /// If the connection was able to be force ended, this will be a failure input result.
        case forceEndRequest(id: UInt)
    }
}

```
