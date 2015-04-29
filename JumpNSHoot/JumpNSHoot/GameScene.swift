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
//var endLevelY = levelData["EndY"]!.integerValue!
let motionManager = CMMotionManager()

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func * (point: CGPoint, scaler: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scaler, y: point.y * scaler)
}

func / (point: CGPoint, scaler: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scaler, y: point.y / scaler)
}

#if !(arch(x86_64) || arch(arm64))
    func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
    }
#endif

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x * x + y * y)
    }
    
    func normalized() -> CGPoint {
        return self / length()
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {

    var scaleFactor: CGFloat = 1.0
    var backgroundNode = SKNode()
    var midgroundNode = SKNode()
    var foregroundNode = SKNode()
    var hudNode = SKNode()
    var player = SKNode()
    let tapToStartNode = SKSpriteNode(imageNamed: "TapToStart")
    var xAcceleration: CGFloat = 0.0
    var lblScore: SKLabelNode!
    var lblStars: SKLabelNode!
    var maxPlayerY: Int!
    var gameOver = false
    var lastBackgroundAdd: CGFloat = 0.00
    var lastMidgroundAdd: CGFloat = 0.00
    var lastPlatformAdd: CGFloat = 30
    var lastStarAdd: CGFloat = 128
    var lastMonsterAdd: CGFloat = 800

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = SKColor.whiteColor()
        maxPlayerY = 80
        GameState.sharedInstance.score = 0
        GameState.sharedInstance.stars = 0
        gameOver = false
        physicsWorld.gravity = CGVector(dx: 0.0, dy: -2.0)
        physicsWorld.contactDelegate = self
        
        scaleFactor = self.size.width / 320.0
        
        backgroundNode = createBackgroundNode()
        addChild(backgroundNode)
        
        midgroundNode = createMidGroundNode()
        addChild(midgroundNode)
        foregroundNode = SKNode()
        addChild(foregroundNode)
        
        createStars(1.0)
        
        createPlatforms(1.0)
        
        foregroundNode.addChild(createStarAtPosition(CGPoint(x: 320 / 2, y: 30), ofType: .Normal))

            
        player = createPlayer()
        foregroundNode.addChild(player)
        
        hudNode = SKNode()
        addChild(hudNode)
    
        tapToStartNode.position = CGPoint(x: self.size.width / 2, y: 180.0)
        hudNode.addChild(tapToStartNode)
        
        let star = SKSpriteNode(imageNamed: "Star")
        star.position = CGPoint(x: 25, y: self.size.height - 30)
        hudNode.addChild(star)
        
        lblStars = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        lblStars.fontSize = 30
        lblStars.fontColor = SKColor.whiteColor()
        lblStars.position = CGPoint(x: 50, y: self.size.height - 40)
        lblStars.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Left
        lblStars.text = String(format: "X %d", GameState.sharedInstance.stars)
        hudNode.addChild(lblStars)
        
        lblScore = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        lblScore.fontSize = 30
        lblScore.fontColor = SKColor.whiteColor()
        lblScore.position = CGPoint(x: self.size.width - 20, y: self.size.height - 40)
        lblScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.Right
        
        lblScore.text = "0"
        hudNode.addChild(lblScore)
        
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
        let ySpacing = 48.0 * scaleFactor
        
        for index in 0...19 {
            let node = SKSpriteNode(imageNamed:String(format: "Background%02d.png", index + 1))
            node.setScale(scaleFactor)
            node.anchorPoint = CGPoint(x: 0.5, y: 0.0)
            node.position = CGPoint(x: self.size.width / 2, y: lastBackgroundAdd + (ySpacing * CGFloat(index)))
            backgroundNode.addChild(node)
        }
        
        lastBackgroundAdd = lastBackgroundAdd + (ySpacing * CGFloat(19))
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
        playerNode.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.Star | CollisionCategoryBitmask.Platform | CollisionCategoryBitmask.Monster
        
        return playerNode
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if player.physicsBody!.dynamic {
       /*     if GameState.sharedInstance.stars > 4 {
                let touch = touches.first as! UITouch
                let touchLocation = touch.locationInNode(self) + CGPoint(x: 0, y: player.position.y - 200)
                println("Touch at x: " + "\(touchLocation.x)" + " y: " + "\(touchLocation.y)")
                createBulletAtLocation(touchLocation)
                GameState.sharedInstance.stars -= 5
                updateHUDnow()
            }
        */    return
        }
        
        tapToStartNode.removeFromParent()
        
        player.physicsBody?.dynamic = true
        player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 20.0))
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        if player.physicsBody!.dynamic {
            if GameState.sharedInstance.stars > 4 {
                let touch = touches.first as! UITouch
                let touchLocation = touch.locationInNode(self) + CGPoint(x: 0, y: player.position.y - 200)
                println("Touch at x: " + "\(touchLocation.x)" + " y: " + "\(touchLocation.y)")
                createBulletAtLocation(touchLocation)
                GameState.sharedInstance.stars -= 5
                updateHUDnow()
            }
        }
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
        
        if lastStarAdd < node.position.y {
            lastStarAdd = node.position.y
        }
        return node
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        println(NSStringFromClass(self.classForCoder) + "." + __FUNCTION__)
        var updateHUD = false
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
            var print = NSStringFromClass(self.classForCoder) + "." + __FUNCTION__ + "bodyA < BodyB"
            print += " firstBody: " + String(firstBody.categoryBitMask) + " secondBody: " + String(secondBody.categoryBitMask)
            println(print)
            //println(NSStringFromClass(self.classForCoder) + "." + __FUNCTION__ + " firstBody: " + firstBody.categoryBitMask + " secondBody: " + secondBody.categoryBitMask)
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
            var print = NSStringFromClass(self.classForCoder) + "." + __FUNCTION__ + "bodyA > BodyB"
            print += " firstBody: " + String(firstBody.categoryBitMask) + " secondBody: " + String(secondBody.categoryBitMask)
            println(print)
        }
        
        if secondBody.categoryBitMask == CollisionCategoryBitmask.Bullet {
            return
        }
        
        if secondBody.categoryBitMask == CollisionCategoryBitmask.Monster {
            println(NSStringFromClass(self.classForCoder) + "." + __FUNCTION__ + " Monster Detected")

            if firstBody.categoryBitMask == CollisionCategoryBitmask.Player {
                println(NSStringFromClass(self.classForCoder) + "." + __FUNCTION__ + " Monster vs Player")
                endGame()
            } else if firstBody.categoryBitMask == CollisionCategoryBitmask.Bullet{
                println(NSStringFromClass(self.classForCoder) + "." + __FUNCTION__ + " Monster vs Bullet")
                let monsterObject = secondBody.node as! MonsterNode
                updateHUD = monsterObject.collisionWithBullet()
                firstBody.node?.removeFromParent()
            }
        } else if firstBody.categoryBitMask == CollisionCategoryBitmask.Player {
            let gameObject = secondBody.node as! GameObjectNode
            updateHUD = gameObject.collisionWithPlayer(player)
         //   let whichNode = (firstBody.node != player) ? firstBody.node : secondBody.node
         //   let other = whichNode as! GameObjectNode
         //   updateHUD = other.collisionWithPlayer(player)
        }

        if updateHUD {
            updateHUDnow()
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
        
        if lastPlatformAdd < node.position.y {
            lastPlatformAdd = node.position.y
        }
        
        return node
    }
    
    func createMidGroundNode() -> SKNode {
        let theMidgroundNode = SKNode()
        var anchor: CGPoint!
        var xPosition: CGFloat
        
        for index in 0...9 {
            var spriteName: String
            
            let r = arc4random() % 3
            switch r {
            case 0:
                spriteName = "Planet01"
                anchor = CGPoint(x: 1.0, y: 0.5)
                xPosition = CGFloat(arc4random() % 320)
            case 1:
                spriteName = "Planet02"
                anchor = CGPoint(x: 1.0, y: 0.5)
                xPosition = CGFloat(arc4random() % 320)
            case 2:
                spriteName = "Planet03"
                anchor = CGPoint(x: 1.0, y: 0.5)
                xPosition = CGFloat(arc4random() % 320)
            default:
                spriteName = "Planet02"
                anchor = CGPoint(x: 1.0, y: 0.5)
                xPosition = CGFloat(arc4random() % 320)
            }
            
            let planetNode = SKSpriteNode(imageNamed: spriteName)
            planetNode.anchorPoint = anchor
            planetNode.position = CGPoint(x: xPosition + 35, y: lastMidgroundAdd + 640 * CGFloat(index))
            
            if planetNode.position.y > lastMidgroundAdd {
                lastMidgroundAdd = planetNode.position.y
            }
            theMidgroundNode.addChild(planetNode)
            
        }
        return theMidgroundNode
    }
    
    override func update(currentTime: NSTimeInterval) {
        if gameOver {
            return
        }
        
        if player.position.y > 200 {
            backgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200)/10))
            midgroundNode.position = CGPoint(x: 0.0, y: -((player.position.y - 200)/4))
            foregroundNode.position = CGPoint(x: 0.0, y: -(player.position.y - 200))
        }
  
        if Int(player.position.y) > maxPlayerY! {
            GameState.sharedInstance.score += Int(player.position.y) - maxPlayerY
            maxPlayerY = Int(player.position.y)
            lblScore.text = String(format: "%d", GameState.sharedInstance.score)
        }
        
        foregroundNode.enumerateChildNodesWithName("NODE_PLATFORM", usingBlock: {
            (node, stop) in
            let platform = node as! PlatformNode
            platform.checkNodeRemoval(self.player.position.y)
        })
    
        foregroundNode.enumerateChildNodesWithName("NODE_STAR", usingBlock: {
            (node, stop) in
            let star = node as! StarNode
            star.checkNodeRemoval(self.player.position.y)
        })
        
        foregroundNode.enumerateChildNodesWithName("NODE_MONSTER", usingBlock: {
            (node, stop) in
            let monster = node as! MonsterNode
            monster.checkNodeRemoval(self.player.position.y)
        })
        
        if CGFloat(maxPlayerY + 640) * scaleFactor > lastMonsterAdd {
            createMonsters(lastMonsterAdd)
        }
        
        if CGFloat(maxPlayerY + 640) * scaleFactor > lastStarAdd {
            createStars(lastStarAdd)
        }
        
        
        if CGFloat(maxPlayerY + 640) * scaleFactor > lastPlatformAdd {
            createPlatforms(lastPlatformAdd)
        }
        
       if CGFloat(maxPlayerY + 640) > lastBackgroundAdd {
            var newBackground = createBackgroundNode()
            backgroundNode.addChild(newBackground)
        }
       
        if CGFloat(maxPlayerY + 640) > lastMidgroundAdd {
            var newMidground = createMidGroundNode()
            midgroundNode.addChild(newMidground)
        }
        
        if Int(player.position.y) < maxPlayerY - 1000 {
            endGame()
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
    
    func endGame() {
        gameOver = true
        GameState.sharedInstance.saveState()
        
        let reveal = SKTransition.fadeWithDuration(0.5)
        let endGameScene = EndGameScene(size: self.size)
        self.view!.presentScene(endGameScene, transition: reveal)
    }
    
    func createStars(basey: CGFloat) {

        var baseyForUse = basey + CGFloat(arc4random() % 64)

        //setup Array for Pattern types
        let starPatternArray = [ "Cross", "DoubleLineLeft", "DoubleLineRight", "Diamond" ]
        
        //Load Dictionary and make shapes accessible
        let stars = levelData["Stars"] as! NSDictionary
        let starPatterns = stars["Patterns"] as! NSDictionary
        
        var index: CGFloat = 1
        let patternX = CGFloat(arc4random() % 200 + 60)
        let patternY = baseyForUse + (CGFloat(arc4random() % 16 + 128) * index)
        let pattern = starPatternArray[Int(arc4random() % 4)]
                
        let starPattern = starPatterns[pattern] as! [NSDictionary]
                
        for starPoint in starPattern {
            let x = starPoint["x"]?.floatValue
            let y = starPoint["y"]?.floatValue
            let type = StarType(rawValue: starPoint["type"]!.integerValue)
            let positionX = CGFloat(x!) + patternX
            let positionY = CGFloat(y!) + patternY
            let starNode = createStarAtPosition(CGPoint(x: positionX, y: positionY), ofType: type!)
            
            if baseyForUse < starNode.position.y {
                baseyForUse = starNode.position.y + CGFloat(arc4random() % 64)
            }
            
            foregroundNode.addChild(starNode)
        }
    }
    
    func createPlatforms(basey: CGFloat) {
        
        var baseyForUse = basey + CGFloat(arc4random() % 64)
        
        //setup Array for Pattern types
        let platformPatternArray = [ "Single", "Double", "DoubleBreak", "Triple" ]
        
        //Load Dictionary and make shapes accessible
        let platforms = levelData["Platforms"] as! NSDictionary
        let platformPatterns = platforms["Patterns"] as! NSDictionary
        
        var index: CGFloat = 1
        let patternX = CGFloat(arc4random() % 200 + 60)
        let patternY = baseyForUse + CGFloat(arc4random() % 16 + 128) * index
        let pattern = platformPatternArray[Int(arc4random() % 4)]
        
        let platformPattern = platformPatterns[pattern] as! [NSDictionary]
        
        for platformPoint in platformPattern {
            let x = platformPoint["x"]?.floatValue
            let y = platformPoint["y"]?.floatValue
            let type = PlatformType(rawValue: platformPoint["type"]!.integerValue)
            let positionX = CGFloat(x!) + patternX
            let positionY = CGFloat(y!) + patternY
            let platformNode = createPlatformAtPosition(CGPoint(x: positionX, y: positionY), ofType: type!)
            
            if baseyForUse < platformNode.position.y {
                baseyForUse = platformNode.position.y + CGFloat(arc4random() % 64)
            }
            
            foregroundNode.addChild(platformNode)
        }
    }
    
    
    func createMonsterAtPosition(position: CGPoint, ofType type: MonsterType) -> SKNode {

        let node = MonsterNode()
        var thePosition = CGPoint(x: position.x * scaleFactor, y: position.y)
        node.position = thePosition
        node.name = "NODE_MONSTER"
        
        let sprite = SKSpriteNode(imageNamed: "Monster")
        
        node.addChild(sprite)

        
        node.physicsBody = SKPhysicsBody(circleOfRadius: sprite.size.width / 2)
        node.physicsBody?.dynamic = false
        node.physicsBody?.allowsRotation = false
        node.physicsBody?.restitution = 1.0
        node.physicsBody?.friction = 0.0
        node.physicsBody?.angularDamping = 0.0
        node.physicsBody?.linearDamping = 0.0
        
        node.physicsBody?.usesPreciseCollisionDetection = true
        node.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Monster
        node.physicsBody?.contactTestBitMask = CollisionCategoryBitmask.Bullet

        if lastMonsterAdd < node.position.y {
            lastMonsterAdd = node.position.y
        }
        
        return node
    }
    
    func createMonsters(basey: CGFloat) {
        var baseyForUse = basey + CGFloat(arc4random() % 320 + 128)
        var type = MonsterType(rawValue: Int(arc4random() % 2))
        let monsterNode = createMonsterAtPosition(CGPoint(x: CGFloat(arc4random() % 320), y: baseyForUse), ofType: type!)
/*
        if baseyForUse < monsterNode.position.y {
            baseyForUse = monsterNode.position.y + CGFloat(arc4random() % 64)
        }
*/
        foregroundNode.addChild(monsterNode)
    }
    
    func createBulletAtLocation(touchLocation: CGPoint) {
        let bullet = SKSpriteNode(imageNamed: "StarSpecial")
        bullet.position = player.position
        let offset = touchLocation - bullet.position
        
        bullet.physicsBody = SKPhysicsBody(circleOfRadius: bullet.size.width / 2)
        bullet.physicsBody?.dynamic = true
        bullet.physicsBody?.collisionBitMask = 0
        bullet.physicsBody?.categoryBitMask = CollisionCategoryBitmask.Bullet
        //bullet.physicsBody?.contactTestBitMask = 0//CollisionCategoryBitmask.Platform | CollisionCategoryBitmask.Star
        bullet.physicsBody?.usesPreciseCollisionDetection = true
        
        foregroundNode.addChild(bullet)
        let direction = offset.normalized()
        let shootAmount = direction * 1000
        let realDest = shootAmount + bullet.position
        let actionMove = SKAction.moveTo(realDest, duration: 1.5)
        let actionMoveDone = SKAction.removeFromParent()
        bullet.runAction(SKAction.sequence([actionMove, actionMoveDone]))
    }
    
    func updateHUDnow() {
        lblStars.text = String(format: "X %d", GameState.sharedInstance.stars)
        lblScore.text = String(format: "%d", GameState.sharedInstance.score)
    }
}