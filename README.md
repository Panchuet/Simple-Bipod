# Simple Bipod
This script automatically deploys and folds a bipod based on whether the gun is resting near a surface. When deployed and grounded, it directly applies accuracy bonuses by baking the configured multipliers into the weapon's base kickback, snap, and spread values.

## Step 1: Component Setup
1. Select the main (root) game object of your weapon in Unity
2. Add a `Scripted Behaviour` component to it
3. Add a `Data Container` component to the same object
4. Set the Source of the Scripted Behaviour to your script file. The file must be named exactly `SimpleBipod.lua`
5. Create a child GameObject under your weapon hierarchy and name it exactly `BipodObject`. Position this object at the top of your bipod model, where the legs connect to the weapon. Select your main gun mesh, right-click its `Transform` component, and select `Copy Component`. Then select your new `BipodObject`, right-click its `Transform` component, and select `Paste Component Values`. This gives you a perfectly aligned starting point for rotation and position, so you only need to slide it smoothly into place
6. Enable `Keep Scripts On Third Person` in the `Weapon` script

## Step 2: Data Container Setup
Open your Data Container and add these 9 keys exactly as written *(i edited some key names, the image is now outdated so double check!)*
- `raycastDistance` — **Float**
  - The downward length of the detection raycast. This should be the distance from the top of the bipod (`BipodObject`) down to the bottom of the legs (e.g., `0.5`). Extend if necessary
- `detectionDelay` — **Float**
  - Time in seconds the raycast must consistently hit or miss a surface before changing states (e.g., `1.0`). Prevents quick accidental deployments while walking or passing brief geometry
- `bipodKickbackMultiplier` — **Float**
  - Multiplier applied to the weapon's `recoilBaseKickback` and `recoilRandomKickback` when deployed and grounded (e.g., `0.1` for 10% recoil kickback)
- `bipodSnapMultiplier` — **Float**
  - Multiplier applied to the weapon's `recoilSnapMagnitude` when deployed and grounded (e.g., `0.1` for 10% recoil snap)
- `bipodSpreadMultiplier` — **Float**
  - Multiplier applied to `followupSpread.maxSpreadAim` and `followupSpread.maxSpreadHip` when deployed and grounded (e.g., `0.1` for 10% spread cap)
- `deployParameterName` — **String**
  - The exact name of the Trigger parameter you will make in your Animator for the deploying animation (Step 3)
- `undeployParameterName` — **String**
  - The exact name of the Trigger parameter you will make in your Animator for the folding animation (Step 3)
- `stateParameterName` — **String**
  - The exact name of the Int parameter you will make in your Animator (Step 3)
- `stateValues` — **String**
  - Two numbers separated by a single space (like `0 1`). The first number is for Folded (State 0), and the second number is for Deployed (State 1)

## Step 3: Animator Setup
Open your Animator's Parameters tab and add three new entries:
1. A `Trigger` parameter. Name it exactly what you typed in `deployParameterName`
2. A `Trigger` parameter. Name it exactly what you typed in `undeployParameterName`
3. An `Int` (Integer) parameter. Name it exactly what you typed in `stateParameterName`

## The Physical Bipod Legs
1. Create a new Animator Layer for the gun's legs. Click the layer's gear icon and set Weight to `1` and Blending to `Additive`
2. Create two states in this layer: one static animation clip for the Folded position, and one for the Deployed position
3. Make transition arrows connecting the two states to each other
4. Click the transition arrow going to the Folded state. Under Conditions, set your Int parameter to Equals your first number (e.g., `0`)
5. Click the transition arrow going to the Deployed state. Set the condition to Equals your second number (e.g., `1`)

## The Hand Animations
1. In your main animation layer, create two new states: one for your "Deploying Hand" animation, and one for your "Undeploying Hand" animation
2. Create a transition line from `Any State` into your "Deploying Hand" state
3. Under Conditions for that transition, add your Deploy Trigger parameter
4. Create a transition line from `Any State` into your "Undeploying Hand" state
5. Under Conditions for that transition, add your Undeploy Trigger parameter
6. Create transition lines from both hand animation states back to your standard `Hip State`

## Credits
Again huge huge thanks to ProfessionalDebil for the massive help
