# Weapon Bipod Toggle

This script automatically deploys and folds a bipod based on whether the gun is resting near a surface. When deployed, it updates the weapon's prone multipliers for kickback, snap, and spread.

## Step 1: Component Setup

1. Select the main (root) GameObject of your weapon in Unity.
2. Add a **Scripted Behaviour** component to it.
3. Add a **Data Container** component to the same object.
4. Set the **Source** of the Scripted Behaviour to your script file.  
   The file must be named exactly `SimpleBipod.lua`.
5. Create a child GameObject under your weapon hierarchy and name it exactly `BipodObject`. Position this object at the top of your bipod model, where the legs connect to the weapon. Select your main gun mesh, right-click its Transform component, and select **Copy Component**. Then select your new `BipodObject`, right-click its Transform component, and select **Paste Component Values**. This gives you a perfectly aligned starting point for rotation and position, so you only need to slide it smoothly into place.

## Step 2: Data Container Setup

Open your **Data Container** and add these 9 keys exactly as written:

| Key | Type | Description |
|---|---|---|
| `raycastDistance` | Float | The downward length of the detection raycast. This should be the distance from the top of the bipod (`BipodObject`) down to the bottom of the legs (for example, `0.5`). Extend if necessary. |
| `detectionDelay` | Float | Time in seconds the raycast must consistently hit or miss a surface before changing states (for example, `0.25`). Prevents quick accidental deployments while walking or passing brief geometry like a sandbag. |
| `bipodKickbackProneMultiplier` | Float | The improved multiplier applied to the weapon's `recoilKickbackProneMultiplier` when deployed (for example, `0.1` for 10% recoil kickback). |
| `bipodSnapProneMultiplier` | Float | The improved multiplier applied to the weapon's `recoilSnapProneMultiplier` when deployed (for example, `0.1` for 10% recoil snap). |
| `bipodSpreadProneMultiplier` | Float | The improved multiplier applied to the weapon's `followupSpread.proneMultiplier` when deployed (for example, `0.1` for 10% spread buildup). |
| `deployParameterName` | String | The exact name of the Trigger parameter you will make in your Animator for the deploying animation (Step 3). |
| `undeployParameterName` | String | The exact name of the Trigger parameter you will make in your Animator for the folding animation (Step 3). |
| `stateParameterName` | String | The exact name of the Int parameter you will make in your Animator (Step 3). |
| `stateValues` | String | Two numbers separated by a single space (for example, `0 1`). The first number is for Folded (State 0), and the second number is for Deployed (State 1). |

## Step 3: Animator Setup

### Parameters

Open your Animator's **Parameters** tab and add three new entries:

- A **Trigger** parameter. Name it exactly what you typed in `deployParameterName`
- A **Trigger** parameter. Name it exactly what you typed in `undeployParameterName`
- An **Int (Integer)** parameter. Name it exactly what you typed in `stateParameterName`

### The Physical Bipod Legs

1. Create a new Animator Layer for the gun's legs.
2. Click the layer's gear icon and set:
   - **Weight** to `1`
   - **Blending** to `Additive`
3. Create two states in this layer:
   - one static animation clip for the **Folded** position
   - one for the **Deployed** position
4. Make transition arrows connecting the two states to each other.
5. Click the transition arrow going to the **Folded** state.
   - Under **Conditions**, set your Int parameter to **Equals** your first number (for example, `0`)
6. Click the transition arrow going to the **Deployed** state.
   - Set the condition to **Equals** your second number (for example, `1`)

### The Hand Animations

1. In your main animation layer, create two new states:
   - one for your **"Deploying Hand"** animation
   - one for your **"Undeploying Hand"** animation
2. Create a transition line from **Any State** into your **"Deploying Hand"** state.
3. Under **Conditions** for that transition, add your Deploy Trigger parameter.
4. Create a transition line from **Any State** into your **"Undeploying Hand"** state.
5. Under **Conditions** for that transition, add your Undeploy Trigger parameter.
6. Create transition lines from both hand animation states back to your standard **Hip State**.

## Credits

Huge thanks to **ProfessionalDebil** for the massive help.
