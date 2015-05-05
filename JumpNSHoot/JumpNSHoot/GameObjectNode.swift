//
//  GameObjectNode.swift
//  JumpNSHoot
//
//  Created by Ian Mitchell on 4/15/15.
//  Copyright (c) 2015 Ian Mitchell. All rights reserved.
//

import SpriteKit

enum StarType: Int {
    case Normal = 0
    case Special
}

enum PlatformType: Int {
    case Normal = 0
    case Break
}

enum MonsterType: Int {
    case Slow = 0
    case Fast
}

struct CollisionCategoryBitmask {
    static let Player: UInt32 = 0b00
    static let Star: UInt32 = 0b01
    static let Platform: UInt32 = 0b10
    static let Bullet: UInt32 = 0b100
    static let Monster: UInt32 = 0b1000
}

class GameObjectNode: SKNode {
    

    
    func collisionWithPlayer(player: SKNode) -> Bool {
        return false
    }
    
    func checkNodeRemoval(playerY: CGFloat) -> Bool{
        if playerY > self.position.y + 400.0 {
            self.removeFromParent()
            return true
        }
        return false
    }
    
    func collisionWithBullet() -> Bool {
        return false
    }
}

class StarNode: GameObjectNode {
    
    let starSound = SKAction.playSoundFileNamed("StarPing.wav", waitForCompletion: false)
    
    var starType: StarType!
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: 400.0)
        
        GameState.sharedInstance.score += (starType == .Normal ? 20 : 100)
        GameState.sharedInstance.stars += (starType == .Normal ? 1 : 5)

        runAction(starSound, completion: {
            self.removeFromParent()
        })

        return true
    }
}

class PlatformNode: GameObjectNode {
    
    var platformType: PlatformType!
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        
        if player.physicsBody?.velocity.dy < 0 {
            player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: 250.0)
            
            if platformType == .Break && player.physicsBody?.categoryBitMask == CollisionCategoryBitmask.Player {
                self.removeFromParent()
            }
        }
        return false
    }
}

class MonsterNode: GameObjectNode {
    
    var monsterType: MonsterType!
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        return false
    }

    override func collisionWithBullet() -> Bool {
        
        GameState.sharedInstance.score += (monsterType == .Slow ? 50 : 100)
        self.removeFromParent()
        return true
    }
}