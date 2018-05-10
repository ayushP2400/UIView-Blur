//
//  UIView+Blur.swift
//  Blur
//
//  Created by Nikolay Khramchenko on 10/20/17.
//  Copyright © 2017 NX. All rights reserved.
//
import UIKit

extension UIView {
    
    private struct AssociatedKeys {
        static var descriptiveName = "AssociatedKeys.DescriptiveName.blurView"
    }
    
    private (set) var blurView: BlurView {
        get {
            if let blurView = objc_getAssociatedObject(
                self,
                &AssociatedKeys.descriptiveName
                ) as? BlurView {
                return blurView
            }
            self.blurView = BlurView(to: self)
            return self.blurView
        }
        set(blurView) {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.descriptiveName,
                blurView,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    class BlurView {
        
        private var superview: UIView
        private var blur: UIVisualEffectView?
        private var editing: Bool = false
        private (set) var blurContentView: UIView?
        
        var animationDuration: TimeInterval = 0.1
        
        /**
         * Blur style. After it is changed all subviews on
         * blurContentView & vibrancyContentView will be deleted.
         */
        ///Call this method when trying to preset a blur value in viewdidload
        public func SecondaryInit(lvl:CGFloat){
            DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
                self.intensity = 0
                self.intensity = lvl
            })
        }
        
        var style: UIBlurEffectStyle = .light {
            didSet {
                guard oldValue != style,
                    !editing else { return }
                applyBlurEffect()
            }
        }
        /**
         * Alpha component of view. It can be changed freely.
         */
        var intensity: CGFloat = 0 {
            didSet {
                guard !editing else { return }
                if blur == nil {
                    applyBlurEffect()
                }
                let intensity = self.intensity
                DispatchQueue.main.async {
                    self.blur?.layer.timeOffset = CFTimeInterval(intensity);
                }
            }
        }
        
        init(to view: UIView) {
            self.superview = view
        }
        
        func setup(style: UIBlurEffectStyle, intensity: CGFloat) -> Self {
            NotificationCenter.default.addObserver(self, selector: #selector(BlurView.applicationDidEnterBackground(_:)), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(BlurView.applicationWillEnterForeground(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
            
            self.editing = true
            
            self.style = style
            self.intensity = intensity
            
            self.editing = false
            
            return self
        }
        
        @objc func applicationDidEnterBackground(_ notification: Notification) {
            blur?.removeFromSuperview();
        }
        
        @objc func applicationWillEnterForeground(_ notification: Notification) {
            applyBlurEffect();
        }
        
        func enable(isHidden: Bool = false) {
            if blur == nil {
                applyBlurEffect()
            }
            
            self.blur?.isHidden = isHidden
        }
        
        private func applyBlurEffect() {
            blur?.removeFromSuperview()
            
            applyBlurEffect(
                style: style,
                intensity: intensity
            )
        }
        
        private func applyBlurEffect(style: UIBlurEffectStyle,
                                     intensity: CGFloat) {
            
            
            self.superview.backgroundColor = UIColor.clear
            
            let blurEffectStart: UIBlurEffect! = nil
            let blurEffectEnd = UIBlurEffect(style: style)
            
            let blurEffectView = UIVisualEffectView(effect: blurEffectStart)
            self.superview.insertSubview(blurEffectView, at: 0)
            
            blurEffectView.addAlignedConstrains()
            
            self.blur = blurEffectView
            self.blurContentView = blurEffectView.contentView
            
            blurEffectView.layer.speed = 0;
            
            UIView.animate(withDuration: 1) {
                blurEffectView.effect = blurEffectEnd
            }
            DispatchQueue.main.async {
                blurEffectView.layer.timeOffset = CFTimeInterval(intensity);
            }
            
        }
    }
    
    private func addAlignedConstrains() {
        translatesAutoresizingMaskIntoConstraints = false
        addAlignConstraintToSuperview(attribute: NSLayoutAttribute.top)
        addAlignConstraintToSuperview(attribute: NSLayoutAttribute.leading)
        addAlignConstraintToSuperview(attribute: NSLayoutAttribute.trailing)
        addAlignConstraintToSuperview(attribute: NSLayoutAttribute.bottom)
    }
    
    private func addAlignConstraintToSuperview(attribute: NSLayoutAttribute) {
        superview?.addConstraint(
            NSLayoutConstraint(
                item: self,
                attribute: attribute,
                relatedBy: NSLayoutRelation.equal,
                toItem: superview,
                attribute: attribute,
                multiplier: 1,
                constant: 0
            )
        )
    }
}

