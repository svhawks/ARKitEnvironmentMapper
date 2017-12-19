//
//  ViewController.swift
//  ARKitEnvironmentMapper
//
//  Created by halileohalilei on 12/15/2017.
//  Copyright (c) 2017 halileohalilei. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import MetalKit
import ARKitEnvironmentMapper

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

  @IBOutlet var sceneView: ARSCNView!

  var envMap: UIImage?

  var environmentMapper: ARKitEnvironmentMapper?

  override func viewDidLoad() {
    super.viewDidLoad()

//    envMap = UIImage(named: "room")

    // Set the view's delegate
    sceneView.delegate = self

    // Show statistics such as fps and timing information
    sceneView.showsStatistics = true
    sceneView.session.delegate = self
    sceneView.antialiasingMode = .none

    // Create a new scene
    let scene = SCNScene(named: "art.scnassets/ship.scn")!

    let ship: SCNNode = scene.rootNode.childNode(withName: "ship", recursively: true)!

    let spin = CABasicAnimation(keyPath: "rotation")
    // Use from-to to explicitly make a full rotation around z

    spin.fromValue = NSValue(scnVector4: SCNVector4(x: 0, y: 0, z: 1, w: 0))
    spin.toValue = NSValue(scnVector4: SCNVector4(x: 0, y: 0, z: 1, w: Float(CGFloat(2 * Double.pi))))
    spin.duration = 3
    spin.repeatCount = .infinity
    ship.addAnimation(spin, forKey: "spin around")

    // Set the scene to the view
    sceneView.scene = scene

    environmentMapper = ARKitEnvironmentMapper(withImageName: "room")
//    environmentMapper = ARKitEnvironmentMapper(withMapHeight: 512, withDefaultColor: .red)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // Create a session configuration
    let configuration = ARWorldTrackingConfiguration()


    // Run the view's session
    sceneView.session.run(configuration)
  }
  //
  //  override func viewDidAppear(_ animated: Bool) {
  //    let ship = sceneView.scene.rootNode.childNodes.first
  //    let replicatorConstraint = SCNReplicatorConstraint(target: sceneView.scene.rootNode.childNodes[1])
  //    replicatorConstraint.replicatesScale = false
  //    replicatorConstraint.replicatesPosition = false
  //    ship?.constraints = [replicatorConstraint]
  //  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // Pause the view's session
    sceneView.session.pause()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Release any cached data, images, etc that aren't in use.
  }

  // MARK: - ARSCNViewDelegate

  /*
   // Override to create and configure nodes for anchors added to the view's session.
   func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
   let node = SCNNode()

   return node
   }
   */

  func session(_ session: ARSession, didFailWithError error: Error) {
    // Present an error message to the user

  }

  func sessionWasInterrupted(_ session: ARSession) {
    // Inform the user that the session has been interrupted, for example, by presenting an overlay

  }

  func sessionInterruptionEnded(_ session: ARSession) {
    // Reset tracking and/or remove existing anchors if consistent tracking is required

  }

  func session(_ session: ARSession, didUpdate frame: ARFrame) {
    if let environmentMapper = environmentMapper {
      environmentMapper.updateMap(withFrame: frame)
    }
  }

  @IBAction func applyMap(_ sender: Any) {
    sceneView.scene.lightingEnvironment.contents = environmentMapper?.currentEnvironmentMap(as: .cgImage)
  }

}

