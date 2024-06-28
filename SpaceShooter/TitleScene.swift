import UIKit
import SpriteKit

class TitleScene: SKScene {
    
    var buttonPlay: UIButton!
    var buttonExit: UIButton!
    var highScoreLabel: UILabel!
    var shipDisplay: UIImageView!
    let background1 = SKSpriteNode(imageNamed: "landing.jpeg")

    let background2 = SKSpriteNode(imageNamed: "landing.jpeg")

    var shipImages = ["ship.png","ship1.png", "playerShip1_green.png", "playerShip1_orange.png", "playerShip1_red.png", "playerShip2_blue.png", "playerShip2_green.png", "playerShip2_orange.png", "playerShip2_red.png", "playerShip3_blue.png", "playerShip3_green.png", "playerShip3_orange.png", "playerShip3_red.png", "playerShip1_blue.png"]
    var currentShipIndex = 0
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
               
               // Add background
               background1.zPosition = -1 // Ensure it's behind other nodes
               background1.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
               background1.size = CGSize(width: self.frame.width, height: self.frame.height * 1.1)
               self.addChild(background1)
               
               background2.zPosition = -2
               background2.position = CGPoint(x: background1.position.x, y: background1.position.y + background1.size.height)
               self.addChild(background2)
               
               // Set background color (assuming offBlackColor is defined elsewhere)
               self.backgroundColor = .black

        // Add logo
        let logo = SKSpriteNode(imageNamed: "logo.png")
        logo.position = CGPoint(x: self.frame.midX, y: self.frame.maxY - 190)
        logo.setScale(0.5)
        self.addChild(logo)

        // Setup buttons
        setUpButtons()
        
        // Setup ship display
        setupShipDisplay()
        
        // Display high score
        displayHighScore()
        startBackgroundMovement()
    }

   
    func startBackgroundMovement() {
           let moveAction = SKAction.moveBy(x: 0, y: -background1.size.height, duration: 20.0)
           let resetAction = SKAction.moveBy(x: 0, y: background1.size.height, duration: 0.0)
           let sequenceAction = SKAction.sequence([moveAction, resetAction])
           let repeatAction = SKAction.repeatForever(sequenceAction)
           
           background1.run(repeatAction)
           background2.run(repeatAction)
       }
    func setupShipDisplay() {
        // Initialize ship display
        shipDisplay = UIImageView(frame: CGRect(x: 0, y: 0, width: 130, height: 130))
        shipDisplay.center = CGPoint(x: self.view!.bounds.width / 2, y: buttonPlay.frame.origin.y - 170)
        shipDisplay.contentMode = .scaleAspectFit
        updateShipImage()
        self.view?.addSubview(shipDisplay)
        
        // Setup navigation buttons
        setupNavigationButtons()
    }
    
    func setupNavigationButtons() {
        let buttonSize = CGSize(width: 40, height: 40)
        
        // Left navigation button
        let buttonLeft = UIButton(frame: CGRect(x: shipDisplay.frame.minX - 70, y: shipDisplay.frame.midY - 20, width: buttonSize.width, height: buttonSize.height))
        buttonLeft.setImage(UIImage(named: "arrow_left.png"), for: .normal)
        buttonLeft.addTarget(self, action: #selector(navigateLeft), for: .touchUpInside)
        self.view?.addSubview(buttonLeft)
        
        // Right navigation button
        let buttonRight = UIButton(frame: CGRect(x: shipDisplay.frame.maxX + 30, y: shipDisplay.frame.midY - 20, width: buttonSize.width, height: buttonSize.height))
        buttonRight.setImage(UIImage(named: "arrow_right.png"), for: .normal)
        buttonRight.addTarget(self, action: #selector(navigateRight), for: .touchUpInside)
        self.view?.addSubview(buttonRight)
    }
    
    @objc func navigateLeft() {
        if currentShipIndex > 0 {
            currentShipIndex -= 1
        } else {
            currentShipIndex = shipImages.count - 1
        }
        updateShipImage()
    }
    
    @objc func navigateRight() {
        if currentShipIndex < shipImages.count - 1 {
            currentShipIndex += 1
        } else {
            currentShipIndex = 0
        }
        updateShipImage()
    }
    
    func updateShipImage() {
        let imageName = shipImages[currentShipIndex]
        shipDisplay.image = UIImage(named: imageName)
    }
    
    func displayHighScore() {
        highScoreLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        highScoreLabel.center = CGPoint(x: self.view!.bounds.width / 2, y: self.view!.bounds.height - 80)
        highScoreLabel.textAlignment = .center
        highScoreLabel.font = UIFont(name: "Futura", size: 25)
        highScoreLabel.textColor = .white
        highScoreLabel.text = "High Score: \(UserDefaults.standard.integer(forKey: "highScore"))"
        self.view?.addSubview(highScoreLabel)
    }
    


    
    func setUpButtons() {
        let buttonMargin: CGFloat = 10 // Adjust the margin between buttons
        let buttonSize = CGSize(width: 120, height: 40)
        
        // Play button
        buttonPlay = UIButton(frame: CGRect(x: 0, y: 0, width: buttonSize.width, height: buttonSize.height))
        buttonPlay.center = CGPoint(x: self.view!.bounds.width / 2, y: 600)
        buttonPlay.setBackgroundImage(UIImage(named: "button_background.png"), for: .normal)
        buttonPlay.setTitle("Play", for: .normal)
        buttonPlay.titleLabel?.font = UIFont(name: "Futura", size: 25)
        buttonPlay.setTitleColor(.white, for: .normal)
        buttonPlay.setTitleShadowColor(.black, for: .normal)
        buttonPlay.titleLabel?.shadowOffset = CGSize(width: 1.0, height: 1.0)
        buttonPlay.layer.cornerRadius = 10.0
        buttonPlay.layer.borderWidth = 2.0
        buttonPlay.layer.borderColor = UIColor.orange.cgColor
        buttonPlay.addTarget(self, action: #selector(playGame), for: .touchUpInside)
        self.view?.addSubview(buttonPlay)
        
        // Exit button
        buttonExit = UIButton(frame: CGRect(x: 0, y: 0, width: buttonSize.width, height: buttonSize.height))
        buttonExit.center = CGPoint(x: self.view!.bounds.width / 2, y: 654)
        buttonExit.setBackgroundImage(UIImage(named: "button_background_red.png"), for: .normal)
        buttonExit.setTitle("Exit", for: .normal)
        buttonExit.titleLabel?.font = UIFont(name: "Futura", size: 25)
        buttonExit.setTitleColor(.white, for: .normal)
        buttonExit.setTitleShadowColor(.black, for: .normal)
        buttonExit.titleLabel?.shadowOffset = CGSize(width: 1.0, height: 1.0)
        buttonExit.layer.cornerRadius = 10.0
        buttonExit.layer.borderWidth = 2.0
        buttonExit.layer.borderColor = UIColor.red.cgColor
        buttonExit.addTarget(self, action: #selector(exitGame), for: .touchUpInside)
        self.view?.addSubview(buttonExit)
    }
    
    @objc func exitGame() {
        print("Exiting game")
        exit(0) // Consider more graceful exit logic
    }
    
    @objc func playGame() {
        if let scene = GameScene(fileNamed: "GameScene") {
            scene.scaleMode = .aspectFit
            UserDefaults.standard.set(currentShipIndex, forKey: "selectedShipIndex")
            
            // Clean up UIKit elements
            buttonPlay.removeFromSuperview()
            buttonExit.removeFromSuperview()
            highScoreLabel.removeFromSuperview()
            shipDisplay.removeFromSuperview()
            for view in self.view!.subviews {
                if view is UIButton {
                    view.removeFromSuperview()
                }
            }
            
            // Transition to GameScene with an animation
            let transition = SKTransition.fade(withDuration: 1.0) // Use fade transition or choose another
            self.view?.presentScene(scene, transition: transition)
        }
    
    }
}
