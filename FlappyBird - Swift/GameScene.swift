//
//  GameScene.swift
//  FlappyBird - Swift
//
//  Created by Lorenzo Piccoli on 04/06/14.
//  Copyright (c) 2014 Lorenzo Piccoli. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate{
    
    /*Constants*/
    
    let gameSpeed = 0.01 //Less is faster
    let pipesSpawnTime = 1.5
    let landImageSize = SKSpriteNode(imageNamed: "land").size.height
    let birdBitMask :UInt32 = 1
    let gravity:CGFloat = -3.0
    var bird = SKSpriteNode()
    var lastRandomHeight:CGFloat = 0.0 //Prevents sequece of pipes at the same height
    var isFirstTouch = true
    var gameOver = false
    
    override func didMoveToView(view: SKView) {
        
        //Background Color
        backgroundColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        
        physicsWorld.gravity = CGVectorMake(0, 0)
        physicsWorld.contactDelegate = self
        
        //Land
        for i in 0..2{
            
            let land = SKSpriteNode(imageNamed: "land")
            land.anchorPoint = CGPointZero
            land.position = CGPoint(x: CGFloat(i)  * land.frame.size.width, y:0.0)
            land.zPosition = 2
            
            //Move land
            land.runAction(moveForeverAction(land))
            
            //Land Physics
            let contactSize = CGSizeMake(land.frame.size.width * 2, land.frame.size.height * 2)
            land.physicsBody = SKPhysicsBody(rectangleOfSize:contactSize)
            land.physicsBody.dynamic = false
            land.physicsBody.contactTestBitMask = 0
            land.physicsBody.collisionBitMask = 0
            
            addChild(land)
        }
        //Sky
        
        for i in 0..3{ //Have to do 1 time more than land because the image width is shorter than the screen width
            let sky = SKSpriteNode(imageNamed: "sky")
            sky.anchorPoint = CGPointZero
            sky.setScale(2.0)
            sky.zPosition = 0
            sky.position = CGPoint(x: CGFloat(i)  * sky.frame.size.width, y:landImageSize)
            
            //Move Sky
            sky.runAction(moveForeverAction(sky))
            addChild(sky)
        }
        
        //Bird
        let bird1 = SKTexture(imageNamed:"bird-01")
        let bird2 = SKTexture(imageNamed:"bird-02")
        let bird3 = SKTexture(imageNamed:"bird-03")
        
        let flap = SKAction.animateWithTextures([bird1, bird2, bird3], timePerFrame: 0.1)
        let repeatFlap = SKAction.repeatActionForever(flap)
        
        bird = SKSpriteNode(texture: bird1)
        bird.position = CGPointMake(frame.size.width / 2, frame.size.height / 2)
        bird.zPosition = 3
        bird.runAction(repeatFlap)
        
        
        //Physics
        bird.physicsBody = SKPhysicsBody(rectangleOfSize: bird.size)
        bird.physicsBody.contactTestBitMask = birdBitMask
        bird.physicsBody.collisionBitMask = birdBitMask
        
        addChild(bird)
        
        
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        /* Called when a touch begins */
        
        for touch: AnyObject in touches {
            bird.physicsBody.velocity = CGVectorMake(0.0, 0.0)
            bird.physicsBody.applyImpulse(CGVectorMake(0.0, 9.0))
            if (isFirstTouch){
                isFirstTouch = false
                
                //Spawn Pipes
                NSTimer.scheduledTimerWithTimeInterval(pipesSpawnTime, target: self, selector: Selector("spawnPipes"), userInfo: nil, repeats: true)
                physicsWorld.gravity = CGVectorMake(0, gravity)

            }
        }
    }
    
    override func update(currentTime: CFTimeInterval) {
        
        if (!isFirstTouch){
            //The bird must start to face down as time pass
            bird.zRotation = bird.physicsBody.velocity.dy / 200
            if bird.zRotation < CGFloat((-M_PI / 2)){
                bird.zRotation = CGFloat((-M_PI / 2))
            }
            
            if (gameOver){
                stopGame()
            }
        }
    }
    
    //Functions
    func moveForeverAction(node: SKSpriteNode) -> SKAction{
        let moveNode = SKAction.moveByX(-node.size.width, y: 0, duration: NSTimeInterval(CGFloat(gameSpeed) * node.size.width))
        let resetPosition = SKAction.moveTo(CGPoint(x: node.frame.origin.x, y:node.frame.origin.y), duration: 0.0)
        let moveNodeForever = SKAction.repeatActionForever(SKAction.sequence([moveNode, resetPosition]))
        return moveNodeForever
    }
    
    func spawnPipes(){
        let pipeUp = SKSpriteNode(imageNamed:"PipeUp")
        let pipeDown = SKSpriteNode(imageNamed:"PipeDown")
        var randomHeight:CGFloat = CGFloat(arc4random() % 5)
        
        switch (randomHeight){ //Random Height can't be zero or one. The switch also change the height to prevents sequece of pipes at the same height
        case 0.0, 1:
            randomHeight = 1.5
        case lastRandomHeight:
            randomHeight++
        default:
            break
        }
        
        lastRandomHeight = randomHeight
        
        //If it's the iPhone 4s than we need to make the gap bigger
        let is4S:CGFloat = frame.height < 500 ? 60 : 0
        
        //Pipe Up
        pipeUp.setScale(2.0)
        pipeUp.position = CGPoint(x: frame.size.width + pipeUp.frame.size.width / 2,y: (landImageSize - pipeUp.size.height / randomHeight - is4S) + pipeUp.frame.height / 2)
        pipeUp.zPosition = 1
        
        //Pipe Down
        pipeDown.setScale(2.0)
        pipeDown.position = CGPoint(x: frame.size.width + pipeDown.frame.size.width / 2, y: (frame.size.height - pipeDown.frame.size.height / randomHeight) + pipeUp.frame.height / 2)
        
        //Action
        let movePipe = SKAction.moveByX(-pipeUp.size.width, y: 0, duration: NSTimeInterval(CGFloat(gameSpeed) * pipeUp.size.width))
        pipeDown.runAction(SKAction.repeatActionForever(movePipe))
        pipeUp.runAction(SKAction.repeatActionForever(movePipe))
        
        //Physics
        let contactSize = CGSizeMake(pipeUp.frame.size.width , pipeUp.frame.size.height)
        pipeDown.physicsBody = SKPhysicsBody(rectangleOfSize:contactSize)
        pipeDown.physicsBody.dynamic = false
        pipeDown.physicsBody.collisionBitMask = 1
        pipeDown.physicsBody.contactTestBitMask = 1
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOfSize:contactSize)
        pipeUp.physicsBody.dynamic = false
        pipeUp.physicsBody.collisionBitMask = 1
        pipeUp.physicsBody.contactTestBitMask = 1
        
        addChild(pipeUp)
        addChild(pipeDown)
    }
    
    func stopGame(){
        let message = SKLabelNode(fontNamed:"Arial")
        message.text = "Game Over";
        message.fontSize = 55;
        message.fontColor = UIColor.redColor()
        message.position = CGPoint(x:CGRectGetMidX(self.frame), y:CGRectGetMidY(self.frame));
        
        addChild(message)
    
        view.paused = true
    }
    
    //Collision Delegate
    
    func didBeginContact(contact: SKPhysicsContact!){
        gameOver = true
    }
}
