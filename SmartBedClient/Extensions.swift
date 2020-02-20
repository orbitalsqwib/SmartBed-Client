//
//  Extensions.swift
//  TagCashier
//
//  Created by Eugene L. on 15/1/20.
//  Copyright © 2020 ARandomDeveloper. All rights reserved.
//

import UIKit
import Firebase

extension UIView {

    func dropShadow(radius: Int, widthOffset: Int, heightOffset: Int) {
        
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.25
        self.layer.shadowOffset = CGSize(width: widthOffset, height: heightOffset)
        self.layer.shadowRadius = CGFloat(radius)
        //self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale

    }
    
    func constraint(withIdentifier: String) -> NSLayoutConstraint? {
        return self.constraints.filter { $0.identifier == withIdentifier }.first
    }
    
    // From Robin Vinod 23/11/19, YouthHacks
    func addGradientBackground(firstColor: UIColor, secondColor: UIColor, width: Double, height: Double){
        clipsToBounds = true
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [firstColor.cgColor, secondColor.cgColor]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: width, height: height)
        
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.35)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        
        self.layer.insertSublayer(gradientLayer, at: 0)
    }
    
}

extension UIViewController {
    
    func presentSimpleAlert(title: String, message: String, btnMsg: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                   alert.addAction(.init(title: btnMsg, style: .cancel, handler: nil))
                   self.present(alert, animated: true, completion: nil)
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print(signOutError)
        }
    }
    
}
