###############################################################################
# CODEXVault_GODOT - README.txt
# Original upstream: https://github.com/FromAriel/CODEXVault_GODOT
# Fork purpose: preserve the original Linux/container setup and add a working
# Windows bootstrap plus validation flow for local Godot use.
###############################################################################

This repository is a Godot tooling bundle, not a complete Godot game project.

What this fork adds:

- `.codex/setup.ps1`
  Windows bootstrap that installs Godot Mono, .NET SDK, GDToolkit, and
  pre-commit into `.\.local\` without requiring admin rights.

- `.codex/validate.ps1`
  Windows validation loop for:
  - `godot --headless --editor --import --quit --path .`
  - `godot --headless --editor --check-only --quit --path .`
  - `dotnet build` when a solution exists

- Updated `README.md`, `AGENTS.md`, and `.codex/AGENTS.md`
  These now describe both the original Linux flow and the Windows fork path.

What stays from upstream:

- `.codex/setup.sh`
  Linux/container bootstrap for CI-style environments.

- `.codex/fix_indent.sh`
  GDScript formatting helper.

- `Godot_Toolscripts/`
  EditorScript utilities you can copy into a Godot project.

Windows quick start:

1. Run:

   powershell -ExecutionPolicy Bypass -File .codex\setup.ps1

2. Then validate:

   powershell -ExecutionPolicy Bypass -File .codex\validate.ps1

Notes:

- The validated local Windows path for Godot 4.6 Mono uses .NET 9.
- The bootstrap puts Godot into self-contained mode so editor state stays under
  `.\.local\` instead of `%APPDATA%`.
- If a repo is not a Godot project yet, validation skips the Godot checks until
  `project.godot` exists.
