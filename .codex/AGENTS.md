<!--
###############################################################################
# Codex Agent Workspace - Tooling Contract and Guide
# Godot 4.6 - Headless - CI-safe - .NET 9 SDK plus Godot Mono included
###############################################################################
-->

```text
###############################################################################
# Codex Agent Workspace - Tooling Contract and Guide
# Godot 4.6 - Headless - CI-safe - .NET 9 SDK plus Godot Mono included
###############################################################################
```

> [!IMPORTANT]
>
> * Indentation: always 4 spaces in `.gd`, `.gdshader`, and `.cs`.
> * `gdlint` expects `class_name` before `extends`.
> * Do not add binary files to PRs.
> * Do not use `.gdignore` to hide errors. Fix them.

## Godot First-Time Setup

1. Use `/usr/local/bin/godot` on Linux, or run `.codex/setup.ps1` on Windows.
2. Override with `GODOT=/full/path/to/godot` or `$env:GODOT=C:\path\to\godot.exe`.
3. Windows local bootstrap installs into `.\.local\`:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .codex\setup.ps1
   ```

4. Validate with:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .codex\validate.ps1
   ```

Linux validation loop:

```bash
godot --headless --editor --import --quit --path . --quiet
godot --headless --editor --check-only --quit --path . --quiet
dotnet build --no-restore --nologo
```

## Patch Hygiene and Format

Respect folders listed in `.codexignore`. They are read-only for agent edits.

```bash
.codex/fix_indent.sh $(git diff --name-only --cached -- '*.gd') >/dev/null
gdlint $(git diff --name-only --cached -- '*.gd') || true
dotnet format --verify-no-changes --nologo --severity hidden || {
  echo 'C# style violations'; exit 1; }
```

Rules:

* No tabs, no syntax errors, no style violations before commit.
* No binaries in PRs.
* Fix validation errors instead of suppressing them.

## Quick Checklist

```text
apply_patch
|- gdformat --use-spaces=4 <changed.gd>
|- gdlint <changed.gd>
|- godot --headless --editor --import --quit --path . --quiet
|- godot --headless --editor --check-only --quit --path . --quiet
`- dotnet build --no-restore --nologo
```
