//
//  UIImage+Resize.swift
//  BlockchainMoviesApp
//
//  Created by Nick Nameless on 4/9/24.
//

import UIKit

extension UIImage {
    
    func resize(_ size: CGSize) -> UIImage? {
        if size.width > 0 && self.size.width > 0 && size.height > 0 && self.size.height > 0 {
            UIGraphicsBeginImageContext(CGSize(width: size.width, height: size.height))
            draw(in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext();
            return result;
        }
        return nil
    }
    
    func resizeAspectFill(_ size: CGSize) -> UIImage? {
        if size.width > 0 && self.size.width > 0 && size.height > 0 && self.size.height > 0 {
            UIGraphicsBeginImageContext(CGSize(width: size.width, height: size.height))
            
            let aspect = size.getAspectFill(self.size)
            
            let rect = CGRect(x: size.width * 0.5 - aspect.size.width * 0.5,
                              y: size.height * 0.5 - aspect.size.height * 0.5,
                              width: aspect.size.width,
                              height: aspect.size.height)
            draw(in: rect)
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext();
            return result;
        }
        return nil
    }
    
    func resizeAspectFit(_ size: CGSize) -> UIImage? {
        if size.width > 0 && self.size.width > 0 && size.height > 0 && self.size.height > 0 {
            UIGraphicsBeginImageContext(CGSize(width: size.width, height: size.height))
            
            let aspect = size.getAspectFit(self.size)
            
            let rect = CGRect(x: size.width * 0.5 - aspect.size.width * 0.5,
                              y: size.height * 0.5 - aspect.size.height * 0.5,
                              width: aspect.size.width,
                              height: aspect.size.height)
            draw(in: rect)
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext();
            return result;
        }
        return nil
    }
    
    
}
