
import UIKit

class USGSMajorOperation: USGSFetchQuakesOperation {
    
    let page: UInt
    
    init(page: UInt) {
        self.page = page
    }
    
    override var urlString: String {
        let currentDate = NSDate()
        let currentCalendar = NSCalendar.currentCalendar()
        
        var dateParameterString = ""
        if let endDate = currentCalendar.dateByAddingUnit(.Month, value: -1 * Int(page), toDate: currentDate, options: [.MatchLast]), let startDate = currentCalendar.dateByAddingUnit(.Month, value: -1, toDate: endDate, options: [.MatchLast]) {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateParameterString = "&endtime=\(dateFormatter.stringFromDate(endDate))&starttime=\(dateFormatter.stringFromDate(startDate))"
        }

        return "\(baseURLString)query?format=geojson&minmagnitude=3.8&limit=\(SettingsController.sharedController.fetchLimit.rawValue)" + dateParameterString
    }
    
}
