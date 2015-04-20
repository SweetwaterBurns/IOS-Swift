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

struct CollisionCategoryBitmask {
    static let Player: UInt32 = 0x00
    static let Star: UInt32 = 0x01
    static let Platform: UInt32 = 0x02
}

class GameObjectNode: SKNode {
    

    
    func collisionWithPlayer(player: SKNode) -> Bool {
        return false
    }
    
    func checkNodeRemoval(playerY: CGFloat) {
        if playerY > self.position.y + 300.0 {
            self.removeFromParent()
        }
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