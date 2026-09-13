# This is Roblox Client Exploit Automation

# Game Details

The main Roblox game environments and services used by this project are:

* `Players`
* `ReplicatedFirst`
* `ReplicatedStorage`
* `StarterPlayer`
* `StarterPlayerScripts`
* `Workspace`

# Game Explorer Tree

The complete game Explorer structure is documented in:

`Explorer.txt`

Use `Explorer.txt` as the reference when locating existing Instances, folders, modules, remotes, scripts, and other game objects.

# Required Documentation

**Force to read before working on this project:**

[AGENT.md](https://raw.githubusercontent.com/vita8it/Opengame/refs/heads/main/AGENT.md)

[Icon Lucide](https://github.com/vita8it/Turbopack/blob/main/Components/Lucide.lua)

The rules, coding conventions, framework usage, and project-specific instructions defined in `AGENT.md` must be followed when writing or modifying code for this project.

# Write your Script in "Source" Folder

`Source/` is the working directory for the Agent.

New scripts and modified scripts should be written in `Source/`.

# GameSource

`GameSource/` contains source code dumped from the Roblox game.

Use `GameSource/` as a reference when inspecting existing game scripts.

Do not use `GameSource/` as the Agent working directory.

Do not overwrite existing GameSource files unless explicitly requested.

---

# Troubleshooting & Troubleshooting Rules

### 🚨 Error Handling: `attempt to index nil with 'CreateWindow'` (WindUI)
When encountering `attempt to index nil with 'CreateWindow'` in WindUI scripts:

1. **Root Cause:**
   * The `loadstring(game:HttpGet(...))()` returned `nil` because the URL was broken, rate-limited, or blocked by the HTTP provider.

2. **Resolution & Protocol:**
   * ALWAYS use the official Footagesus WindUI URL:
     ```lua
     local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
     ```
   * Add a pcall fallback check to verify `WindUI` is loaded as a table before calling `:CreateWindow()`:
     ```lua
     if type(WindUI) ~= "table" or not WindUI.CreateWindow then
         warn("Failed to load WindUI library!")
         return
     end
     ```
   * Ensure Slider parameters match WindUI's latest specification:
     ```lua
     MainTab:Slider({
         Title = "Collect Radius",
         Value = { Min = 10, Max = 100, Default = 35 },
         Step = 5,
         Callback = function(Value) ... end
     })
     ```
