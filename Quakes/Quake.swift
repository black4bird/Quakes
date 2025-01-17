
import Foundation
import CoreData
import CoreLocation
import MapKit


class Quake: NSManagedObject {
    
    // MARK: Formatters
    static let timestampFormatter: NSDateFormatter = {
        let timestampFormatter = NSDateFormatter()
        
        timestampFormatter.dateStyle = .MediumStyle
        timestampFormatter.timeStyle = .ShortStyle
        
        return timestampFormatter
    }()
    
    static let magnitudeFormatter: NSNumberFormatter = {
        let magnitudeFormatter = NSNumberFormatter()
        
        magnitudeFormatter.numberStyle = .DecimalStyle
        magnitudeFormatter.maximumFractionDigits = 1
        magnitudeFormatter.minimumFractionDigits = 1
        
        return magnitudeFormatter
    }() 
    
    static let distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .Abbreviated
        formatter.units = SettingsController.sharedController.isUnitStyleImperial ? .Imperial : .Metric
        return formatter
    }()
    
    // MARK: - Properties
    @NSManaged var depth: Double
    @NSManaged var timestamp: NSDate
    @NSManaged var name: String
    @NSManaged var magnitude: Double
    @NSManaged var longitude: Double
    @NSManaged var latitude: Double
    @NSManaged var identifier: String
    @NSManaged var detailURL: String
    @NSManaged var felt: Double
    @NSManaged var provider: Int16

    @NSManaged var weblink: String?
    @NSManaged var polyData: NSData?
    @NSManaged var nearbyCitiesData: NSData?
    @NSManaged var distance: NSNumber?
    @NSManaged var countryCode: String?
    
    var additionalInfoString: String {        
        Quake.distanceFormatter.units = SettingsController.sharedController.isUnitStyleImperial ? .Imperial : .Metric
        return "Depth: \(Quake.distanceFormatter.stringFromDistance(depth))"
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        return CLLocation(coordinate: coordinate, altitude: -depth, horizontalAccuracy: kCLLocationAccuracyBest, verticalAccuracy: kCLLocationAccuracyBest, timestamp: timestamp)
    }
    
    var severityColor: UIColor {
        if magnitude >= 6.5 {
            return StyleController.purpleColor
        }
        else if magnitude >= 4.0 {
            return StyleController.redQuakeColor
        }
        else if magnitude >= 3.0 {
            return StyleController.orangeQuakeColor
        }
        else {
            return StyleController.greenQuakeColor
        }
    }
    
    var stringForProvider: String {
        return Int(provider) == SourceProvider.USGS.rawValue ? "USGS" : "EMSC"
    }
    
    var nearbyCities: [ParsedNearbyCity]? {
        if let data = nearbyCitiesData {
            if let cities = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? [ParsedNearbyCity] {
                return cities
            }
        }
        return nil
    }
    
}

extension Quake: Fetchable {
    
    typealias FetchableType = Quake
    
    static func entityName() -> String
    {
        return "Quake"
    }
    
}

extension Quake: MKAnnotation {
    
    var title: String? {
        return name
    }
    
    var subtitle: String? {
        let formatter = NSNumberFormatter()
        
        formatter.numberStyle = .DecimalStyle
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        
        let timestampFormatter = NSDateFormatter()
        
        timestampFormatter.dateStyle = .MediumStyle
        timestampFormatter.timeStyle = .MediumStyle

        return formatter.stringFromNumber(magnitude)! + ", at " + timestampFormatter.stringFromDate(timestamp)
    }
}
