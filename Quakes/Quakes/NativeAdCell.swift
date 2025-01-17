
import UIKit
import GoogleMobileAds

protocol NativeAdCellDelegate: class {
    func nativeAdCellDidFailToReceiveAd(cell: NativeAdCell)
}

class NativeAdCell: UITableViewCell {

    static let reuseIdentifier = "NativeAdCell"
    static let cellHeight: CGFloat = 85.0
    
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet var nativeExpressAdView: GADNativeExpressAdView!
    
    weak var delegate: NativeAdCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        nativeExpressAdView.delegate = self
        nativeExpressAdView.adUnitID = "ca-app-pub-6493864895252732/5256701203"
        nativeExpressAdView.backgroundColor = StyleController.backgroundColor
        
        nativeExpressAdView.alpha = 0.0
        activityIndicatorView.startAnimating()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        nativeExpressAdView.alpha = 0.0
        activityIndicatorView.startAnimating()
    }
    
    func loadRequest() {
        let request = GADRequest()
        request.testDevices = [kGADSimulatorID]
        nativeExpressAdView.loadRequest(request)
    }
    
}

extension NativeAdCell: GADNativeExpressAdViewDelegate {
    
    // MARK: - GADBannerView Delegate
    func nativeExpressAdViewDidReceiveAd(nativeExpressAdView: GADNativeExpressAdView!) {
        activityIndicatorView.stopAnimating()
        UIView.animateWithDuration(0.23) {
            nativeExpressAdView.alpha = 1.0
        }
    }
    
    func nativeExpressAdView(nativeExpressAdView: GADNativeExpressAdView!, didFailToReceiveAdWithError error: GADRequestError!) {
        UIView.animateWithDuration(0.23, animations: {
            nativeExpressAdView.alpha = 0.0
        }) { _ in
            self.delegate?.nativeAdCellDidFailToReceiveAd(self)
        }
    }
    
}
