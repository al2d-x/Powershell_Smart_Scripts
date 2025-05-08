# 🛑 Disable Web Search – Start Menu Cleanup
**Script:** `Disable-WebSearch_Validate.ps1`

Disables Bing/web search & Cortana suggestions in the Windows Start Menu (HKCU)  
*Deaktiviert Bing-Websuche & Cortana-Vorschläge im Windows-Startmenü (HKCU)*

---

## 📄 Features
- Sets registry keys:
  - `BingSearchEnabled`
  - `CortanaConsent`
  - `DisableSearchBoxSuggestions`
- Verifies registry values ("SHOULD vs. ACTUAL")
- Optionally restarts `explorer.exe`
- Logs to: `%USERPROFILE%\Downloads\websearch.log`

---

## 📂 Installation
Place the script in your **Downloads** folder:  
`%USERPROFILE%\Downloads`

---

## ▶️ Usage (EN)
1. Download the file and ensure it's in your **Downloads** folder
2. Open **PowerShell as Administrator**
3. Run the following commands:

   ```powershell
   cd "$env:USERPROFILE\Downloads"
   powershell -ExecutionPolicy Bypass -File ".\Disable-WebSearch_Validate.ps1" -RestartExplorer
   ```

---

## ▶️ Nutzung (DE)
1. Lade die Datei herunter und stelle sicher, dass sie im **Downloads-Ordner** liegt
2. Öffne **PowerShell als Administrator**
3. Führe folgende Befehle aus:

   ```powershell
   cd "$env:USERPROFILE\Downloads"
   powershell -ExecutionPolicy Bypass -File ".\Disable-WebSearch_Validate.ps1" -RestartExplorer
   ```

---

## 📁 Log Output
Ergebnisse werden gespeichert unter:  
`%USERPROFILE%\Downloads\websearch.log`

---

## 🧠 Notes | Hinweise
- 🪟 Windows 10 & 11 supported  
- 👤 Affects **only the current user (HKCU)**  
- ♻️ Safe to run multiple times  
- 🌐 No internet connection or extra tools needed

