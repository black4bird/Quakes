
import UIKit

class QuakeCell: UITableViewCell
{
    
    static let reuseIdentifier = "QuakeCell"
    static let cellHeight: CGFloat = 85.0
    
    @IBOutlet weak var magnitudeLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var additionalInfoLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var feltLabel: UILabel!
    @IBOutlet weak var colorView: UIView!
    
    var quakeToDisplay: Quake!
    
    func configure(quake: Quake) {
        quakeToDisplay = quake
        
        timestampLabel.text = quake.timestamp.relativeString()
        magnitudeLabel.text = Quake.magnitudeFormatter.stringFromNumber(quake.magnitude)
        
        additionalInfoLabel.text = quake.additionalInfoString
        
        feltLabel.text = quake.felt > 0 ? "\(Int(quake.felt)) felt" : ""
        
        cityLabel.text = quake.name.componentsSeparatedByString(" of ").last!
        
        colorView.backgroundColor = quake.severityColor
        colorView.layer.cornerRadius = 10.0
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        colorView.backgroundColor = quakeToDisplay.severityColor
    }
    
    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        colorView.backgroundColor = quakeToDisplay.severityColor
    }
    
}
