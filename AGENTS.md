###############################################################################
# Codex Agent Workspace - Tooling Contract and Guide
# Godot 4.6 - Headless - CI-safe - .NET 9 SDK plus Godot Mono included
###############################################################################

[!IMPORTANT]
Indentation: always 4 spaces in `.gd`, `.gdshader`, and `.cs`. Never use tabs.
`gdlint` expects `class_name` before `extends`.

-------------------- SECTION: FIRST-TIME SETUP --------------------

1. Use the built-in Godot CLI on Linux (`/usr/local/bin/godot`) or run
   `.codex/setup.ps1` on Windows to install local tooling into `.\.local\`.
   Override with `GODOT=/full/path/to/godot` or `$env:GODOT=C:\path\to\godot.exe`.

2. Import pass:

   ```bash
   godot --headless --editor --import --quit --path .
   ```

3. Parse all GDScript:

   ```bash
   godot --headless --editor --check-only --quit --path .
   ```

4. Build C#/Mono when a solution exists:

   ```bash
   dotnet build > /tmp/dotnet_build.log
   tail -n 20 /tmp/dotnet_build.log
   ```

Repeat steps 2-4 after edits until all return exit code 0.

Windows local setup:

```powershell
powershell -ExecutionPolicy Bypass -File .codex\setup.ps1
powershell -ExecutionPolicy Bypass -File .codex\validate.ps1
```

-------------------- SECTION: PATCH HYGIENE AND FORMAT --------------------

```bash
.codex/fix_indent.sh $(git diff --name-only --cached -- '*.gd')
gdlint $(git diff --name-only --cached -- '*.gd') || true
dotnet format --verify-no-changes || {
  echo 'C# code-style violations detected.'; exit 1; }
```

No tabs, no syntax errors, no style violations before commit.

-------------------- SECTION: VALIDATION LOOP --------------------

```bash
godot --headless --editor --import --quit --path .
godot --headless --editor --check-only --quit --path .
dotnet build > /tmp/dotnet_build.log
```

Optional tests:

```bash
godot --headless -s res://tests/
dotnet test
cargo test | go test ./... | bun test
```

-------------------- SECTION: QUICK CHECKLIST --------------------

```text
apply_patch
|- gdformat --use-spaces=4 <changed.gd>
|- gdlint <changed.gd> (non-blocking)
|- godot --headless --editor --import --quit --path .
|- godot --headless --editor --check-only --quit --path .
|- dotnet build > /tmp/dotnet_build.log
`- tail -n 20 /tmp/dotnet_build.log
```

-------------------- SECTION: WHY THIS MATTERS --------------------

* `--import` is the only way to build Godot's script-class cache.
* `--check-only` finds GDScript errors.
* `dotnet build` confirms C# compilation when present.

TL;DR: run the three headless commands. Exit 0 means the project is clean.
