# CODEXVault_GODOT

Fork note: this branch is a Windows-compatibility fork/update of the original
`FromAriel/CODEXVault_GODOT` repository. The original Linux/container bootstrap
is still present, and this fork adds a verified local Windows bootstrap and
validation flow for Godot 4.6 Mono.

This repo is a Godot-support toolkit, not a complete Godot game project. The useful parts here are:

- `.codex/setup.sh`: Linux CI/bootstrap script from the original repo.
- `.codex/setup.ps1`: Windows bootstrap added for this workspace.
- `.codex/validate.ps1`: Windows validation loop for Godot import/check/build.
- `Godot_Toolscripts/*.gd`: `EditorScript` utilities you can copy into a Godot project and run from the Godot Script Editor.

## Windows quick start

From the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .codex\setup.ps1
```

That script installs tools into `.\.local\` without requiring admin rights:

- Godot Mono `4.6-stable` into `.\.local\godot-mono\4.6-stable\`
- .NET SDK `9.0` into `.\.local\dotnet\`
- `gdtoolkit` and `pre-commit` into `.\.local\venv\`

The bootstrap also puts the local Godot install into self-contained mode so editor cache/settings stay under `.\.local\` instead of `%APPDATA%`.

Then run the local validation loop:

```powershell
powershell -ExecutionPolicy Bypass -File .codex\validate.ps1
```

If the current repo is not a Godot project yet, the script will skip the Godot checks until a `project.godot` exists.

## Using the Godot toolscripts

These files are plain `EditorScript`s, not an addon/plugin:

- `Godot_Toolscripts/ZZZTool_GD_Gather.gd`
- `Godot_Toolscripts/ZZZTool_TSCN_Gather.gd`

To use them in your own Godot project:

1. Copy the script into your project under `res://`.
2. Open the script in the Godot Script Editor.
3. Run it from `File > Run` in the Script Editor.

`ZZZTool_GD_Gather.gd` writes `res://ZZZScriptCompilation.txt`.
`ZZZTool_TSCN_Gather.gd` writes `res://ZZZscenes_inspector_dump.txt`.

## Notes

- Original upstream: `https://github.com/FromAriel/CODEXVault_GODOT`
- Fork purpose: keep the original Linux setup, add Windows setup and validation,
  and document the verified Godot 4.6 Mono plus .NET 9 workflow.
- The original `readme.txt` is still in the repo, but it documents the Linux/container path.
- This repo still does not include a sample `project.godot`. Add or copy these scripts into a real Godot project before expecting import/check passes to do useful work.
