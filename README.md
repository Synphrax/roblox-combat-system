# Roblox Combat System Prototype

This is a Roblox project built with Rojo that prototypes a client/server combat system. The current focus is a basic combat framework with client-side input handling, server-side combat validation, replicated combat effects, shared animation/state modules, and base combat actions such as M1, M2, and block.

The project is split between client and server logic: clients read player input and play local combat feedback, while the server validates combat requests, manages character state, creates hitboxes, applies knockback, and handles damage.

## Technologies

- **Roblox Studio** - used to run, test, and provide in-game assets such as animations, sounds, VFX, and character rigs.
- **Luau** - Roblox's Lua language used for the server, client, and shared modules.
- **Rojo 7.6.1** - maps the filesystem project into Roblox Studio.
- **Selene** - used for Luau linting through `selene.toml`.

## Features

- Client-side input binding through `ContextActionService`.
- Mouse button 1 input for base M1 attacks.
- Keyboard input for M2 and blocking.
- Server remote dispatch through `ReplicatedStorage.Remotes.Server`.
- Client replication remote through `ReplicatedStorage.Remotes.Replicate`.
- Player combat type setup with `playerCombatType`.
- Player skill set setup with `playerSkillSet`.
- Server-side combat module dispatch through `ServerFramework`.
- Shared client combat modules under `ReplicatedStorage.Shared.LocalHandler`.
- Shared state tracking through `StateHandler.luau`.
- Shared animation loading, stopping, and preloading through `AnimationHandler.luau`.
- M1 combo state tracking.
- Temporary combat lockout through `"CantAnything"` state.
- Stun handling through `"Stunned"` state and humanoid walk speed changes.
- Blocking and perfect blocking states.
- Server-side hitbox cloning for M1 attacks.
- Per-target hit detection using `workspace:GetPartBoundsInBox`.
- Duplicate hit prevention within a single hitbox check.
- Knockback application through `BodyVelocity`.
- Hit, blocked, and perfect block replication hooks.

## How to run the project

### 1. Install project tools

This project expects Rojo to be available.

```bash
rojo --version
```

If you manage Roblox tools with Rokit, install Rojo through Rokit. If Rojo is already available globally, you can use it directly.

### 2. Build the place file

```bash
rojo build -o CombatSystem.rbxlx
```

Open `CombatSystem.rbxlx` in Roblox Studio.

### 3. Or run with live Rojo sync

Start the Rojo server:

```bash
rojo serve default.project.json
```

Then connect Roblox Studio to the Rojo server using the Rojo plugin.

### 4. Required Studio assets

The code expects these assets to exist in Roblox Studio:

```text
ReplicatedStorage
  Assets
    Sounds
      PunchHit
      BlockedHit
      PerfectBlock

    FX
      HitFX
        Attachment

      BlockFX
        Attachment

      PBFX
        Attachment

Workspace
  Hitboxes
```

The `Assets` folder is intended to be managed manually in Roblox Studio, not by Rojo.

The animation IDs used by the combat modules must be owned by, or shared with, the experience owner or group. If animations do not play, check Studio output for animation permission or rig-type errors.

### 5. Project structure

```text
src
  client
    InputReplication.client.luau
    Replicator.client.luau

  remotes
    Replicate.model.json
    Server.model.json

  server
    Skillsets.server.luau
    Modules
      HelperModule.luau

    ServerFramework
      init.server.luau
      Combat
        Base
          Block.luau
          M2.luau
          M1
            init.luau
            Hitbox.model.json

  shared
    Modules
      AnimationHandler.luau
      StateHandler.luau

    LocalHandler
      Combat
        Base
          Block.luau
          M1.luau
          M2.luau
```

`InputReplication.client.luau` binds player input and calls the matching local combat module:

```lua
callClientFunction("Combat", "M1", "OnM1Activated")
```

The local M1 module sends a server validation request:

```lua
ServerRemote:FireServer({
	Type = "Combat",
	Action = "M1",
	Func = "ServerCheck"
})
```

`ServerFramework/init.server.luau` routes that request to the server combat module based on the player's equipped combat type.

## Preview

Current gameplay behavior:

- Players receive default combat values when they join.
- The default combat type is `Base`.
- MB1 triggers the M1 combo flow.
- M1 plays a local attack animation.
- The server validates whether the character can attack.
- The server temporarily applies `"CantAnything"` during attack startup.
- A hitbox is cloned from the server M1 module and positioned in front of the attacker.
- Valid targets can be damaged, stunned, and knocked back.
- Blocking targets can trigger blocked or perfect blocked responses.
- Combat feedback is sent back to clients through the replication remote.

No screenshot or video preview is checked into the repository yet.
