//
//  GameScene.swift
//  SpaceShooter
//
//  Created by Foundation-006 on 26/06/24.
//

import SpriteKit
import GameplayKit

var player = SKSpriteNode()
var scoreLabel = SKLabelNode()
var mainLabel = SKLabelNode()
var playerSize = CGSize(width: 170, height: 170)
var projectTileSize = CGSize(width: 26, height: 26)
var enemySize = CGSize(width: 140, height: 140)
var starSize = CGSize()
var star = SKSpriteNode()

var offBlackColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
var offWhiteColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
var OrangeCustorColor = UIColor.orange
var backgroundSprite: SKSpriteNode?
var projectTileRate = 0.2
var projectTileSpeed = 0.9
var shipImages = ["ship.png","ship1.png", "playerShip1_green.png", "playerShip1_orange.png", "playerShip1_red.png", "playerShip2_blue.png", "playerShip2_green.png", "playerShip2_orange.png", "playerShip2_red.png", "playerShip3_blue.png", "playerShip3_green.png", "playerShip3_orange.png", "playerShip3_red.png", "playerShip1_blue.png"]
var enemySpeed = 1.9
var enemySpawnRate = 0.5

var isAlive = true
var score = 0
var currentBackgroundIndex = 0
let backgroundColors = ["blue.png", "black.png", "darkPurple.png", "purple.png"]
var touchLocation = CGPoint()

struct physicsCategory {
    static let player: UInt32 = 0
    static let projectTile: UInt32 = 1
    static let enemy: UInt32 = 2
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var selectedShipIndex: Int = 0

    override func didMove(to view: SKView) {
        // Retrieve selected ship index from UserDefaults
               if let selectedShipIndex = UserDefaults.standard.object(forKey: "selectedShipIndex") as? Int {
                   self.selectedShipIndex = selectedShipIndex
               } else {
                   // Default to index 0 if nothing is saved
                   self.selectedShipIndex = 0
               }
        
        let randomIndex = Int(arc4random_uniform(UInt32(backgroundColors.count)))
        let randomBackgroundImage = backgroundColors[randomIndex]
        let backgroundImage = SKTexture(imageNamed: randomBackgroundImage)
        let backgroundSprite = SKSpriteNode(texture: backgroundImage)
        backgroundSprite.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        backgroundSprite.zPosition = -1 // Ensure it's behind all other nodes
        backgroundSprite.scale(to: self.frame.size) // Scale the sprite to fill the entire scene
        self.addChild(backgroundSprite)

        physicsWorld.contactDelegate = self
            resetGameVariableOnStart()

            leadPlayer(selectedShipIndex: selectedShipIndex)
            spawnMainLabel()
            spawnScoreLabel()
            fireProjectTile()
            timerSpawnEnemies()
            timerSpawnStars()
            changeBackgroundAutomatically()
    }
    
    func changeBackground() {
           guard backgroundColors.count > 1 else { return } // Ensure there are at least 2 backgrounds to switch between

           var newIndex: Int
           repeat {
               newIndex = Int.random(in: 0..<backgroundColors.count)
           } while newIndex == currentBackgroundIndex // Ensure the new index is different from the current one

           currentBackgroundIndex = newIndex // Update the current index

           let newBackgroundImage = SKTexture(imageNamed: backgroundColors[currentBackgroundIndex])
           let newBackgroundSprite = SKSpriteNode(texture: newBackgroundImage)
           newBackgroundSprite.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
           newBackgroundSprite.zPosition = -1 // Ensure it's behind all other nodes
           newBackgroundSprite.size = self.frame.size // Scale the sprite to fill the entire scene

           // Remove the old background if it exists
           backgroundSprite?.removeFromParent()
           
           // Set the new background sprite
           backgroundSprite = newBackgroundSprite
           self.addChild(newBackgroundSprite)
       }

       func changeBackgroundAutomatically() {
           let wait = SKAction.wait(forDuration: 10) // Wait for 10 seconds
           let changeBackgroundAction = SKAction.run { [weak self] in
               self?.changeBackground()
           }
           let sequence = SKAction.sequence([wait, changeBackgroundAction])
           let repeatAction = SKAction.repeatForever(sequence)
           
           self.run(repeatAction) // Run the action on the scene
       }
    func leadPlayer(selectedShipIndex: Int) {
            let shipImageName = shipImages[selectedShipIndex]
            player = SKSpriteNode(imageNamed: shipImageName)
            player.size = playerSize
            player.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 610)

            player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
            player.physicsBody?.affectedByGravity = false
            player.physicsBody?.categoryBitMask = physicsCategory.player
            player.physicsBody?.contactTestBitMask = physicsCategory.enemy
            player.physicsBody?.allowsRotation = false
            player.physicsBody?.isDynamic = false
            player.name = "playerName"
            self.addChild(player)
        }
   
    func resetGameVariableOnStart() {
        // Reset game variables
        isAlive = true
        score = 0
        enemySpeed = 2.0
        enemySpawnRate = 0.5
        
        // Save high score to UserDefaults if it's a new high score
        let currentHighScore = UserDefaults.standard.integer(forKey: "HighScore")
        if score > currentHighScore {
            UserDefaults.standard.set(score, forKey: "HighScore")
            UserDefaults.standard.synchronize() // Ensure it's immediately saved
        }
        
        // Update score label after resetting variables
        updateScore()
    }

    
    func leadProjectTile() {
        let projectTile = SKSpriteNode(imageNamed: "projectile")
        projectTile.size = projectTileSize
        projectTile.position = CGPoint(x: player.position.x, y: player.position.y)
        projectTile.physicsBody = SKPhysicsBody(rectangleOf: projectTile.size)
        projectTile.physicsBody?.affectedByGravity = false
        projectTile.physicsBody?.categoryBitMask = physicsCategory.projectTile
        projectTile.physicsBody?.contactTestBitMask = physicsCategory.enemy
        projectTile.physicsBody?.allowsRotation = false
        projectTile.physicsBody?.isDynamic = true
        projectTile.name = "projectileName"
        projectTile.zPosition = 1

        moveProjectTileToTop(projectTile: projectTile)

        self.addChild(projectTile)
    }

    func moveProjectTileToTop(projectTile: SKSpriteNode) {
        let moveForward = SKAction.moveTo(y: 600, duration: projectTileSpeed)
        let destroy = SKAction.removeFromParent()

        projectTile.run(SKAction.sequence([moveForward, destroy]))
    }

    func spawnEnemy() {
        let enemyImages = [
            "enemyBlack1.png", "enemyBlack2.png", "enemyBlack3.png", "enemyBlack4.png", "enemyBlack5.png",
            "enemyBlue1.png", "enemyBlue2.png", "enemyBlue3.png", "enemyBlue4.png", "enemyBlue5.png",
            "enemyGreen1.png", "enemyGreen2.png", "enemyGreen3.png", "enemyGreen4.png", "enemyGreen5.png",
            "enemyRed1.png", "enemyRed2.png", "enemyRed3.png", "enemyRed4.png", "enemyRed5.png"
        ]
        let randomIndex = Int(arc4random_uniform(UInt32(enemyImages.count)))
        let randomEnemyImage = enemyImages[randomIndex]
        let enemy = SKSpriteNode(imageNamed: randomEnemyImage) // Use random enemy image
        enemy.size = enemySize
        let xPos = randombetweenNumbers(firstNum: 0, secondNum: frame.width)
        enemy.position = CGPoint(x: xPos - 500, y: self.frame.size.height / 2)

        enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
        enemy.physicsBody?.affectedByGravity = false
        enemy.physicsBody?.categoryBitMask = physicsCategory.enemy
        enemy.physicsBody?.contactTestBitMask = physicsCategory.projectTile
        enemy.physicsBody?.allowsRotation = false
        enemy.physicsBody?.isDynamic = true
        enemy.name = "enemyName"

        moveEnemyToFloor(enemy: enemy)
        self.addChild(enemy)
    }

    func randombetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }

    func moveEnemyToFloor(enemy: SKSpriteNode) {
        let moveForward = SKAction.moveTo(y: -820, duration: enemySpeed)
        let destroy = SKAction.removeFromParent()

        enemy.run(SKAction.sequence([moveForward, destroy]))
    }

    func spawnStars() {
        let meteorImages = [
            "meteorBrown_big1.png", "meteorBrown_big2.png", "meteorBrown_big3.png", "meteorBrown_big4.png",
            "meteorBrown_tiny1.png", "meteorBrown_tiny2.png",
            "meteorGrey_big1.png", "meteorGrey_big2.png", "meteorGrey_big3.png", "meteorGrey_big4.png",
            "meteorGrey_med1.png", "meteorGrey_med2.png",
            "meteorGrey_small1.png", "meteorGrey_small2.png",
            "meteorGrey_tiny1.png", "meteorGrey_tiny2.png"
        ]
        let randomSize = Int(arc4random_uniform(15) + 17)
        starSize = CGSize(width: randomSize, height: randomSize)
        let randomIndex = Int(arc4random_uniform(UInt32(meteorImages.count))) // Generate a random index
        let randomMeteorImage = meteorImages[randomIndex] // Use a random meteor image
        star = SKSpriteNode(imageNamed: randomMeteorImage)
        star.size = starSize

        let xPos = randombetweenNumbers(firstNum: 0, secondNum: frame.width)
        star.position = CGPoint(x: (xPos - 500), y: self.frame.size.height / 2)

        startsMove()
        self.addChild(star)
    }

    func startsMove() {
        let randomTime = Int(arc4random_uniform(10))
        let doubleRandomTime = Double((randomTime) / 10) + 1

        let moveForward = SKAction.moveTo(y: -600, duration: doubleRandomTime)
        let destroy = SKAction.removeFromParent()

        star.run(SKAction.sequence([moveForward, destroy]))
    }

    func spawnMainLabel() {
        mainLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        mainLabel.fontSize = 50
        mainLabel.fontColor = offWhiteColor // Ensure offWhiteColor is defined somewhere
        mainLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        mainLabel.text = "START GAME"
        self.addChild(mainLabel)

        let wait = SKAction.wait(forDuration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 0.5) // Fade out over 0.5 seconds
        let remove = SKAction.removeFromParent()
        mainLabel.run(SKAction.sequence([wait, fadeOut, remove]))
    }

    func spawnScoreLabel() {
        // Create a background box for the score label
        let scoreBackground = SKSpriteNode(color: UIColor.black.withAlphaComponent(0.5), size: CGSize(width: 200, height: 80))
        scoreBackground.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 820)
        scoreBackground.zPosition = 10
        self.addChild(scoreBackground)
        
        // Create the score label itself
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 40
        scoreLabel.fontColor = offWhiteColor
        scoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 830)
        scoreLabel.text = "Score: \(score)"
        scoreLabel.zPosition = 11 // Ensure the label is in front of the background
        self.addChild(scoreLabel)
        
        // Ensure the score label updates with the current score
        updateScore()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            touchLocation = touch.location(in: self) // Updated to use the scene's coordinate system
        }
    }

    func movePlayerOnTouch() {
        player.position.x = (touchLocation.x)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            touchLocation = touch.location(in: self) // Updated to use the scene's coordinate system
            movePlayerOnTouch()
        }
    }

    func fireProjectTile() {
        let timer = SKAction.wait(forDuration: projectTileRate)

        let spawn = SKAction.run {
            self.leadProjectTile()
        }

        let sequence = SKAction.sequence([timer, spawn])
        self.run(SKAction.repeatForever(sequence))
    }

    func timerSpawnEnemies() {
        let wait = SKAction.wait(forDuration: enemySpawnRate)
        let spawn = SKAction.run {
            self.spawnEnemy()
        }
        let sequence = SKAction.sequence([wait, spawn])
        self.run(SKAction.repeatForever(sequence))
    }

    func timerSpawnStars() {
        let wait = SKAction.wait(forDuration: 0.2)
        let spawn = SKAction.run {
            if isAlive == true {
                self.spawnStars()
            }
        }
        let sequence = SKAction.sequence([wait, spawn])
        self.run(SKAction.repeatForever(sequence))
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let firstBody = contact.bodyA
        let secondBody = contact.bodyB

        // Check collision between enemy and projectile
        if (firstBody.categoryBitMask == physicsCategory.enemy && secondBody.categoryBitMask == physicsCategory.projectTile) ||
           (firstBody.categoryBitMask == physicsCategory.projectTile && secondBody.categoryBitMask == physicsCategory.enemy) {
            // Handle enemy-projectile collision
            if let enemyNode = firstBody.node as? SKSpriteNode, let projectileNode = secondBody.node as? SKSpriteNode {
                spawnExplosion(bodyTemp: enemyNode)
                enemyProjectileCollision(contactA: enemyNode, contactB: projectileNode) // Corrected typo here
                enemyNode.removeFromParent() // Remove the enemy node
                projectileNode.removeFromParent() // Remove the projectile node
            } else if let enemyNode = secondBody.node as? SKSpriteNode, let projectileNode = firstBody.node as? SKSpriteNode {
                spawnExplosion(bodyTemp: enemyNode)
                enemyProjectileCollision(contactA: enemyNode, contactB: projectileNode) // Handle reverse case
                enemyNode.removeFromParent() // Remove the enemy node
                projectileNode.removeFromParent() // Remove the projectile node
            }
        }

        // Check collision between enemy and player
        if (firstBody.categoryBitMask == physicsCategory.enemy && secondBody.categoryBitMask == physicsCategory.player) ||
           (firstBody.categoryBitMask == physicsCategory.player && secondBody.categoryBitMask == physicsCategory.enemy) {
            // Handle player-enemy collision
            if let playerNode = firstBody.node as? SKSpriteNode, let enemyNode = secondBody.node as? SKSpriteNode {
                playerEnemyCollision(contactA: playerNode, contactB: enemyNode)
                // Optionally, handle player and enemy removal or game over logic here
            } else if let playerNode = secondBody.node as? SKSpriteNode, let enemyNode = firstBody.node as? SKSpriteNode {
                playerEnemyCollision(contactA: playerNode, contactB: enemyNode) // Handle reverse case
                // Optionally, handle player and enemy removal or game over logic here
            }
        }
    }

    func enemyProjectileCollision(contactA: SKSpriteNode, contactB: SKSpriteNode) {
        if contactA.name == "enemyName" && contactB.name == "projectileName" { // Corrected "playerTileName" to "projectileName"
            score += 2

            let destroy = SKAction.removeFromParent()

            contactA.run(destroy)
            contactB.removeFromParent()
            updateScore()
        }
    }

    func playerEnemyCollision(contactA: SKSpriteNode, contactB: SKSpriteNode) {
        if contactA.name == "playerName" && contactB.name == "enemyName" {
            isAlive = false
            gameOverLogic()
        }
    }
    func gameOverLogic() {
        let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        gameOverLabel.fontSize = 90
        gameOverLabel.fontColor = SKColor.red
        gameOverLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.name = "gameOverLabel"
        self.addChild(gameOverLabel)
        
        // Optional: Add fade-out effect after a few seconds
        let wait = SKAction.wait(forDuration: 2.0) // Wait for 2 seconds
        let fadeOut = SKAction.fadeOut(withDuration: 1.0) // Fade out effect for 1 second
        let remove = SKAction.removeFromParent() // Remove from parent
        let sequence = SKAction.sequence([wait, fadeOut, remove])
        
        
        gameOverLabel.run(sequence) { [weak self] in
            self?.resetGameVariableOnStart() // Reset game variables after showing "GAME OVER"
            self?.resetTheGame() // Reset the game logic after showing "GAME OVER"
        }
    }
    func resetTheGame() {
        let wait = SKAction.wait(forDuration: 1.3)
        let titleScene = TitleScene(fileNamed: "TitleScene")
        titleScene?.scaleMode = SKSceneScaleMode.aspectFill
        let transition = SKTransition.fade(withDuration: 0.4)
        
        let changeScene = SKAction.run {
            self.scene!.view?.presentScene(titleScene!, transition: transition)
        }
        
        let sequence = SKAction.sequence([wait, changeScene])
        self.run(SKAction.repeat(sequence, count: 1))
        
        
        // Reset game variables
        resetGameVariableOnStart()
    }


    func updateScore() {
        score += 1 // Assuming you want to increment the score by 1
        scoreLabel.text = "Score: \(score)"
        
        // Check and update high score
        let highScore = UserDefaults.standard.integer(forKey: "highScore")
        if score > highScore {
            UserDefaults.standard.set(score, forKey: "highScore")
        }
        
        // Increase difficulty every 20 points
        if score % 20 == 0 {
            // Increase enemy speed by decreasing the delay between movements
            enemySpeed -= 0.05 // Example decrement, adjust based on gameplay balance
            
            // Increase enemy spawn rate by decreasing the delay between spawns
            enemySpawnRate -= 0.05 // Example decrement, adjust based on gameplay balance
            
        }
    }

   
    func spawnExplosion(bodyTemp: SKSpriteNode) {
        let explosionEmitterPath = Bundle.main.path(forResource: "ExplosionParticle", ofType: "sks")
        let explosion = NSKeyedUnarchiver.unarchiveObject(withFile: explosionEmitterPath!) as! SKEmitterNode
        explosion.position = CGPoint(x: bodyTemp.position.x, y: bodyTemp.position.y)
        explosion.zPosition = 1
        explosion.targetNode = self
        self.addChild(explosion)

        let wait = SKAction.wait(forDuration: 0.3)
        let removeExplosion = SKAction.run {
            explosion.removeFromParent()
        }

        self.run(SKAction.sequence([wait, removeExplosion]))
    }

    func movePlayerOffScreen() {
        player.removeFromParent() // Correctly remove the player
        player.removeAllActions() // Remove all actions
        spawnExplosion(bodyTemp: player)
    }


    override func update(_ currentTime: TimeInterval) {
        if isAlive == false {
            movePlayerOffScreen()
            
        }
    }
}
