//
//  ViewController.swift
//  ARInteraction
//
//  Created by Татьяна on 22.09.2018.
//  Copyright © 2018 Татьяна. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var scoreLabel: UILabel!
    var hoopAdded = false
    
    var tourusNode: SCNNode?
    
    var score:Int = 0 {
        didSet {
            self.scoreLabel.text = "SCORE \(score)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        if !hoopAdded {
            let touchLocation = sender.location(in: sceneView)
            
            let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
            
            if let result = hitTestResult.first {
                addHoop(result: result)
                hoopAdded = true
                removeWalls()
                sceneView.session.pause()
                let configuration = ARWorldTrackingConfiguration()
                sceneView.session.run(configuration)
            }
        } else {
            createBasketBall()
        }
    }
    
    func addHoop(result: ARHitTestResult) {
        let hoopScene = SCNScene(named: "art.scnassets/Hoop.scn")!
        
        guard let hoopNode = hoopScene.rootNode.childNode(withName: "Hoop", recursively: false) else {
            return
        }
        
        hoopNode.simdTransform = result.worldTransform
        hoopNode.eulerAngles.x -= Float.pi / 2
        
        hoopNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: hoopNode,
                               options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        sceneView.scene.rootNode.addChildNode(hoopNode)
        tourusNode = sceneView.scene.rootNode.childNode(withName: "torus", recursively: true)
    }
    
    func createWall(planeAnchor: ARPlaneAnchor) -> SCNNode {
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        
        let geometry = SCNPlane(width: width, height: height)
        
        let node = SCNNode()
        node.geometry = geometry
        
        node.eulerAngles.x = -Float.pi / 2
        node.opacity = 0.25
        
        node.name = "wall"
        
        return node
    }
    
    func removeWalls() {
        
        let wallNodes = sceneView.scene.rootNode.childNodes(passingTest: isWallNode)
        for wallNode in wallNodes {
            wallNode.removeFromParentNode()
        }
    }
    
    func isWallNode(_ node: SCNNode, _ i: UnsafeMutablePointer<ObjCBool>) -> Bool {
        return node.name == "wall" ? true : false
    }

    func createBasketBall() {
        guard let frame = sceneView.session.currentFrame else {
            return
        }
        
        let ball = BallSCNNode()
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball, options: [SCNPhysicsShape.Option.collisionMargin: 0.01]))
        ball.physicsBody = physicsBody
        
        let transform = SCNMatrix4(frame.camera.transform)
        ball.transform = transform
        ball.eulerAngles.y += Float.pi/2
        
        let power = Float(10)
        let force = SCNVector3(-transform.m31 * power, -transform.m32 * power, -transform.m33 * power)

        ball.physicsBody?.applyForce(force, asImpulse: true)
        
        sceneView.scene.rootNode.addChildNode(ball)
        
    }
    
    func checkBalls() {
        
        let ballNodes = sceneView.scene.rootNode.childNodes(passingTest: isBallNode)
        for ballNode in ballNodes {
            checkGoal(forBall: ballNode as! BallSCNNode)
            removeDistantBall(ballNode: ballNode as! BallSCNNode)
        }
    }
    
    func removeDistantBall(ballNode: BallSCNNode) {
        
        guard let frame = sceneView.session.currentFrame else { return }
        
        let maxDistance: Float = 10
        
        let cameraPosition = SCNMatrix4(frame.camera.transform)
        
        let ballPosition = ballNode.presentation.position
        let vector = SCNVector3Make(cameraPosition.m41 - ballPosition.x, cameraPosition.m42 - ballPosition.y, cameraPosition.m43 - ballPosition.z)
        let distance = sqrtf(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        if distance > maxDistance {
            ballNode.removeFromParentNode()
        }
    }
    
    
    func isBallNode(_ node: SCNNode, _ i: UnsafeMutablePointer<ObjCBool>) -> Bool {
        return (node is BallSCNNode) ? true : false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        let wall = createWall(planeAnchor: planeAnchor)
        node.addChildNode(wall)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let wall = node.childNodes.first,
            let geometry = wall.geometry as? SCNPlane else {
                return
        }
        
        geometry.width = CGFloat(planeAnchor.extent.x)
        geometry.height = CGFloat(planeAnchor.extent.z)
        
        wall.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        checkBalls()
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    func checkGoal(forBall ballNode: BallSCNNode) {
        guard let tourus = tourusNode else { return }
        guard !ballNode.isGoal else { return }
        
        let tourusPosition = tourus.worldPosition
        let ballPosition = ballNode.presentation.position
        let vector = SCNVector3Make(tourusPosition.x - ballPosition.x, tourusPosition.y - ballPosition.y, tourusPosition.z - ballPosition.z)
        let distance = sqrtf(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
        if distance <= 0.19 {
            score += 1
            ballNode.isGoal = true
        }
        
    }
    
    
    
}
