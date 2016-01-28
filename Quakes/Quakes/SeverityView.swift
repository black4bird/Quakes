
import UIKit

class SeverityView: UIView
{

    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let locations: [CGFloat] = [0.0, 0.5, 1.0]
        
        let colors = [
            StyleController.redQuakeColor.CGColor,
            StyleController.orangeQuakeColor.CGColor,
            StyleController.greenQuakeColor.CGColor
        ]
        
        let gradient = CGGradientCreateWithColors(colorSpace, colors, locations)
        CGContextDrawLinearGradient(ctx, gradient, CGPoint(x: CGRectGetWidth(rect), y: 0), CGPointZero, .DrawsAfterEndLocation)
    }

}