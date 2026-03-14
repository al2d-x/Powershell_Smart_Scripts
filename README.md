# PowerShell Utility Scripts

A small collection of self-contained PowerShell scripts for system and project maintenance.

All scripts are:
- compatible with PowerShell 5+
- safe to inspect before execution
- designed to be rerun safely where applicable

---

## Disable Start Menu Web Search

**Script:** `Disable-WebSearch_Validate.ps1`

Disables Bing/web search and Cortana suggestions in the Windows Start Menu for the current user (`HKCU`).

### What it does
- Sets these registry values:
  - `BingSearchEnabled`
  - `CortanaConsent`
  - `DisableSearchBoxSuggestions`
- Verifies expected vs. actual registry values
- Optionally restarts `explorer.exe`
- Writes a log file to `%USERPROFILE%\Downloads\websearch.log`

### Usage
```powershell
cd "$env:USERPROFILE\Downloads"
powershell -ExecutionPolicy Bypass -File ".\Disable-WebSearch_Validate.ps1" -RestartExplorer
````

### Notes

* Supports Windows 10 and 11
* Affects only the current user
* Can be run multiple times safely
* No internet connection required

---

## Install PowerShell 7 and .NET 8

**Script:** `setup-pwsh7-dotnet8.ps1`

Installs or updates:

* PowerShell 7
* .NET 8 Runtime
* .NET 8 SDK

The script checks existing versions, installs missing components with `winget`, and logs the full process.

### What it does

* Installs or upgrades:

  * `Microsoft.PowerShell`
  * `Microsoft.DotNet.Runtime.8`
  * `Microsoft.DotNet.SDK.8`
* Verifies installed versions and executable paths
* Writes a transcript log to `%ProgramData%\SetupLogs\setup-pwsh-dotnet8_YYYYMMDD-HHMMSS.log`
* Exits if not run as Administrator

### Usage

```powershell
cd "$env:USERPROFILE\Downloads"
powershell -ExecutionPolicy Bypass -File ".\setup-pwsh7-dotnet8.ps1"
```

### Notes

* Requires Windows 10 or 11
* Requires `winget`
* Must be run as Administrator
* Can be run multiple times safely
* Uses official Microsoft packages only

---

## Clean Project Artifacts

**Script:** `clean-python-project.ps1`

Removes common cache and build artifacts from Python projects. By default, virtual environments such as `.venv` and `venv` are skipped.

### What it does

* Removes directories such as:

  * `__pycache__`
  * `.pytest_cache`
  * `.ruff_cache`
  * `build`
  * `dist`
  * `*.egg-info`
* Deletes compiled Python files such as `*.pyc` and `*.pyo`
* Creates a timestamped cleanup report
* Supports `-WhatIf` for dry runs
* Supports `-IncludeVenv` to include virtual environments

### Usage

Dry run:

```powershell
.\clean-python-project.ps1 -WhatIf
```

Run cleanup:

```powershell
.\clean-python-project.ps1
```

Include virtual environments:

```powershell
.\clean-python-project.ps1 -IncludeVenv
```

### Output

`maintenance\clean-report-YYYYMMDD-HHmmss.txt`

### Notes

* Works for Python, Node, or mixed projects
* No admin rights required

---

## Combine Python Files

**Script:** `combine-python-files.ps1`

Combines all `.py` files in the project into a single text file.

### What it does

* Recursively collects `.py` files
* Skips folders such as `.venv`, `.git`, and `__pycache__`
* Writes output to `maintenance\combined_python.txt`
* Opens the result in Notepad

### Usage

```powershell
.\combine-python-files.ps1
```

### Output

`maintenance\combined_python.txt`

### Notes

* Exports text only
* Does not execute code

---

## Export Project Structure

**Script:** `project-phython_structure.ps1`

Generates an ASCII tree view of the project folder structure.

### What it does

* Saves output to `maintenance\project-structure.txt` by default
* Supports `-ToRoot` to write the file in the project root
* Skips common development folders such as:

  * `.git`
  * `.venv`
  * `build`
  * `dist`
  * `node_modules`

### Usage

Default output:

```powershell
.\project-phython_structure.ps1
```

Write to project root:

```powershell
.\project-phython_structure.ps1 -ToRoot
```

### Output

* `maintenance\project-structure.txt`
* or `project-structure.txt` in the project root when using `-ToRoot`

### Notes

* Plain UTF-8 text output
* Useful for documentation and quick project overviews

---

## Recommendations

* Run scripts from the current directory with:

  ```powershell
  .\ScriptName.ps1
  ```
* Review scripts before execution
* Tested with PowerShell 5.1 and 7.x
