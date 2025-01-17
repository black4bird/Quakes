
import Foundation
import CoreLocation


class SettingsController
{
    
    static let kSettingsControllerDidChangeUnitStyleNotification = "settingsControllerDidChangeUnitStyle"
    static let kSettingsControllerDidChangePurchaseAdRemovalNotification = "settingsControllerDidChangePurchaseAdRemoval"
    static let kSettingsControllerDidUpdateLastFetchDateNotification = "settingsControllerDidUpdateLastFetchDate"
    static let kSettingsControllerDidUpdateLocationForPushNotification = "settingsControllerDidUpdateLocationForPush"
    
    enum APIFetchSize: Int {
        case Small = 100
        case Medium = 225
        case Large = 400
        case ExtraLarge = 1000
        
        func displayString() -> String {
            switch self {
            case .Small:
                return "Small"
            case .Medium:
                return "Medium"
            case .Large:
                return "Large"
            case .ExtraLarge:
                return "ExtraLarge"
            }
        }
        
        static func closestValueForInteger(value: Int) -> APIFetchSize {
            switch value {
            case APIFetchSize.Small.rawValue:
                return .Small
            case APIFetchSize.Medium.rawValue:
                return .Medium
            case APIFetchSize.Large.rawValue:
                return .Large
            case APIFetchSize.ExtraLarge.rawValue:
                return .ExtraLarge
            default:
                fatalError("PROGRAMMING ERROR: You didn't specify a correct value")
            }
        }
    }
    
    enum SearchRadiusSize: Int {
        case Small = 50
        case Medium = 150
        case Large = 275
        case ExtraLarge = 750
        
        func displayString() -> String {
            switch self {
            case .Small:
                return "Small"
            case .Medium:
                return "Medium"
            case .Large:
                return "Large"
            case .ExtraLarge:
                return "ExtraLarge"
            }
        }
        
        static func closestValueForInteger(value: Int) -> SearchRadiusSize {
            switch value {
            case SearchRadiusSize.Small.rawValue:
                return .Small
            case SearchRadiusSize.Medium.rawValue:
                return .Medium
            case SearchRadiusSize.Large.rawValue:
                return .Large
            case SearchRadiusSize.ExtraLarge.rawValue:
                return .ExtraLarge
            default:
                fatalError("PROGRAMMING ERROR: You didn't specify a correct value \(value)")
            }
        }
    }
    
    static let sharedController = SettingsController()
    
    private static let kCachedPlacemarkKey = "cachedPlace"
    private static let kLastSearchedKey = "lastsearched"
    private static let kSearchRadiusKey = "searchRadius"
    private static let kFetchSizeLimitKey = "fetchLimit"
    private static let kUnitStyleKey = "unitStyle"
    private static let kLastLocationOptionKey = "lastLocationOption"
    private static let kUserFirstLaunchedKey = "firstLaunchKey"
    private static let kLastPushKey = "lastPush"
    private static let kLastFetchKey = "lastFetch"
    private static let kPaidToRemoveKey = "alreadyPaid"
    private static let kHasAttemptedNotificationKey = "attemptedNotification"
    private static let kPushTokenKey = "pushToken"
    
    private let defaults = NSUserDefaults.standardUserDefaults()
    
    lazy private var baseDefaults:[String: AnyObject] = {
        return [
            kSearchRadiusKey: SearchRadiusSize.Medium.rawValue,
            kFetchSizeLimitKey: APIFetchSize.Medium.rawValue,
            kLastPushKey: NSDate.distantPast(),
            kHasAttemptedNotificationKey: false,
            kPaidToRemoveKey: false,
            kUnitStyleKey: true
        ]
    }()
    
    // MARK: - Init
    init() {
        loadSettings()
    }
    
    // MARK: - Private
    private func loadSettings() {
        defaults.registerDefaults(baseDefaults)
    }
    
    // MARK: - Helper
    func hasSearchedBefore() -> Bool {
        return lastLocationOption == nil && lastSearchedPlace == nil && cachedAddress == nil
    }
    
    func isLocationOptionWorldOrMajor() -> Bool {
        return lastLocationOption == LocationOption.World.rawValue || lastLocationOption == LocationOption.Major.rawValue
    }
    
    func locationEligableForNotifications() -> CLLocation? {
        if let lastSearch = lastSearchedPlace where lastSearch.location != nil {
            return lastSearch.location
        }
        else if let lastAddress = cachedAddress where lastAddress.location != nil {
            return lastAddress.location
        }
        else {
            return nil
        }
    }
        
    // MARK: - Public
    var cachedAddress: CLPlacemark? {
        get {
            if let data = defaults.objectForKey(SettingsController.kCachedPlacemarkKey) as? NSData,
                let place = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? CLPlacemark {
                    return place
            }
            else {
                return nil
            }
        }
        set {
            if let newPlace = newValue {
                let data = NSKeyedArchiver.archivedDataWithRootObject(newPlace)
                defaults.setObject(data, forKey: SettingsController.kCachedPlacemarkKey)
                defaults.synchronize()
                NSNotificationCenter.defaultCenter().postNotificationName(SettingsController.kSettingsControllerDidUpdateLocationForPushNotification, object: nil)
            }
            else {
                defaults.setObject(nil, forKey: SettingsController.kCachedPlacemarkKey)
                defaults.synchronize()
            }
        }
    }
    
    var lastSearchedPlace: CLPlacemark? {
        get {
            if let data = defaults.objectForKey(SettingsController.kLastSearchedKey) as? NSData,
                let place = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? CLPlacemark {
                return place
            }
            else {
                return nil
            }
        }
        set {
            if let newPlace = newValue {
                let data = NSKeyedArchiver.archivedDataWithRootObject(newPlace)
                defaults.setObject(data, forKey: SettingsController.kLastSearchedKey)
                defaults.synchronize()
                NSNotificationCenter.defaultCenter().postNotificationName(SettingsController.kSettingsControllerDidUpdateLocationForPushNotification, object: nil)
            }
            else {
                defaults.setObject(nil, forKey: SettingsController.kLastSearchedKey)
                defaults.synchronize()
            }
        }
    }
    
    var pushToken: String? {
        get {
            return defaults.stringForKey(SettingsController.kPushTokenKey)
        }
        set {
            defaults.setObject(newValue, forKey: SettingsController.kPushTokenKey)
            defaults.synchronize()
        }
    }
    
    var hasAttemptedNotificationPermission: Bool {
        get {
            return defaults.boolForKey(SettingsController.kHasAttemptedNotificationKey)
        }
        set {
            defaults.setBool(newValue, forKey: SettingsController.kHasAttemptedNotificationKey)
            defaults.synchronize()
        }
    }
    
    var hasSupported: Bool {
        get {
            return defaults.boolForKey(SettingsController.kPaidToRemoveKey)
        }
        set {
            if hasSupported {
                TelemetryController.sharedController.logSupportedApp()
            }
            defaults.setBool(newValue, forKey: SettingsController.kPaidToRemoveKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(self.dynamicType.kSettingsControllerDidChangePurchaseAdRemovalNotification, object: nil)
        }
    }
    
    var isUnitStyleImperial: Bool {
        get {
            return defaults.boolForKey(SettingsController.kUnitStyleKey)
        }
        set {
            defaults.setBool(newValue, forKey: SettingsController.kUnitStyleKey)
            defaults.synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(self.dynamicType.kSettingsControllerDidChangeUnitStyleNotification, object: nil)
        }
    }
    
    var lastLocationOption: String? {
        get {
            return defaults.stringForKey(SettingsController.kLastLocationOptionKey)
        }
        set {
            defaults.setObject(newValue, forKey: SettingsController.kLastLocationOptionKey)
            defaults.synchronize()
        }
    }
    
    var searchRadius: SearchRadiusSize {
        get {
            return NSProcessInfo.processInfo().lowPowerModeEnabled ? .Small : SearchRadiusSize.closestValueForInteger(defaults.integerForKey(SettingsController.kSearchRadiusKey))
        }
        set {
            defaults.setInteger(newValue.rawValue, forKey: SettingsController.kSearchRadiusKey)
            defaults.synchronize()
        }
    }
    
    var fetchLimit: APIFetchSize {
        get {
            return NSProcessInfo.processInfo().lowPowerModeEnabled ? .Small : APIFetchSize.closestValueForInteger(defaults.integerForKey(SettingsController.kFetchSizeLimitKey))
        }
        set {
            defaults.setInteger(newValue.rawValue, forKey: SettingsController.kFetchSizeLimitKey)
            defaults.synchronize()
        }
    }
    
    var fisrtLaunchDate: NSDate? {
        get {
            let launchTimeInterval = defaults.doubleForKey(SettingsController.kUserFirstLaunchedKey)
            if launchTimeInterval == 0 {
                defaults.setDouble(NSDate().timeIntervalSince1970, forKey: SettingsController.kUserFirstLaunchedKey)
                defaults.synchronize()

                return nil
            }
            else {
                return NSDate(timeIntervalSince1970: launchTimeInterval)
            }
        }
        set {
            defaults.setDouble(NSDate().timeIntervalSince1970, forKey: SettingsController.kUserFirstLaunchedKey)
            defaults.synchronize()
        }
    }
    
    var lastPushDate: NSDate {
        get {
            let interval = defaults.doubleForKey(SettingsController.kLastPushKey)
            return interval == 0 ? NSDate.distantPast() : NSDate(timeIntervalSince1970: interval)
        }
        set {
            defaults.setDouble(newValue.timeIntervalSince1970, forKey: SettingsController.kLastPushKey)
            defaults.synchronize()
        }
    }
    
    var lastFetchDate: NSDate {
        get {
            let interval = defaults.doubleForKey(SettingsController.kLastFetchKey)
            return interval == 0 ? NSDate.distantPast() : NSDate(timeIntervalSince1970: interval)
        }
        set {
            NSNotificationCenter.defaultCenter().postNotificationName(self.dynamicType.kSettingsControllerDidUpdateLastFetchDateNotification, object: nil)
            defaults.setDouble(newValue.timeIntervalSince1970, forKey: SettingsController.kLastFetchKey)
            defaults.synchronize()
        }
    }
    
}
