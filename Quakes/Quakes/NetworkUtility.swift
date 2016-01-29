
import UIKit


class NetworkUtility
{
    
    private static var loadingCount = 0
    
    static func networkOperationStarted() {
        
        if loadingCount == 0 {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        }
        loadingCount++
    }
    
    static func networkOperationFinished() {
        if loadingCount > 0 {
            loadingCount--
        }
        if loadingCount == 0 {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    static func internetReachable() -> Bool {
        if let reach = try? Reachability.reachabilityForInternetConnection() {
            return reach.isReachable()
        }
        else {
            return false
        }
    }
    
}