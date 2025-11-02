# Termux-Advance-Tools

This installer:

Installs development tools (Python, Node, Ruby, compilers, Java etc.). </br>

Offers a menu to install pentesting & recon tools (nmap, sqlmap, ffuf, wfuzz, gobuster, recon-ng, droopescan, gitleaks, subfinder, amass, etc.).</br>

Can attempt Metasploit and OWASP ZAP (both large).</br>

Adds helper commands like fix-nokogiri and update-all into $PREFIX/bin.</br>

Uses fallbacks (git / pip / go installs) if packages aren’t available in repo.</br>

Uses dialog for a terminal GUI menu if available, otherwise falls back to text menu.</br>


># ⚠️ Warning:
Pentesting tools are powerful. Use them only on systems you own or have explicit permission to test. I won’t support illegal activity.</br>



# How to use !

### 1. In Termux
```
cd install-termux-tools-ultimate.sh
```
### 2. Make it executable and run:
```
chmod +x install-termux-tools-ultimate.sh
```
### 3. and Last run.
```
bash install-termux-tools-ultimate.sh

```

### ⚠️ Warnings & Tips

Metasploit and some tools are large — ensure >2–4 GB free.</br>

Install speed depends on mirror & internet.</br>

Some packages may fail on certain Termux mirrors; installer tolerates failures and attempts fallbacks (git-based installs).</br>

Use pentest tools responsibly and legally.</br>
