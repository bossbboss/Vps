#!/bin/bash
set -e

# ==============================
# HARDCODED LOGIN DETAILS
# ==============================

SSH_USER="Dakku"
SSH_PASSWORD="@DAKKUBOSS"

# ==============================
# CREATE SSH USER
# ==============================

echo "Creating SSH user..."

if ! id "$SSH_USER" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "$SSH_USER"
fi

echo "$SSH_USER:$SSH_PASSWORD" | chpasswd

usermod -aG sudo "$SSH_USER"

echo "$SSH_USER ALL=(ALL) NOPASSWD:ALL" \
    > "/etc/sudoers.d/$SSH_USER"

chmod 440 "/etc/sudoers.d/$SSH_USER"

# ==============================
# DAKKU WELCOME BANNER (SHOWS ON LOGIN)
# ==============================

cat > /etc/profile.d/dakku-banner.sh <<'BANNER'
#!/bin/bash
# Only show for interactive shells
case $- in
    *i*) ;;
      *) return;;
esac

# Colors
RESET="\033[0m"
BOLD="\033[1m"
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
DIM="\033[2m"

clear

echo -e "${RED}${BOLD}"
cat <<'ASCII'
██████╗  █████╗ ██╗  ██╗██╗  ██╗██╗   ██╗
██╔══██╗██╔══██╗██║ ██╔╝██║ ██╔╝██║   ██║
██║  ██║███████║█████╔╝ █████╔╝ ██║   ██║
██║  ██║██╔══██║██╔═██╗ ██╔═██╗ ██║   ██║
██████╔╝██║  ██║██║  ██╗██║  ██╗╚██████╔╝
╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝
ASCII
echo -e "${RESET}"

echo -e "${CYAN}${BOLD}        ⚡  W E L C O M E   T O   D A K K U   S E R V E R  ⚡${RESET}"
echo -e "${DIM}${WHITE}        ─────────────────────────────────────────────────${RESET}"

# ---- Info gathering ----
USER_NAME=$(whoami)
HOST_NAME=$(hostname)
OS_NAME=$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')
KERNEL=$(uname -r)
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //')
CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')
CPU_CORES=$(nproc)
MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
MEM_USED=$(free -h | awk '/Mem:/ {print $3}')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_PCT=$(df -h / | awk 'NR==2 {print $5}')
IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')
DATE_NOW=$(date "+%A, %d %B %Y | %I:%M:%S %p")

# ---- Print info ----
printf "${YELLOW}${BOLD}  👤 User      ${RESET}: ${WHITE}%s${RESET}\n" "$USER_NAME"
printf "${YELLOW}${BOLD}  🖥  Host      ${RESET}: ${WHITE}%s${RESET}\n" "$HOST_NAME"
printf "${YELLOW}${BOLD}  🐧 OS        ${RESET}: ${WHITE}%s${RESET}\n" "$OS_NAME"
printf "${YELLOW}${BOLD}  ⚙  Kernel    ${RESET}: ${WHITE}%s${RESET}\n" "$KERNEL"
printf "${YELLOW}${BOLD}  🧠 CPU       ${RESET}: ${WHITE}%s (${CPU_CORES} cores)${RESET}\n" "$CPU_MODEL"
printf "${YELLOW}${BOLD}  💾 Memory    ${RESET}: ${WHITE}%s used / %s total${RESET}\n" "$MEM_USED" "$MEM_TOTAL"
printf "${YELLOW}${BOLD}  🗄  Disk      ${RESET}: ${WHITE}%s used / %s total (%s)${RESET}\n" "$DISK_USED" "$DISK_TOTAL" "$DISK_PCT"
printf "${YELLOW}${BOLD}  🌐 IP        ${RESET}: ${WHITE}%s${RESET}\n" "$IP_ADDR"
printf "${YELLOW}${BOLD}  ⏱  Uptime    ${RESET}: ${WHITE}%s${RESET}\n" "$UPTIME"
printf "${YELLOW}${BOLD}  📅 Date      ${RESET}: ${WHITE}%s${RESET}\n" "$DATE_NOW"

echo ""
echo -e "${GREEN}${BOLD}  ✅ Access Granted. Welcome to the DAKKU zone, boss!${RESET}"
echo -e "${DIM}${WHITE}  ─────────────────────────────────────────────────${RESET}"
echo ""
BANNER

chmod +x /etc/profile.d/dakku-banner.sh

# ==============================
# CONFIGURE SSH
# ==============================

mkdir -p /run/sshd
mkdir -p /etc/ssh/sshd_config.d

cat > /etc/ssh/sshd_config.d/railway.conf <<EOF
Port 22
ListenAddress 0.0.0.0
PasswordAuthentication yes
KbdInteractiveAuthentication no
PermitRootLogin no
UsePAM no
X11Forwarding no
PrintMotd no
ClientAliveInterval 60
ClientAliveCountMax 3
EOF

# Generate SSH host keys
ssh-keygen -A

# Test configuration
/usr/sbin/sshd -t

echo ""
echo "======================================"
echo " SSH SERVER READY"
echo " User: $SSH_USER"
echo " Internal port: 22"
echo "======================================"
echo ""

# Keep container alive with SSH as main process
exec /usr/sbin/sshd -D -e