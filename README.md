# Dump Game Roblox

Robust and high-performance Roblox game structure and client script dumper with Fluent UI support.

## Overview

Dump Game Roblox is a client-side utility designed to extract, decompile, and map Roblox game environments. It automatically extracts script sources, generates a complete DataModel tree representation, and formats workspace structures for analysis and AI automation.

## Key Features

- **Full Decompilation**: Extracts and decompiles `LocalScript` and `ModuleScript` instances across allowed services.
- **DataModel Explorer Mapping**: Generates a clean tree representation (`Explorer.txt`) of the game hierarchy.
- **AI Agent Compatible**: Structures output into `Source/`, `GameSource/`, and generates `AGENT.md` for automated development workflows.
- **Cross-Platform Interface**: Built with Fluent UI (Darker Theme) supporting both Desktop and Mobile devices.

## Quick Start

Execute the following script in your Roblox executor environment:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/LOCAL2/Dump_Game_Roblox/main/dump.luau"))()
```

## Directory Structure

Upon execution, the script generates the following folder hierarchy:

```text
Dump-[GUID]/
├── GameSource/    # Decompiled game scripts organized by service path
├── Source/        # Working directory for custom script development
├── Explorer.txt   # ASCII representation of the game DataModel tree
└── AGENT.md       # Environment documentation and guidelines
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
