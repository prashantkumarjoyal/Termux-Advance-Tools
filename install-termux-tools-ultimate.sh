#!/data/data/com.termux/files/usr/bin/bash
# Termux Ultimate Tools Installer (Hindi dialog menu + extra pentest tools)
# Author: JOYAL Services
# Website: https://www.joyalservices.in

set -e
PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
BIN="$PREFIX/bin"
DIALOG_PKG="dialog"

# Ensure basic environment
echo "Updating packages..."
pkg update -y && pkg upgrade -y

echo "Installing required base packages..."
pkg install -y coreutils git curl wget nano proot pv openssh python nodejs ruby clang make pkg-config zlib unzip tar coreutils

# Install dialog for GUI menu (if available)
pkg install -y $DIALOG_PKG || true

mkdir -p "$BIN"

# helper functions
info(){ echo -e "\n[INFO] $1\n"; }
warn(){ echo -e "\n[WARN] $1\n"; }
try_pkg(){ pkg install -y "$@" || true; }

# Create helper commands (same as earlier)
cat > "$BIN/update-all" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
echo "Running full update + cleanup..."
pkg update -y && pkg upgrade -y
pkg autoclean -y || true
pkg autoremove -y || true
pip install --upgrade pip setuptools wheel || true
npm i -g npm || true
gem update --system || true
echo "Done."
EOF
chmod 755 "$BIN/update-all"

cat > "$BIN/fix-nokogiri" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -e
echo "Running nokogiri fix..."
pkg install -y clang make pkg-config coreutils libxml2 libxslt zlib libiconv git || true
if [ ! -f "$PREFIX/include/gumbo.h" ]; then
  cd $HOME
  git clone https://github.com/google/gumbo-parser.git gumbo-parser-temp || true
  cd gumbo-parser-temp
  make || true
  make install PREFIX=$PREFIX || true
  cd $HOME
  rm -rf gumbo-parser-temp
fi
chmod -R 755 $PREFIX/include || true
if [ ! -f "$PREFIX/include/nokogiri_gumbo.h" ]; then
  cp -f $PREFIX/include/gumbo.h $PREFIX/include/nokogiri_gumbo.h || ln -sf $PREFIX/include/gumbo.h $PREFIX/include/nokogiri_gumbo.h || true
fi
export CFLAGS="-I$PREFIX/include"
export LDFLAGS="-L$PREFIX/lib"
gem install nokogiri -- --use-system-libraries || gem install nokogiri -v '1.13.10' -- --use-system-libraries || true
echo "Done. Test: ruby -r nokogiri -e 'puts Nokogiri::VERSION'"
EOF
chmod 755 "$BIN/fix-nokogiri"

# Core installers (functions)
install_dev(){
  info "Installing development environment..."
  try_pkg python python-pip ruby nodejs clang make cmake git build-essential pkg-config openjdk-17
  pip install --upgrade pip setuptools wheel || true
  gem install bundler || true
  npm i -g npm || true
  info "Dev tools installed."
}

install_common_pentest(){
  info "Installing common pentest packages..."
  try_pkg nmap hydra nikto dirb whatweb sqlmap gobuster wfuzz gobuster hashcat john net-tools
  try_pkg ffuf wfuzz gobuster || true
  # sqlmap fallback
  if ! command -v sqlmap >/dev/null 2>&1; then
    cd $HOME
    rm -rf sqlmap || true
    git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git sqlmap || true
    ln -sf $HOME/sqlmap/sqlmap.py $PREFIX/bin/sqlmap || true
  fi
  # ffuf fallback: try to install via prebuilt or repo
  if ! command -v ffuf >/dev/null 2>&1; then
    try_pkg ffuf || true
  fi
  # dirsearch
  if ! command -v dirsearch >/dev/null 2>&1; then
    cd $HOME
    rm -rf dirsearch || true
    git clone --depth 1 https://github.com/maurosoria/dirsearch.git dirsearch || true
    ln -sf $HOME/dirsearch/dirsearch.py $PREFIX/bin/dirsearch || true
  fi
  info "Common pentest tools installed (where available)."
}

install_recon_tools(){
  info "Installing recon-ng, droopescan, gitleaks, subfinder, amass (where possible)..."
  # pip tools
  pip install --no-cache-dir recon-ng droopescan || true
  # gitleaks
  if ! command -v gitleaks >/dev/null 2>&1; then
    # try go or prebuilt; if no go, try git release download
    try_pkg golang || true
    if command -v go >/dev/null 2>&1; then
      GOPATH=$HOME/go
      mkdir -p $GOPATH
      export GOPATH
      go install github.com/zricethezav/gitleaks/v8@latest || true
      ln -sf $GOPATH/bin/gitleaks $PREFIX/bin/gitleaks || true
    else
      # try git-based fallback (may not build)
      cd $HOME
      rm -rf gitleaks || true
      git clone --depth 1 https://github.com/zricethezav/gitleaks.git gitleaks || true
    fi
  fi
  # subfinder (go)
  if ! command -v subfinder >/dev/null 2>&1; then
    try_pkg golang || true
    if command -v go >/dev/null 2>&1; then
      go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest || true
      ln -sf $HOME/go/bin/subfinder $PREFIX/bin/subfinder || true
    fi
  fi
  # amass
  try_pkg amass || true
  info "Recon tools attempted."
}

install_metasploit(){
  info "Installing Metasploit (large) — ensure >2GB free space."
  try_pkg unstable-repo || true
  try_pkg metasploit || true
  if ! command -v msfconsole >/dev/null 2>&1; then
    info "Packaged Metasploit not found, attempting fallback installer (may fail on limited devices)..."
    cd $HOME
    rm -rf metasploit-framework || true
    git clone --depth 1 https://github.com/rapid7/metasploit-framework.git metasploit-framework || true
    cd metasploit-framework
    gem install bundler || true
    bundle install || true
    ln -sf $HOME/metasploit-framework/msfconsole $PREFIX/bin/msfconsole || true
  fi
  info "Metasploit install attempted."
}

install_zap(){
  info "Installing OWASP ZAP (may be heavy). Using zaproxy (Java)."
  try_pkg openjdk-17 wget curl || true
  cd $HOME
  ZAP_VER="2.13.0"
  ZAP_DIR="$HOME/zap"
  mkdir -p $ZAP_DIR
  # download the lightweight standalone if available
  if [ ! -f "$ZAP_DIR/ZAP_2.13.0_unix.sh" ]; then
    wget -q --no-check-certificate "https://github.com/zaproxy/zaproxy/releases/download/v$ZAP_VER/ZAP_$ZAP_VER_unix.sh" -O "$ZAP_DIR/ZAP_$ZAP_VER_unix.sh" || true
  fi
  info "To run ZAP: bash $ZAP_DIR/ZAP_$ZAP_VER_unix.sh  (may require X or headless mode)."
}

install_web_helpers(){
  info "Installing web helpers: nikto, wfuzz, ffuf, gobuster, nikto..."
  try_pkg nikto wfuzz gobuster ffuf || true
  info "Web helpers attempted."
}

install_code_server(){
  info "Installing code-server (VS Code in browser) via npm..."
  try_pkg nodejs npm || true
  npm i -g code-server || true
  info "Start code-server: code-server --host 0.0.0.0 --auth none --port 8080"
}

# Dialog menu (Hindi)
if command -v dialog >/dev/null 2>&1; then
  OPTION=$(dialog --stdout --title "Termux Ultimate Installer" \
    --menu "Chuno: (Use arrow keys)" 15 60 10 \
    1 "Install development tools (Python, Ruby, Node, build tools)" \
    2 "Install common pentest tools (nmap, sqlmap, wfuzz, ffuf, gobuster...)" \
    3 "Install recon tools (recon-ng, droopescan, gitleaks, subfinder, amass)" \
    4 "Install Metasploit" \
    5 "Install OWASP ZAP (Java; heavy)" \
    6 "Install web helpers & scanners" \
    7 "Install code-server (VSCode)" \
    8 "Install EVERYTHING (recommended if space available)" \
    9 "Exit" )
else
  echo "Dialog not available — using text menu (Hindi)."
  echo "1) Dev tools"
  echo "2) Common pentest tools"
  echo "3) Recon tools"
  echo "4) Metasploit"
  echo "5) OWASP ZAP"
  echo "6) Web helpers"
  echo "7) code-server"
  echo "8) Install EVERYTHING"
  echo "9) Exit"
  read -rp "Apna option chuno (1-9): " OPTION
fi

case "$OPTION" in
  1) install_dev ;;
  2) install_common_pentest ;;
  3) install_recon_tools ;;
  4) install_metasploit ;;
  5) install_zap ;;
  6) install_web_helpers ;;
  7) install_code_server ;;
  8)
     install_dev
     install_common_pentest
     install_recon_tools
     install_metasploit
     install_zap
     install_web_helpers
     install_code_server
     ;;
  *) echo "Exiting. Tools installed in $PREFIX/bin (fix-nokogiri available)." ;;
esac

echo "Installer finished. Useful commands added: fix-nokogiri, update-all (in $PREFIX/bin)."
echo "Use 'fix-nokogiri' if nokogiri gem build fails."
echo "Reminder: Use pentest tools only on systems you own or have permission to test."
