//
//  IndicatorButton.swift
//  Traveli
//
//  Created by GCo iMac on 5/1/19.
//  Copyright © 2019 GCo. All rights reserved.
//

import UIKit

class IndicatorButton: UIButton {
    
    var isLoading = false
    var isCancelabel = false
    var damping:CGFloat = 0.7
    private var originFrame = CGRect()
    private var originPosition = CGPoint()
    private var originBackgroundColor = UIColor()
    private var indicator = UIActivityIndicatorView()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        DispatchQueue.main.async {
            self.originFrame = self.bounds
            self.originPosition = self.layer.position
        }
        originBackgroundColor = backgroundColor!
        setupIndicator()
    }
    
    private func setupIndicator() {
        if !subviews.contains(indicator) {
            indicator = UIActivityIndicatorView(frame: frame)
            indicator.isUserInteractionEnabled = false
            indicator.hidesWhenStopped = true
            indicator.style = .white
            addSubview(indicator)
            DispatchQueue.main.async {
                self.indicator.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 45, height: self.frame.height))
            }
            bringSubviewToFront(indicator)
        }
    }
    
    func startLoading(center:CGPoint? = nil) {
        if !isCancelabel {
            isEnabled = false
        }
        if isLoading {
            if isCancelabel {
                stopLoading()
                return
            } else {
                return
            }
        }
        isLoading = true
        originFrame = bounds
        indicator.startAnimating()
        DispatchQueue.main.async {
            self.titleLabel!.alpha = 0
            self.layoutIfNeeded()
        }
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.indicator.layer.position.x = CGPoint.zero.x + self.bounds.width / 2
            self.frame.size.width = self.frame.height
            self.indicator.layer.position.x = self.bounds.width / 2
            if center != nil {
                self.layer.position.x = center!.x
            } else {
                self.layer.position.x = UIScreen.main.bounds.width / 2
            }
            self.layoutIfNeeded()
            self.titleLabel?.alpha = 0
        }) { (finished) in
            UIView.animate(withDuration: 0.2, animations: {
                self.titleLabel?.alpha = 0
            })
        }
    }
    
    func stopLoading(withShake:Bool = false, center:CGPoint? = nil) {
        isEnabled = false
        indicator.stopAnimating()
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.frame.size.width = self.originFrame.width
            if center != nil {
                self.layer.position.x = center!.x
            } else {
                self.layer.position.x = self.originPosition.x
            }
            self.layoutIfNeeded()
        }) { (finished) in
            UIView.animate(withDuration: 0.3, animations: {
                self.titleLabel?.alpha = 1
                self.layoutIfNeeded()
                if withShake {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.backgroundColor = .red
                    }, completion: { (finished) in
                        UIView.animate(withDuration: 0.3, animations: {
                            self.backgroundColor = self.originBackgroundColor
                            self.isEnabled = true
                            self.isLoading = false
                            self.shakeHorizontal()
                        })
                    })
                } else {
                    self.isEnabled = true
                    self.isLoading = false
                }
            })
        }
    }
    
    func setDisable(color: UIColor = .lightGray) {
        isEnabled = false
        UIView.animate(withDuration: 0.3) {
            self.backgroundColor = color
            self.layoutIfNeeded()
        }
    }
    
    func setEnable() {
        isEnabled = true
        UIView.animate(withDuration: 0.3) {
            self.backgroundColor = self.originBackgroundColor
            self.layoutIfNeeded()
        }
    }
}

extension UIView {
    
    func shakeHorizontal() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [0.8,-0.8, 15, -15, 20, -20, 15, -15, 8, -8]
        self.layer.add(animation, forKey: "shake")
    }
}
