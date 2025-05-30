# Lunar Lander iOS Game

A simple lunar lander game built with Swift and SpriteKit for iOS.

## Features

- **Physics-based gameplay**: The lander is affected by lunar gravity and will descend automatically
- **Touch controls**: Touch and hold anywhere on the screen to fire thrusters
- **Realistic mechanics**: Thrusters provide upward force to counteract gravity
- **Fuel system**: Limited fuel that depletes when thrusters are active
- **Landing detection**: Safe landing vs crash detection based on velocity
- **UI indicators**: Real-time display of velocity, altitude, and fuel level
- **Game restart**: Tap to restart after game over

## How to Play

1. **Objective**: Land the lunar lander safely on the surface
2. **Controls**: 
   - Touch and hold anywhere on the screen to fire thrusters
   - Release to stop thrusting
3. **Physics**:
   - The lander starts falling due to gravity
   - Thrusters provide upward force when activated
   - Fuel is consumed when thrusters are active
4. **Landing**:
   - Land slowly (velocity < 5.0 m/s) for a successful landing
   - Land too fast and you'll crash
   - Run out of fuel and you'll fall

## Game Elements

- **White rectangle**: The lunar lander
- **Orange flame**: Thruster fire (visible when thrusting)
- **Gray surface**: The lunar ground
- **Black background**: Space with stars
- **HUD**: Velocity, altitude, and fuel indicators

## Technical Details

- Built with Swift and SpriteKit
- Supports iOS 17.0+
- Physics simulation with gravity and force application
- Touch input handling for thruster control
- Collision detection for landing/crashing
- Game state management with restart functionality
- Scene created programmatically (no .sks files needed)

## Building and Running

1. Open `LunarLander.xcodeproj` in Xcode
2. Select a target device or simulator
3. Build and run the project

The game automatically starts when launched. The lander begins falling immediately, so be ready to use your thrusters!

## Recent Fixes

- ✅ **Fixed "fopen failed" error**: Removed corrupted .sks files and created the game scene programmatically
- ✅ **Cleaned project structure**: Simplified the project by removing unnecessary SpriteKit scene files

## Game Tips

- Don't waste fuel - use short bursts of thrust rather than holding continuously
- Watch your velocity indicator - aim for gentle landings
- Monitor your altitude to plan your descent
- The fuel gauge changes color: green (>50%), yellow (20-50%), red (<20%)

Enjoy your lunar landing mission! 🚀🌙 