🛑 Disable Web Search – Start Menu Cleanup (Disable-WebSearch_Validate.ps1)

Disables Bing/web search & Cortana suggestions in the Windows Start Menu (HKCU)
*Deaktiviert Bing-Websuche & Cortana-Vorschläge im Windows-Startmenü (HKCU)*

📄 Features
- Sets registry keys:
  - BingSearchEnabled
  - CortanaConsent
  - DisableSearchBoxSuggestions
- Verifies values ("SHOULD vs. ACTUAL")
- Optionally restarts explorer.exe
- Logs to: Downloads\websearch.log

📂 Install
Move file to:
%USERPROFILE%\Downloads

▶️ Usage (EN)
1. Download the file and make sure it is in your Downloads folder
2. Open PowerShell as Administrator
3. Run:
   cd "$env:USERPROFILE\Downloads"
   powershell -ExecutionPolicy Bypass -File ".\Disable-WebSearch_Validate.ps1" -RestartExplorer

▶️ Nutzung (DE)
1. Lade die Datei herunter und stelle sicher, dass sie im Downloads-Ordner liegt
2. PowerShell als Administrator starten
3. Ausführen:
   cd "$env:USERPROFILE\Downloads"
   powershell -ExecutionPolicy Bypass -File ".\Disable-WebSearch_Validate.ps1" -RestartExplorer


📁 Log Output
%USERPROFILE%\Downloads\websearch.log

🧠 Notes | Hinweise
- 🪟 Windows 10 & 11 supported
- 👤 Only affects current user (HKCU)
- ♻️ Safe to re-run anytime
- 🌐 No internet or extra tools needed
