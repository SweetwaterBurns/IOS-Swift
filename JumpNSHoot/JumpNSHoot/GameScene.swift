//
//  GameScene.swift
//  JumpNSHoot
//
//  Created by Ian Mitchell on 4/15/15.
//  Copyright (c) 2015 Ian Mitchell. All rights reserved.
//

import SpriteKit
import CoreMotion

var levelPlist = NSBundle.mainBundle().pathForResource("Level01", ofType: "plist")
var levelData = NSDictionary(contentsOfFile: levelPlist!)!
//var endLevelY = 0
// Load the level
var endLevelY = levelData["EndY"]!.integerValue!
let motionManager = CMMotionManager()

class GameScene: SKScene, SKPhysicsContactDelegate {

    var backgroundNode = SKNode()
    var midgroundNode = SKNode()
    var foregroundNode = SKNode()
    var hudNode = SKNode()
    var player = SKNode()
    let tapToStartNode = SKSpriteNode(imageNamed: "TapToStart")
    var scaleFactor: CGFloat = 0.0
    var xAcceleration: CGFloat = 0.0


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor.whiteColor()
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.0)
        physicsWorld.contactDelegate = self
        
        scaleFactor = self.size.width / 320.0
        
        backgroundNode = createBackgroundNode()
        addChild(backgroundNode)
        
        midgroundNode = createMidGroundNode()
        addChild(midgroundNode)
        foregroundNode = SKNode()
        addChild(foregroundNode)
        
        let stars = levelData["Stars"] as! NSDictionary
        let starPatterns = stars["Patterns"] as! NSDictionary
        let starPositions = stars["Positions"] as! [NSDictionary]
        
        for starPosition in starPositions {
            let patternX = starPosition["x"]?.floatValue
            let patternY = starPosition["y"]?.floatValue
            let pattern = starPosition["pattern"] as! NSString
            
            // Look up the pattern
            let starPattern = starPatterns[pattern] as! [NSDictionary]
            for starPoint in starPattern {
                let x = starPoint["x"]?.floatValue
                let y = starPoint["y"]?.floatValue
                let type = StarType(rawValue: starPoint["type"]!.integerValue)
                let positionX = CGFloat(x! + patternX!)
                let positionY = CGFloat(y! + patternY!)
                let starNode = createStarAtPosition(CGPoint(x: positionX, y: positionY), ofType: type!)
                foregroundNode.addChild(starNode)
            }
        }
        
        let platforms = levelData["Platforms"] as! NSDictionary
        let platformPatterns = platforms["Patterns"] as! NSDictionary
        let platformPositions = platforms["Positions"] as! [NSDictionary]
        
        for platformPosition in platformPositions {
            let patternX = platformPosition["x"]?.floatValue
            let patternY = platformPosition["y"]?.floatValue
            let pattern = platformPosition["pattern"] as! NSString
            
            // Look up the pattern
            let platformPattern = platformPatterns[pattern] as! [NSDictionary]
            for platformPoint in platformPattern {
                let x = platformPoint["x"]?.floatValue
                let y = platformPoint["y"]?.floatValue
                let type = PlatformType(rawValue: platformPoint["type"]!.integerValue)
                let positionX = CGFloat(x! + patternX!)
                let positionY = CGFloat(y! + patternY!)
                let platformNode = createPlatformAtPosition(CGPoint(x: positionX, y: positionY), ofType: type!)
                foregroundNode.addChild(platformNode)
            }
        }
        
        player = createPlayer()
        foregroundNode.addChild(player)
        
        hudNode = SKNode()
        addChild(hudNode)
    
        tapToStartNode.position = CGPoint(x: self.size.width / 2, y: 180.0)
        hudNode.addChild(tapToStartNode)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler: {
            (accelerometerData: CMAccelerometerData!, error: NSError!) in
            // 3
            let acceleration = accelerometerData.acceleration
            // 4
            self.xAcceleration = (CGFloat(acceleration.x) * 0.75) + (self.xAcceleration * 0.25)
        })
    }
    
    func createBackgroundNode() -> SKNode {
        let backgroundNode = SKNode()
        let ySpacing = 64.0 * scaleFactor
        
        for index in 0...19 {
            let node = SKSpriteNode(imageNamed:String(format: "Background%02d.png", index + 1))
            node.setScale(scaleFactor)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: self.size.width / 2, y: ySpacing * CGFloat(index))
            backgroundNode.addChild(node)
        }
        return backgroundNode
    }
    
    func createPlayer() -> SKNode {
        let playerNode = SKNode()
        playerNode.position = CGPoint(x: self.size.width / 2, y: 80.0)
        
        let sprite = SKSpriteNode(imageNamed: "Player")
        playerNode.addChild(sprite)
        
        playerNode.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        playerNode.physicsBody?.dynamic = false
        playerNode.physicsBody?.allowsRotation = false
        playerNode.physicsBody?.restitution = 1.0
        playerNode.physicsBody?.friction = 0.0
        playerNode.physicsBody?.angularDamping = 0.0
        playerNode.physicsBody?.linearDamping = 0.0
        
        playerNode.physicsBody?.usesPreciseCollisionDetection = true
        playerNode.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Player
        playerNode.physicsBody?.collisionBitMask = 0
        playerNode.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.Star | CollisionCategoryBitmask.Platform
        
        return playerNode
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        
        if player.physicsBody!.dynamic {
            return
        }
        
        tapToStartNode.removeFromParent()
        
        player.physicsBody?.dynamic = true
        player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 20.0))
    }
    
    func createStarAtPosition(position: CGPoint, ofType type: StarType) -> StarNode  {
        
        let node = StarNode()
        let thePosition = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.position = thePosition
        node.name = "NODE_STAR"
        node.starType = type
        
        var sprite: SKSpriteNode
        if type == .Special {
        sprite = SKSpriteNode(imageNamed: "StarSpecial")
        }else {
            sprite = SKSpriteNode(imageNamed: "Star")
        }
        node.addChild(sprite)
        
        node.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        node.physicsBody?.dynamic = false
        
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Star
        node.physicsBody?.collisionBitMask = 0
        
        return node
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        var updateHUD = false
    
        let whichNode = (contact.bodyA.node != player) ? contact.bodyA.node : contact.bodyB.node
        let other = whichNode as! GameObjectNode
    
        updateHUD = other.collisionWithPlayer(player)
    
        if updateHUD {
        }
    }
    
    func createPlatformAtPosition(position: CGPoint, ofType type: PlatformType) -> PlatformNode {
        let node = PlatformNode()
        let thePosition = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.position = thePosition
        node.name = "NODE_PLATFORM"
        node.platformType = type
        
        var sprite: SKSpriteNode
        if type == .Break {
            sprite = SKSpriteNode(imageNamed: "PlatformBreak")
        } else {
            sprite = SKSpriteNode(imageNamed: "Platform")
        }
        node.addChild(sprite)
        
        node.physicsBody = SKPhysicsBody(rectangleOfSize: sprite.size)
        node.physicsBody?.dynamic = false
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Platform
        node.physicsBody?.collisionBitMask = 0
        
        return node
    }
    
    func createMidGroundNode() -> SKNode {
        let theMidgroundNode = SKNode()
        var anchor: CGPoint!
        var xPosition: CGFloat
        
        for index in 0...9 {
            var spriteName: String
            
            let r = arc4random() % 2
            if r > 0 {
                spriteName = "BranchRight"
                anchor = CGPoint(x: 1.0, y: 0.5)
                xPosition = self.size.width
            } else {
                spriteName = "BranchLeft"
                anchor = CGPoint(x: 0.0, y: 0.5)
                xPosition = 0.0
            }
            
            let branchNode = SKSpriteNode(imageNamed: spriteName)
            branchNode.anchorPoint = anchor
            branchNode.position = CGPoint(x: xPosition, y: 500.0 * CGFloat(index))
            theMidgroundNode.addChild(branchNode)
        }
        return theMidgroundNode
    }
    
    override func update(currentTime: NSTimeInterval) {
        if player.position.y > 200 {
            backgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200)/10))
            midgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200)/4))
            foregroundNode.position = CGPoint(x: 0.0, y: -(player.position.y - 200))
        }
    }
    
    override func didSimulatePhysics() {
        player.physicsBody?.velocity = CGVector(dx: xAcceleration * 400.0, dy: player.physicsBody!.velocity.dy)
        if player.position.x < -20.0 {
            player.position = CGPoint(x: self.size.width + 20.0, y: player.position.y)
        } else if (player.position.x > self.size.width + 20.0) {
            player.position = CGPoint(x: -20.0, y: player.position.y)
        }
    }
}
