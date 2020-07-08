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
    var isCancelabel = true
    var damping:CGFloat = 0.7
    private var originalTitle = ""
    private var originalImage: UIImage?
    private var originFrame = CGRect()
    private var originPosition = CGPoint()
    private var originBackgroundColor = UIColor()
    private var indicator = UIActivityIndicatorView()
    private var latestShowedProgress = 0
    private var latestOrderedProgress = 0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.3) {
            self.layer.transform = CATransform3DScale(CATransform3DIdentity, 0.95, 0.95, 1.2)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.3) {
            self.layer.transform = CATransform3DScale(CATransform3DIdentity, 1, 1, 1)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        DispatchQueue.main.async {
            self.originFrame = self.bounds
            self.originPosition = self.layer.position
        }
        if let color = backgroundColor {
            originBackgroundColor = color
        }
        setupIndicator()
        titleLabel!.font = UIFont(name: Strings.get.fontNameBold, size: Sizes.get.largeFontSize)
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
    
    func setProgress(value:Int) {
        saveOriginalTitle()
        hideIndicator()
        latestOrderedProgress = value
        if latestOrderedProgress > latestShowedProgress {
            latestShowedProgress += 1
            increaseProgress()
        } else if latestOrderedProgress == 100 {
            hideIndicator()
        } else {
            setTitle(latestShowedProgress.description + "%", for: .normal)
        }
    }
    
    func increaseProgress() {
        latestShowedProgress += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if self.latestShowedProgress < 100 && self.latestShowedProgress < self.latestOrderedProgress {
                self.setTitle(self.latestShowedProgress.description + "%", for: .normal)
                self.increaseProgress()
            } else {
                self.showIndicator()
            }
        }
    }
    
    func hideIndicator() {
        indicator.isHidden = true
        titleLabel?.alpha = 1
        if latestOrderedProgress == 100 {
            setTitle(originalTitle, for: .normal)
        }
    }
    
    func showIndicator() {
        indicator.isHidden = false
        indicator.startAnimating()
        titleLabel?.alpha = 0
    }
    
    func saveOriginalTitle() {
        if let title = titleLabel?.text {
            if !title.contains("%") {
                originalTitle = title
            }
        }
    }
    
    func startLoading(center:CGPoint? = nil, fixConstraintsIssue:Bool = false) {
        saveDefaultImage()
        if !self.isCancelabel {
            self.isEnabled = false
        }
        if self.isLoading {
            if self.isCancelabel {
                self.stopLoading()
                return
            } else {
                return
            }
        }
        self.isLoading = true
        self.originFrame = self.bounds
        self.indicator.startAnimating()
        DispatchQueue.main.async {
            self.titleLabel!.alpha = 0
            self.layoutIfNeeded()
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: self.damping, initialSpringVelocity: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: { [unowned self] in
                self.frame.size.width = self.bounds.height
                self.indicator.layer.position.x = self.bounds.width / 2
                if center != nil {
                    self.layer.position.x = center!.x
                } else {
                    self.layer.position.x = UIScreen.main.bounds.width / 2
                }
                if fixConstraintsIssue {
                    self.translatesAutoresizingMaskIntoConstraints = true // this guy ruines othe controllers constraints | uncomment will cause issue on sumbitOrderController
                }
                print("indicatorButton.frame.size.width: \(self.frame.size.width)")
                self.titleLabel?.alpha = 0
                self.layoutIfNeeded()
            })
        }
    }
    
    func stopLoading(withShake:Bool = false, center:CGPoint? = nil, stopImage:UIImage? = nil, comple: (() -> Void)? = nil) {
        isEnabled = false
        if let image = stopImage {
            originalImage = image
        }
        indicator.stopAnimating()
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: 0, options: .curveEaseInOut, animations: { [unowned self] in
            self.frame.size.width = self.originFrame.width
            if center != nil {
                self.layer.position.x = center!.x
            } else {
                self.layer.position.x = self.originPosition.x
            }
            self.layoutIfNeeded()
        }) { (finished) in
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                self?.titleLabel?.alpha = 1
                self?.layoutIfNeeded()
                self?.setDefaultImage()
                if withShake {
                    UIView.animate(withDuration: 0.3, animations: {
                        self?.backgroundColor = .red
                    }, completion: { (finished) in
                        UIView.animate(withDuration: 0.3, animations: {
                            self?.backgroundColor = self?.originBackgroundColor
                            self?.isEnabled = true
                            self?.isLoading = false
                            self?.shakeHorizontal()
                        })
                    })
                } else {
                    self?.isEnabled = true
                    self?.isLoading = false
                }
            }) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    comple?()
                }
            }
        }
    }
    
    func shakeHorizontal() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [0.8,-0.8, 15, -15, 20, -20, 15, -15, 8, -8]
        self.layer.add(animation, forKey: "shake")
    }
    
    func setDisable(color: UIColor = .lightGray) {
        isEnabled = false
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.backgroundColor = color
            self?.layoutIfNeeded()
        }
    }
    
    func setEnable() {
        isEnabled = true
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.backgroundColor = self?.originBackgroundColor
            self?.layoutIfNeeded()
        }
    }
    
    private func saveDefaultImage() {
        if let image = image(for: .normal) {
            originalImage = image
            setImage(UIImage(), for: .normal)
        }
    }
    
    private func setDefaultImage() {
        if let image = originalImage {
            setImage(image, for: .normal)
        }
    }
}
