//
//  UIStoryboard+Extensions.swift
//  RemoveSimilarImages
//
//  Created by YupinHuPro on 3/8/19.
//  Copyright © 2019 Apple. All rights reserved.
//

import UIKit

extension UIStoryboard {
    
    enum InstantiationSource {
        case initial
        case identifier(String)
    }
    
    static func instantiateViewController<ViewController: UIViewController>(
        of type: ViewController.Type,
        withName name: String = String(describing: ViewController.self),
        source: InstantiationSource = .initial
        ) -> ViewController {
        
        let bundle = Bundle(for: ViewController.self)
        let storyboard = UIStoryboard(name: name, bundle: bundle)
        
        let vc: UIViewController?
        
        switch source {
        case .initial:
            vc = storyboard.instantiateInitialViewController()
        case .identifier(let identifier):
            vc = storyboard.instantiateViewController(withIdentifier: identifier)
        }
        
        guard let viewController = vc as? ViewController else {
            fatalError("Could not find the specified view controller in the storyboard.")
        }
        
        return viewController
    }
}

