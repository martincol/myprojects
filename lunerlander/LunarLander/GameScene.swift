import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // Game objects
    private var lander: SKSpriteNode!
    private var thrusterFlame: SKShapeNode!
    private var leftThrusterFlame: SKShapeNode!
    private var rightThrusterFlame: SKShapeNode!
    private var ground: SKSpriteNode!
    private var background: SKSpriteNode!
    private var targetLandingZone: SKSpriteNode!
    
    // Game properties
    private var gravity: CGFloat = -1.5
    private var thrusterForce: CGFloat = 50.0
    private var horizontalThrusterForce: CGFloat = 25.0
    private var isThrusting = false
    private var isThustingLeft = false
    private var isThustingRight = false
    private var gameStarted = false
    private var gamePaused = false
    
    // Target landing area
    private var targetLandingPosition: CGFloat = 0.0
    private let targetLandingWidth: CGFloat = 80.0
    
    // UI Elements
    private var velocityLabel: SKLabelNode!
    private var altitudeLabel: SKLabelNode!
    private var fuelLabel: SKLabelNode!
    private var instructionLabel: SKLabelNode!
    
    // Game state
    private var fuel: CGFloat = 50.0
    private let maxFuel: CGFloat = 50.0
    private let fuelConsumptionRate: CGFloat = 12.0
    
    override func didMove(to view: SKView) {
        setupScene()
        setupPhysics()
        setupLander()
        setupGround()
        setupBackground()
        setupUI()
        setupParticles()
    }
    
    private func setupScene() {
        gravity = -1.5
        thrusterForce = 50.0
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVector(dx: 0, dy: gravity)
        
        let groundMargin = targetLandingWidth * 0.5
        targetLandingPosition = CGFloat.random(in: groundMargin...(size.width - groundMargin))
        
        print("Using ultra-gentle gravity: \(gravity)")
        print("Thruster force: \(thrusterForce)")
        print("Target landing position: \(targetLandingPosition)")
    }
    
    private func setupPhysics() {
        struct PhysicsCategory {
            static let lander: UInt32 = 0x1 << 0
            static let ground: UInt32 = 0x1 << 1
        }
    }
    
    private func setupLander() {
        let landerSize = CGSize(width: 40, height: 50)
        lander = SKSpriteNode(color: .clear, size: landerSize)
        lander.position = CGPoint(x: size.width * 0.5, y: size.height * 0.8)
        lander.name = "lander"
        
        // Create triangular spacecraft body
        let bodyPath = UIBezierPath()
        bodyPath.move(to: CGPoint(x: 0, y: 20))
        bodyPath.addLine(to: CGPoint(x: -15, y: -20))
        bodyPath.addLine(to: CGPoint(x: 15, y: -20))
        bodyPath.close()
        
        let bodyShape = SKShapeNode(path: bodyPath.cgPath)
        bodyShape.fillColor = .lightGray
        bodyShape.strokeColor = .white
        bodyShape.lineWidth = 2
        lander.addChild(bodyShape)
        
        // Add landing legs
        let leftLeg = SKSpriteNode(color: .darkGray, size: CGSize(width: 3, height: 15))
        leftLeg.position = CGPoint(x: -12, y: -15)
        lander.addChild(leftLeg)
        
        let rightLeg = SKSpriteNode(color: .darkGray, size: CGSize(width: 3, height: 15))
        rightLeg.position = CGPoint(x: 12, y: -15)
        lander.addChild(rightLeg)
        
        // Add cockpit window
        let window = SKShapeNode(circleOfRadius: 6)
        window.fillColor = .cyan
        window.strokeColor = .white
        window.lineWidth = 1
        window.position = CGPoint(x: 0, y: 5)
        lander.addChild(window)
        
        // Physics body
        lander.physicsBody = SKPhysicsBody(rectangleOf: landerSize)
        lander.physicsBody?.categoryBitMask = 0x1 << 0
        lander.physicsBody?.contactTestBitMask = 0x1 << 1
        lander.physicsBody?.collisionBitMask = 0x1 << 1
        lander.physicsBody?.mass = 0.1
        lander.physicsBody?.linearDamping = 0.01
        lander.physicsBody?.angularDamping = 0.3
        lander.physicsBody?.restitution = 0.1
        lander.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        
        addChild(lander)
        
        // Main thruster flame
        thrusterFlame = SKShapeNode()
        let mainThrusterPath = UIBezierPath()
        mainThrusterPath.move(to: CGPoint(x: -8, y: 0))
        mainThrusterPath.addLine(to: CGPoint(x: 8, y: 0))
        mainThrusterPath.addLine(to: CGPoint(x: 0, y: -25))
        mainThrusterPath.close()
        
        thrusterFlame.path = mainThrusterPath.cgPath
        thrusterFlame.fillColor = .orange
        thrusterFlame.strokeColor = .red
        thrusterFlame.lineWidth = 1
        thrusterFlame.position = CGPoint(x: 0, y: -25)
        thrusterFlame.isHidden = true
        thrusterFlame.alpha = 0.9
        lander.addChild(thrusterFlame)
        
        // Left side thruster flame
        leftThrusterFlame = SKShapeNode()
        let leftThrusterPath = UIBezierPath()
        leftThrusterPath.move(to: CGPoint(x: 0, y: 8))
        leftThrusterPath.addLine(to: CGPoint(x: 0, y: -8))
        leftThrusterPath.addLine(to: CGPoint(x: -20, y: 0))
        leftThrusterPath.close()
        
        leftThrusterFlame.path = leftThrusterPath.cgPath
        leftThrusterFlame.fillColor = .blue
        leftThrusterFlame.strokeColor = .cyan
        leftThrusterFlame.lineWidth = 1
        leftThrusterFlame.position = CGPoint(x: -18, y: -5)
        leftThrusterFlame.isHidden = true
        leftThrusterFlame.alpha = 0.8
        lander.addChild(leftThrusterFlame)
        
        // Right side thruster flame
        rightThrusterFlame = SKShapeNode()
        let rightThrusterPath = UIBezierPath()
        rightThrusterPath.move(to: CGPoint(x: 0, y: 8))
        rightThrusterPath.addLine(to: CGPoint(x: 0, y: -8))
        rightThrusterPath.addLine(to: CGPoint(x: 20, y: 0))
        rightThrusterPath.close()
        
        rightThrusterFlame.path = rightThrusterPath.cgPath
        rightThrusterFlame.fillColor = .blue
        rightThrusterFlame.strokeColor = .cyan
        rightThrusterFlame.lineWidth = 1
        rightThrusterFlame.position = CGPoint(x: 18, y: -5)
        rightThrusterFlame.isHidden = true
        rightThrusterFlame.alpha = 0.8
        lander.addChild(rightThrusterFlame)
    }
    
    private func setupGround() {
        ground = SKSpriteNode(color: .gray, size: CGSize(width: size.width, height: 50))
        ground.position = CGPoint(x: size.width * 0.5, y: 25)
        ground.name = "ground"
        
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.categoryBitMask = 0x1 << 1
        ground.physicsBody?.isDynamic = false
        
        addChild(ground)
        
        // Target landing zone (no text)
        targetLandingZone = SKSpriteNode(color: .green, size: CGSize(width: targetLandingWidth, height: 10))
        targetLandingZone.position = CGPoint(x: targetLandingPosition, y: ground.position.y + ground.size.height/2 + targetLandingZone.size.height/2)
        targetLandingZone.name = "targetZone"
        targetLandingZone.alpha = 0.7
        addChild(targetLandingZone)
    }
    
    private func setupBackground() {
        background = SKSpriteNode(color: .black, size: size)
        background.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        background.zPosition = -100
        addChild(background)
        
        // Add stars
        for _ in 1...50 {
            let star = SKSpriteNode(color: .white, size: CGSize(width: 2, height: 2))
            star.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: size.height * 0.3...size.height)
            )
            star.zPosition = -50
            addChild(star)
        }
    }
    
    private func setupUI() {
        velocityLabel = SKLabelNode(fontNamed: "Arial")
        velocityLabel.fontSize = 16
        velocityLabel.fontColor = .white
        velocityLabel.position = CGPoint(x: 60, y: size.height - 40)
        velocityLabel.text = "Velocity: 0.0 m/s"
        addChild(velocityLabel)
        
        altitudeLabel = SKLabelNode(fontNamed: "Arial")
        altitudeLabel.fontSize = 16
        altitudeLabel.fontColor = .white
        altitudeLabel.position = CGPoint(x: 60, y: size.height - 65)
        altitudeLabel.text = "Altitude: 0 m"
        addChild(altitudeLabel)
        
        fuelLabel = SKLabelNode(fontNamed: "Arial")
        fuelLabel.fontSize = 16
        fuelLabel.fontColor = .green
        fuelLabel.position = CGPoint(x: 60, y: size.height - 90)
        fuelLabel.text = "Fuel: 100%"
        addChild(fuelLabel)
        
        instructionLabel = SKLabelNode(fontNamed: "Arial")
        instructionLabel.fontSize = 18
        instructionLabel.fontColor = .yellow
        instructionLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        instructionLabel.text = "Touch left/right sides for horizontal thrust, center for vertical"
        addChild(instructionLabel)
        
        let wait = SKAction.wait(forDuration: 3.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([wait, fadeOut, remove])
        instructionLabel.run(sequence)
    }
    
    private func setupParticles() {
        // Placeholder for particle effects
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isThrusting = false
        isThustingLeft = false
        isThustingRight = false
        
        thrusterFlame.isHidden = true
        leftThrusterFlame.isHidden = true
        rightThrusterFlame.isHidden = true
        
        thrusterFlame.removeAction(forKey: "thrusterAnimation")
        leftThrusterFlame.removeAction(forKey: "leftThrusterAnimation")
        rightThrusterFlame.removeAction(forKey: "rightThrusterAnimation")
        
        thrusterFlame.setScale(1.0)
        leftThrusterFlame.setScale(1.0)
        rightThrusterFlame.setScale(1.0)
        
        let returnToUpright = SKAction.rotate(toAngle: 0, duration: 0.5)
        lander.run(returnToUpright)
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let landerPhysics = lander.physicsBody else { return }
        
        // Vertical thruster
        if isThrusting && fuel > 0 {
            let thrusterImpulse = CGVector(dx: 0, dy: thrusterForce * 0.025)
            landerPhysics.applyImpulse(thrusterImpulse)
            fuel -= fuelConsumptionRate * (1.0/60.0)
            fuel = max(0, fuel)
        }
        
        // Horizontal thrusters
        if (isThustingLeft || isThustingRight) && fuel > 0 {
            let horizontalImpulse = horizontalThrusterForce * 0.025
            var impulseDirection: CGFloat = 0
            var rotationDirection: CGFloat = 0
            
            if isThustingLeft {
                impulseDirection = horizontalImpulse // Push RIGHT
                rotationDirection = 0.3 // Tilt right
            } else if isThustingRight {
                impulseDirection = -horizontalImpulse // Push LEFT
                rotationDirection = -0.3 // Tilt left
            }
            
            let horizontalThrusterImpulse = CGVector(dx: impulseDirection, dy: 0)
            landerPhysics.applyImpulse(horizontalThrusterImpulse)
            
            let targetRotation = rotationDirection
            let currentRotation = lander.zRotation
            let rotationDifference = targetRotation - currentRotation
            let rotationSpeed: CGFloat = 0.1
            lander.zRotation += rotationDifference * rotationSpeed
            
            fuel -= fuelConsumptionRate * 0.7 * (1.0/60.0)
            fuel = max(0, fuel)
        }
        
        updateUI()
        checkGameState()
    }
    
    private func updateUI() {
        guard let landerPhysics = lander.physicsBody else { return }
        
        let velocity = sqrt(pow(landerPhysics.velocity.dx, 2) + pow(landerPhysics.velocity.dy, 2))
        let velocityInMeters = velocity / 25.0
        velocityLabel.text = String(format: "Velocity: %.1f m/s", velocityInMeters)
        
        let altitude = max(0, (lander.position.y - ground.position.y - ground.size.height/2 - lander.size.height/2) / 8.0)
        altitudeLabel.text = String(format: "Altitude: %.0f m", altitude)
        
        let fuelPercentage = (fuel / maxFuel) * 100
        fuelLabel.text = String(format: "Fuel: %.0f%%", fuelPercentage)
        
        if fuelPercentage > 50 {
            fuelLabel.fontColor = .green
        } else if fuelPercentage > 20 {
            fuelLabel.fontColor = .yellow
        } else {
            fuelLabel.fontColor = .red
        }
    }
    
    private func checkGameState() {
        if lander.position.y < -100 {
            gameOver(success: false, reason: "Crashed!")
        }
        
        if lander.position.x < -50 || lander.position.x > size.width + 50 {
            gameOver(success: false, reason: "Lost in space!")
        }
        
        if fuel <= 0 && (isThrusting || isThustingLeft || isThustingRight) {
            isThrusting = false
            isThustingLeft = false
            isThustingRight = false
            thrusterFlame.isHidden = true
            leftThrusterFlame.isHidden = true
            rightThrusterFlame.isHidden = true
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let landerPhysics = lander.physicsBody else { return }
        
        let velocity = sqrt(pow(landerPhysics.velocity.dx, 2) + pow(landerPhysics.velocity.dy, 2))
        let velocityInMeters = velocity / 25.0
        
        if velocityInMeters < 3.0 {
            let landerX = lander.position.x
            let targetMinX = targetLandingPosition - targetLandingWidth/2
            let targetMaxX = targetLandingPosition + targetLandingWidth/2
            
            if landerX >= targetMinX && landerX <= targetMaxX {
                gameOver(success: true, reason: "Perfect Target Landing! 🎯")
            } else {
                gameOver(success: true, reason: "Safe Landing!")
            }
        } else {
            gameOver(success: false, reason: "Crashed! Landing too fast!")
        }
    }
    
    private func gameOver(success: Bool, reason: String) {
        gamePaused = true
        lander.physicsBody?.isDynamic = false
        
        let gameOverLabel = SKLabelNode(fontNamed: "Arial")
        gameOverLabel.fontSize = 24
        gameOverLabel.fontColor = success ? .green : .red
        gameOverLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.6)
        gameOverLabel.text = reason
        addChild(gameOverLabel)
        
        let restartLabel = SKLabelNode(fontNamed: "Arial")
        restartLabel.fontSize = 18
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        restartLabel.text = "Tap to restart"
        restartLabel.name = "restart"
        addChild(restartLabel)
        
        let wait = SKAction.wait(forDuration: 1.0)
        let enableRestart = SKAction.run {
            self.gamePaused = false
        }
        run(SKAction.sequence([wait, enableRestart]))
    }
    
    private func restartGame() {
        removeAllChildren()
        
        fuel = maxFuel
        isThrusting = false
        isThustingLeft = false
        isThustingRight = false
        gameStarted = false
        gamePaused = false
        
        setupScene()
        setupPhysics()
        setupLander()
        setupGround()
        setupBackground()
        setupUI()
        setupParticles()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let touchedNode = atPoint(location)
        
        if touchedNode.name == "restart" && !gamePaused {
            restartGame()
            return
        }
        
        if !gamePaused && fuel > 0 {
            gameStarted = true
            
            let screenThird = size.width / 3.0
            
            if location.x < screenThird {
                // Left touch - fire RIGHT thruster to move LEFT
                isThustingRight = true
                rightThrusterFlame.isHidden = false
                
                let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
                let scaleDown = SKAction.scale(to: 0.8, duration: 0.1)
                let thrusterAnimation = SKAction.sequence([scaleUp, scaleDown])
                let repeatAnimation = SKAction.repeatForever(thrusterAnimation)
                rightThrusterFlame.run(repeatAnimation, withKey: "rightThrusterAnimation")
                
            } else if location.x > screenThird * 2 {
                // Right touch - fire LEFT thruster to move RIGHT
                isThustingLeft = true
                leftThrusterFlame.isHidden = false
                
                let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
                let scaleDown = SKAction.scale(to: 0.8, duration: 0.1)
                let thrusterAnimation = SKAction.sequence([scaleUp, scaleDown])
                let repeatAnimation = SKAction.repeatForever(thrusterAnimation)
                leftThrusterFlame.run(repeatAnimation, withKey: "leftThrusterAnimation")
                
            } else {
                // Center touch - main thruster
                isThrusting = true
                thrusterFlame.isHidden = false
                
                let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
                let scaleDown = SKAction.scale(to: 0.8, duration: 0.1)
                let thrusterAnimation = SKAction.sequence([scaleUp, scaleDown])
                let repeatAnimation = SKAction.repeatForever(thrusterAnimation)
                thrusterFlame.run(repeatAnimation, withKey: "thrusterAnimation")
            }
        }
    }
} 