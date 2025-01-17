
import UIKit
import MapKit
import CoreLocation
import SafariServices


class DetailViewController: UIViewController
{

    @IBOutlet var nameHeaderLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.userInteractionEnabled = false
        map.delegate = self
        return map
    }()
    
    private lazy var openInMapButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.setTitle("View on Map", forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Normal)
        button.titleLabel?.textAlignment = .Center
        button.titleLabel?.font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightMedium)
        button.addTarget(self, action: #selector(DetailViewController.openInMapButtonPressed), forControlEvents: .TouchUpInside)
        button.backgroundColor = StyleController.backgroundColor
        button.sizeToFit()
        return button
    }()
    
    private lazy var feltButton: UIButton = {
        let button = UIButton(type: .Custom)
        button.setTitle("I Felt This", forState: .Normal)
        button.setTitleColor(UIColor.blackColor(), forState: .Normal)
        button.titleLabel?.textAlignment = .Center
        button.titleLabel?.font = UIFont.systemFontOfSize(17.0, weight: UIFontWeightMedium)
        button.addTarget(self, action: #selector(DetailViewController.feltButtonPressed), forControlEvents: .TouchUpInside)
        button.backgroundColor = StyleController.backgroundColor
        button.sizeToFit()
        return button
    }()
    
    private lazy var titleImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "WW"))
        imageView.layer.shadowColor = UIColor.blackColor().CGColor
        imageView.layer.shadowOpacity = 0.5
        imageView.layer.shadowRadius = 1.75
        imageView.layer.shadowOffset = CGSize.zero
        return imageView
    }()
    
    let geocoder = CLGeocoder()
    let titleIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    let mainQueue = NSOperationQueue.mainQueue()
    let manager = CLLocationManager()
    
    var quakeToDisplay: Quake!
    var parsedNearbyCities: [ParsedNearbyCity]? {
        didSet {
            if let _ = parsedNearbyCities {
                tableView.reloadData()
            }
        }
    }
    var lastUserLocation: CLLocation?
    var distanceFromQuake: Double = 0.0
    
    init(quake: Quake) {
        super.init(nibName: String(DetailViewController), bundle: nil)
        self.quakeToDisplay = quake
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TelemetryController.sharedController.logQuakeDetailViewed(quakeToDisplay.weblink ?? "Unknown URL")
        
        if let nearbyCities = quakeToDisplay.nearbyCities {
            parsedNearbyCities = nearbyCities
        }
        else if let url = NSURL(string: quakeToDisplay.detailURL) where quakeToDisplay.nearbyCities == nil {
            NetworkUtility.networkOperationStarted()
            
            let downloadDetailOperation = DownloadDetailOperation(url: url)
            let downloadNearbyCitiesOperation = DownloadNearbyCitiesOperation()
                            
            downloadNearbyCitiesOperation.completionBlock = {
                NetworkUtility.networkOperationFinished()
                if let cities = downloadNearbyCitiesOperation.downloadedCities where cities.count > 0 {
                    PersistentController.sharedController.updateQuakeWithID(self.quakeToDisplay.identifier, withNearbyCities: cities, withCountry: nil)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.parsedNearbyCities = cities
                    }
                }
            }
            
            downloadDetailOperation |> downloadNearbyCitiesOperation
            
            mainQueue.maxConcurrentOperationCount = 1
            mainQueue.qualityOfService = .UserInitiated
            mainQueue.addOperations([downloadDetailOperation, downloadNearbyCitiesOperation], waitUntilFinished: false)
        }
        
        title = "Detail"
        if let countryCode = quakeToDisplay.countryCode {
            titleImageView.image = UIImage(named: countryCode) ?? UIImage(named: "WW")
            navigationItem.titleView = titleImageView
        }
        else {
            navigationItem.titleView = titleIndicatorView
            titleIndicatorView.startAnimating()
        }
        
        nameHeaderLabel.text = quakeToDisplay.name.componentsSeparatedByString(" of ").last!
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: #selector(DetailViewController.shareButtonPressed))
        
        if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse && CLLocationManager.locationServicesEnabled() {
            mapView.showsUserLocation = true
        }
        else if CLLocationManager.authorizationStatus() == .NotDetermined {
            manager.delegate = self
            manager.requestWhenInUseAuthorization()
        }
        
        mapView.removeAnnotation(quakeToDisplay)
        mapView.addAnnotation(quakeToDisplay)
        mapView.showAnnotations(mapView.annotations, animated: true)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor(red: 0.933,  green: 0.933,  blue: 0.933, alpha: 1.0)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if quakeToDisplay.countryCode == nil {
            var stringToSearch = ""
            if let lastLocationName = quakeToDisplay.name.componentsSeparatedByString(" of ").last?.componentsSeparatedByString(", ").last {
                stringToSearch = lastLocationName
            }
            else if let wholeLocationName = quakeToDisplay.name.componentsSeparatedByString(" of ").last {
                stringToSearch = wholeLocationName
            }
            
            NetworkUtility.networkOperationStarted()
            geocoder.geocodeAddressString(stringToSearch) { marks, error -> Void in
                NetworkUtility.networkOperationFinished()
                
                dispatch_async(dispatch_get_main_queue()) {
                    if let mark = marks?.first, let code = mark.ISOcountryCode where error == nil {
                        PersistentController.sharedController.updateQuakeWithID(self.quakeToDisplay.identifier, withNearbyCities: nil, withCountry: code)
                        self.titleImageView.image = UIImage(named: code) ?? UIImage(named: "WW")
                        self.navigationItem.titleView = self.titleImageView
                    }
                    else {
                        self.navigationItem.titleView = self.titleImageView
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if titleIndicatorView.superview != nil {
            titleIndicatorView.removeFromSuperview()
            navigationItem.titleView = nil
        }
        
        if geocoder.geocoding {
            geocoder.cancelGeocode()
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if tableView.tableHeaderView == nil {
            let headerContainerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 275))
            headerContainerView.translatesAutoresizingMaskIntoConstraints = true
            headerContainerView.clipsToBounds = true
            
            mapView.translatesAutoresizingMaskIntoConstraints = false
            openInMapButton.translatesAutoresizingMaskIntoConstraints = false
            feltButton.translatesAutoresizingMaskIntoConstraints = false
            
            headerContainerView.addSubview(mapView)
            headerContainerView.addSubview(openInMapButton)
            headerContainerView.addSubview(feltButton)
            
            let views = ["map": mapView, "open": openInMapButton, "feels": feltButton]
            headerContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[map]|", options: [], metrics: nil, views: views))
            headerContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[open][feels(==open)]|", options: [], metrics: ["size": view.frame.width / 2], views: views))
            headerContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[map][open(==44)]|", options: [], metrics: nil, views: views))
            headerContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[map][feels(==44)]|", options: [], metrics: nil, views: views))
            openInMapButton.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
            
            tableView.tableHeaderView = headerContainerView
        }
    }
    
    // MARK: - Actions
    internal func openInMapButtonPressed() {
        if let rootVC = navigationController?.viewControllers.first as? ListViewController {
            navigationController?.popViewControllerAnimated(true)
            
            let mapVC = MapViewController(centeredOnLocation: quakeToDisplay.coordinate)
            mapVC.delegate = rootVC
            
            navigationController?.pushViewController(mapVC, animated: true)
        }
    }
    
    internal func feltButtonPressed() {
        if let url = NSURL(string: "\(quakeToDisplay.weblink)#impact_tellus") {
            let safariVC = SFSafariViewController(URL: url)
            safariVC.view.tintColor = quakeToDisplay.severityColor
            dispatch_async(dispatch_get_main_queue()) {
                self.presentViewController(safariVC, animated: true, completion: nil)
            }
        }
    }
    
    internal func shareButtonPressed() {
        guard let urlString = quakeToDisplay.weblink, let url = NSURL(string: urlString) else { return }
        let options = MKMapSnapshotOptions()
        options.region = MKCoordinateRegion(center: quakeToDisplay.coordinate, span: MKCoordinateSpan(latitudeDelta: 1 / 2, longitudeDelta: 1 / 2))
        options.size = mapView.frame.size
        options.scale = UIScreen.mainScreen().scale
        options.mapType = .Hybrid
        
        MKMapSnapshotter(options: options).startWithCompletionHandler { snapshot, error in
            let prompt = "A \(Quake.magnitudeFormatter.stringFromNumber(self.quakeToDisplay.magnitude)!) magnitude earthquake happened \(self.quakeToDisplay.timestamp.relativeString()) ago near \(self.quakeToDisplay.name.componentsSeparatedByString(" of ").last!)."
            var items = [prompt, url, self.quakeToDisplay.location]
            
            if let shot = snapshot where error == nil {
                let pin = MKPinAnnotationView(annotation: nil, reuseIdentifier: nil)
                let image = shot.image
                
                UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
                image.drawAtPoint(CGPoint.zero)
                
                let visibleRect = CGRect(origin: CGPoint.zero, size: image.size)
                var point = shot.pointForCoordinate(self.quakeToDisplay.coordinate)
                if visibleRect.contains(point) {
                    point.x = point.x + pin.centerOffset.x - (pin.bounds.size.width / 2)
                    point.y = point.y + pin.centerOffset.y - (pin.bounds.size.height / 2)
                    pin.image?.drawAtPoint(point)
                }
                
                let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                items.append(compositeImage)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.presentViewController(UIActivityViewController(
                    activityItems: items,
                    applicationActivities: nil),
                    animated: true,
                    completion: { _ in
                        TelemetryController.sharedController.logQuakeShare()
                    }
                )
            }
        }
    }
    
}

extension DetailViewController: UITableViewDelegate, UITableViewDataSource
{
    
    // MARK: - UITableView Delegate
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .Value1, reuseIdentifier: "quakeInfoCell")
        
        if indexPath.section == 0 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "Magnitude"
                cell.detailTextLabel?.text = Quake.magnitudeFormatter.stringFromNumber(quakeToDisplay.magnitude)
            }
            else if indexPath.row == 1 {
                cell.textLabel?.text = "Depth"
                Quake.distanceFormatter.units = SettingsController.sharedController.isUnitStyleImperial ? .Imperial : .Metric
                cell.detailTextLabel?.text = Quake.distanceFormatter.stringFromDistance(quakeToDisplay.depth)
            }
            else if indexPath.row == 2 {
                cell.textLabel?.text = "Location"
                cell.detailTextLabel?.text = quakeToDisplay.name
            }
            else if indexPath.row == 3 {
                cell.textLabel?.text = "Coordinate"
                cell.detailTextLabel?.text = quakeToDisplay.coordinate.formatedString()
            }
            else if indexPath.row == 4 {
                cell.textLabel?.text = "Date & Time"
                cell.detailTextLabel?.text = Quake.timestampFormatter.stringFromDate(quakeToDisplay.timestamp)
            }
                
            if quakeToDisplay.felt > 0 && distanceFromQuake > 0 {
                if indexPath.row == 5 {
                    cell.textLabel?.text = "Felt By"
                    cell.detailTextLabel?.text = "\(Int(quakeToDisplay.felt)) people"
                }
                else if indexPath.row == 6 {
                    Quake.distanceFormatter.units = SettingsController.sharedController.isUnitStyleImperial ? .Imperial : .Metric
                    cell.textLabel?.text = "Distance"
                    cell.detailTextLabel?.text = Quake.distanceFormatter.stringFromDistance(distanceFromQuake)
                }
            }
            else if quakeToDisplay.felt > 0 && distanceFromQuake == 0 {
                if indexPath.row == 5 {
                    cell.textLabel?.text = "Felt By"
                    cell.detailTextLabel?.text = "\(Int(quakeToDisplay.felt)) people"
                }
            }
            else if quakeToDisplay.felt == 0 && distanceFromQuake > 0 {
                if indexPath.row == 5 {
                    Quake.distanceFormatter.units = SettingsController.sharedController.isUnitStyleImperial ? .Imperial : .Metric
                    cell.textLabel?.text = "Distance"
                    cell.detailTextLabel?.text = Quake.distanceFormatter.stringFromDistance(distanceFromQuake)
                }
            }
        }
        else if indexPath.section == 1 {
            if let cities = parsedNearbyCities {
                cell.textLabel?.text = cities[indexPath.row].cityName
                cell.accessoryType = .DisclosureIndicator
            }
            else {
                let websiteLabel = UILabel()
                websiteLabel.font = UIFont.systemFontOfSize(18.0, weight: UIFontWeightMedium)
                websiteLabel.translatesAutoresizingMaskIntoConstraints = false
                websiteLabel.textColor = quakeToDisplay.severityColor
                websiteLabel.text = Int(quakeToDisplay.provider) == SourceProvider.USGS.rawValue ? "Open in USGS" : "Open in EMSC"
                websiteLabel.textAlignment = .Center
                
                cell.translatesAutoresizingMaskIntoConstraints = true
                cell.addSubview(websiteLabel)
                
                let views = ["label": websiteLabel]
                cell.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[label]|", options: [], metrics: nil, views: views))
                cell.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[label]|", options: [], metrics: nil, views: views))
            }
        }
        else {
            let websiteLabel = UILabel()
            websiteLabel.font = UIFont.systemFontOfSize(18.0, weight: UIFontWeightMedium)
            websiteLabel.translatesAutoresizingMaskIntoConstraints = false
            websiteLabel.textColor = quakeToDisplay.severityColor
            websiteLabel.text = "Open in USGS"
            websiteLabel.textAlignment = .Center
            
            cell.translatesAutoresizingMaskIntoConstraints = true
            cell.addSubview(websiteLabel)
            
            let views = ["label": websiteLabel]
            cell.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[label]|", options: [], metrics: nil, views: views))
            cell.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[label]|", options: [], metrics: nil, views: views))
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return parsedNearbyCities != nil ? "Nearby Cities" : nil
        }
        else {
            return nil
        }
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
        guard NetworkUtility.internetReachable() else {
            return
        }
        
        if let urlString = quakeToDisplay.weblink, let url = NSURL(string: urlString) where parsedNearbyCities != nil ? indexPath.section == 2 : indexPath.section == 1 && indexPath.row == 0 {
            let safariVC = SFSafariViewController(URL: url)
            safariVC.view.tintColor = quakeToDisplay.severityColor
            dispatch_async(dispatch_get_main_queue()) {
                self.presentViewController(safariVC, animated: true, completion: { _ in
                    TelemetryController.sharedController.logQuakeOpenedInBrowser()
                })
            }
        }
        else if let citiesToDisplay = parsedNearbyCities where indexPath.section == 1 && parsedNearbyCities != nil {
            TelemetryController.sharedController.logQuakeCitiesViewed()
            let selectedCity = citiesToDisplay[indexPath.row]
            let sortedCities = citiesToDisplay.sort({ $0.0.cityName == selectedCity.cityName })
            navigationController?.pushViewController(MapViewController(quakeToDisplay: quakeToDisplay, nearbyCities: sortedCities), animated: true)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44.0
    }
    
    // MARK: - UITableView DataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return parsedNearbyCities != nil ? 3 : 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            var offset = 0
            if quakeToDisplay.felt == 0 {
                offset += 1
            }
            if distanceFromQuake == 0 {
                offset += 1
            }
            return 7 - offset
        }
        else if section == 1 {
            return parsedNearbyCities != nil ? parsedNearbyCities!.count : 1
        }
        else {
            return 1
        }
    }
    
}

extension DetailViewController: CLLocationManagerDelegate
{
    
    // MARK: - CLLocationManager Delegate
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
}

extension DetailViewController: MKMapViewDelegate
{
    
    // MARK: - MKMapView Delegate
    func mapView(mapView: MKMapView, didUpdateUserLocation userLocation: MKUserLocation)
    {
        guard let userLocation = userLocation.location where userLocation.horizontalAccuracy > 0 else {
            return
        }
        
        if let lastLocation = lastUserLocation where lastLocation.distanceFromLocation(userLocation) > 25.0 {
            return
        }
        
        distanceFromQuake = userLocation.distanceFromLocation(quakeToDisplay.location)
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
        
        if userLocation.distanceFromLocation(quakeToDisplay.location) > (1000 * 900) {
            return
        }
        
        mapView.showAnnotations(mapView.annotations, animated: true)
        
        lastUserLocation = userLocation
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        guard annotation is Quake else {
            return nil
        }
        
        if let annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("Quake") as? MKPinAnnotationView {
            return annotationView
        }
        else {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Quake")
            annotationView.enabled = true
            annotationView.animatesDrop = true
            
            annotationView.pinTintColor = quakeToDisplay.severityColor
            
            return annotationView
        }
    }
    
}
