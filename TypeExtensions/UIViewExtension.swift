//
//  Extensions.swift
//  Messenger
//
//  Created by Yasmine Ashraf on 16/08/2021.
//

import UIKit

extension UIView{
    public var width:CGFloat{
        return frame.size.width
    }
    public var height:CGFloat{
        return frame.size.height
    }
    public var top:CGFloat{
        return frame.origin.y
    }
    public var bottom:CGFloat{
        return frame.size.height + frame.origin.y
    }
    public var left:CGFloat{
        return frame.origin.x
    }
    public var right:CGFloat{
        return frame.size.width + frame.origin.x
    }
}
