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
    static let Player: UInt32 = 0x00
    static let Star: UInt32 = 0x01
    static let Platform: UInt32 = 0x02
    static let Bullet: UInt32 = 0x04
    static let Monster: UInt32 = 0x16
}

class GameObjectNode: SKNode {
    

    
    func collisionWithPlayer(player: SKNode) -> Bool {
        return false
    }
    
    func checkNodeRemoval(playerY: CGFloat) {
        if playerY > self.position.y + 400.0 {
            self.removeFromParent()
        }
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
        
        runAction(starSound, completion: {
            self.removeFromParent()
            })
        GameState.sharedInstance.score += (starType == .Normal ? 20 : 100)
        GameState.sharedInstance.stars += (starType == .Normal ? 1 : 5)
        return true
    }
}

class PlatformNode: GameObjectNode {
    
    var platformType: PlatformType!
    
    override func collisionWithPlayer(player: SKNode) -> Bool {
        
        if player.physicsBody?.velocity.dy < 0 {
            player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: 250.0)
            
            if platformType == .Break {
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
    
    override func checkNodeRemoval(playerY: CGFloat) {
        
        if  (playerY > self.position.y + 400.0){
            self.removeFromParent()
        }
 /*
        if self.position.x + 45 < 0 {
            self.removeFromParent()
        }
        
        if self.position.x - 40 > 320 {
            self.removeFromParent()
        }*/
    }
    
    override func collisionWithBullet() -> Bool {
        
        self.removeFromParent()

        //GameState.sharedInstance.score += (monsterType == .Slow ? 20 : 100)
        return true
    }
}