# 🧰 PowerShell Utility Scripts

A small collection of reliable PowerShell scripts for system and project maintenance.
Each script is **self-contained**, **PS5+ compatible**, and **safe to inspect before execution**.

---

## 🔍 Disable Web Search – Start Menu Cleanup

**Script:** `Disable-WebSearch_Validate.ps1`

Disables Bing/Web search & Cortana suggestions in the Windows Start Menu (`HKCU`).
*Deaktiviert Bing-Websuche & Cortana-Vorschläge im Windows-Startmenü (HKCU).*

### 📄 Features

* Sets registry keys:

  * `BingSearchEnabled`
  * `CortanaConsent`
  * `DisableSearchBoxSuggestions`
* Verifies registry values (“SHOULD vs. ACTUAL”)
* Optionally restarts `explorer.exe`
* Logs to: `%USERPROFILE%\Downloads\websearch.log`

### ▶️ Usage (EN)

```powershell
cd "$env:USERPROFILE\Downloads"
powershell -ExecutionPolicy Bypass -File ".\Disable-WebSearch_Validate.ps1" -RestartExplorer
```

### ▶️ Nutzung (DE)

```powershell
cd "$env:USERPROFILE\Downloads"
powershell -ExecutionPolicy Bypass -File ".\Disable-WebSearch_Validate.ps1" -RestartExplorer
```

### 📁 Log Output

`%USERPROFILE%\Downloads\websearch.log`

### 🧠 Notes | Hinweise

* 🪟 Windows 10 & 11 supported
* 👤 Affects only the current user (HKCU)
* ♻️ Safe to run multiple times
* 🌐 No internet connection required

---

## 🧹 Clean Project – Remove Cache / Build Artifacts

**Script:** `clean-python-project.ps1`

Cleans Python project directories from cache/build artifacts.
By default, it **skips `.venv` and `venv`**, so your environment stays intact.

### 📄 Features

* Removes:

  * `__pycache__`, `.pytest_cache`, `.ruff_cache`, `build`, `dist`, `*.egg-info`, etc.
* Deletes compiled Python files (`*.pyc`, `*.pyo`, etc.)
* Generates a detailed **timestamped report**
* `-WhatIf` mode for dry-runs
* Optional `-IncludeVenv` to also clean inside virtual environments

### ▶️ Usage

Dry run (safe preview):

```powershell
.\clean-python-project.ps1 -WhatIf
```

Actual cleanup:

```powershell
.\clean-python-project.ps1
```

Also clean inside `.venv`:

```powershell
.\clean-python-project.ps1 -IncludeVenv
```

### 📁 Output

`maintenance\clean-report-YYYYMMDD-HHmmss.txt`

### 🧠 Notes

* Works with **Python**, **Node**, or hybrid projects
* Logs deleted paths and warnings
* Does not require admin rights

---

## 🧩 Combine Python Files – Single Text Export

**Script:** `combine-python-files.ps1`

Combines all `.py` files in the project (recursively) into a single text file.
Useful for audits, backups, or quick searches.

### 📄 Features

* Merges all `.py` files into `maintenance\combined_python.txt`
* Skips virtual environments and cache folders (`.venv`, `.git`, `__pycache__`)
* Automatically opens the result in Notepad

### ▶️ Usage

```powershell
.\combine-python-files.ps1
```

### 📁 Output

`maintenance\combined_python.txt`

### 🧠 Notes

* No code execution — text only
* Safe for sharing source snapshots

---

## 🌲 Project Structure Export

**Script:** `project-phython_structure.ps1`

Generates a tree view (`ASCII`) of the project folder structure.

### 📄 Features

* Saves to `maintenance\project-structure.txt` by default
* Use `-ToRoot` to write the file into the project root
* Skips common development folders (`.git`, `.venv`, `build`, `dist`, `node_modules`)
* Fully PS5-compatible, ASCII-safe (no box-drawing characters)

### ▶️ Usage

Default:

```powershell
.\project-phython_structure.ps1
```

Write output in project root:

```powershell
.\project-phython_structure.ps1 -ToRoot
```

### 📁 Output

`maintenance\project-structure.txt`
or (with `-ToRoot`) → `project-structure.txt` in the project root.

### 🧠 Notes

* Ideal for quick documentation
* Output is plain UTF-8 text

---

## 💡 General Recommendations

* Always **run scripts directly** with `.\ScriptName.ps1` (PowerShell does not run from current dir by default).
* Review source before use — all scripts are **commented, offline-safe**, and **transparent**.
* Tested with PowerShell 5.1 and 7.x.
