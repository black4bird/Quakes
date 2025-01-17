
import UIKit


class RemoveAdsViewController: UIViewController
{

    @IBOutlet weak var removeAdsButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var confetti: SAConfettiView!
    
    private let helper = IAPUtility()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Remove Ads"
        messageLabel.text = ""
        
        if SettingsController.sharedController.hasSupported {
            headerLabel.text = "Thanks for your support ♥️"
            removeAdsButton.hidden = true
            navigationItem.rightBarButtonItem = nil
            confetti.startConfetti()
        }
        else {
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: #selector(RemoveAdsViewController.adRemovalPurchased),
                name: IAPUtility.IAPHelperPurchaseNotification,
                object: nil
            )
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: #selector(RemoveAdsViewController.adRemovalFailed),
                name: IAPUtility.IAPHelperFailedNotification,
                object: nil
            )
            
            removeAdsButton.setTitle("", forState: .Normal)
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .Refresh,
                target: self,
                action: #selector(RemoveAdsViewController.refreshButtonPressed)
            )
            navigationItem.rightBarButtonItem?.enabled = false
            removeAdsButton.enabled = false
            
            loadingActivityIndicator.startAnimating()
            helper.requestProducts { products in
                self.loadingActivityIndicator.stopAnimating()

                if let firstProduct = products?.first where IAPUtility.isRemoveAdsProduct(firstProduct) {
                    let numberFormatter = NSNumberFormatter()
                    numberFormatter.numberStyle = .CurrencyStyle
                    
                    if let formattedNumberString = numberFormatter.stringFromNumber(firstProduct.price) {
                        self.removeAdsButton.titleLabel?.numberOfLines = 0
                        self.removeAdsButton.titleLabel?.textAlignment = .Center
                        
                        self.removeAdsButton.setTitle("\(formattedNumberString)\nRemove Ads", forState: .Normal)
                    }
                    
                    self.navigationItem.rightBarButtonItem?.enabled = true
                    self.removeAdsButton.enabled = true
                }
                else {
                    self.removeAdsButton.setTitle("Network Failure", forState: .Normal)
                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        confetti.stopConfetti()
    }
    
    // MARK: Notifications
    func adRemovalPurchased() {
        headerLabel.text = "Thanks for your support ♥️"
        removeAdsButton.hidden = true
        navigationItem.rightBarButtonItem = nil
        SettingsController.sharedController.hasSupported = true
        confetti.startConfetti()
    }
    
    func adRemovalFailed() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .Refresh,
            target: self,
            action: #selector(RemoveAdsViewController.refreshButtonPressed)
        )
        
        messageLabel.alpha = 1.0
        messageLabel.text = "Ad removal failed."
        
        UIView.animateWithDuration(0.3, delay: 4.0, options: [], animations: {
            self.messageLabel.alpha = 0.0
        }) { _ in
            self.messageLabel.text = ""
        }
    }
    
    // MARK: Actions
    @IBAction func removeAdsButtonPressed(sender: UIButton) {
        helper.purchaseRemoveAds()
    }
    
    func refreshButtonPressed() {
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityView)
        activityView.startAnimating()
        
        helper.restorePurchases()
    }

}
