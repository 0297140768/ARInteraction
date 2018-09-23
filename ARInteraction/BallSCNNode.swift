//
//  BallSCNNode.swift
//  ARInteraction
//
//  Created by Татьяна on 23.09.2018.
//  Copyright © 2018 Татьяна. All rights reserved.
//

import Foundation
import ARKit

class BallSCNNode: SCNNode {
    var isGoal: Bool = false
    
    override init() {
        super.init()
        self.geometry = SCNSphere(radius: 0.25)
        self.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/ball.tga") //UIColor.orange
        self.name = "ball"
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
