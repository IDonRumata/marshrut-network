#!/usr/bin/env bash
# ============================================================
# Скрипт первичной настройки Hetzner CX22 (Ubuntu 24.04 LTS)
# Запускать ОДИН РАЗ после `ssh root@<server_ip>`.
#
# Что делает:
#   1. Обновляет систему
#   2. Создаёт пользователя `andrei` с sudo
#   3. Копирует SSH ключ из root
#   4. Отключает root SSH, отключает пароль-аутентификацию
#   5. Настраивает UFW firewall (только 22, 80, 443)
#   6. Ставит fail2ban
#   7. Ставит Docker + Docker Compose
#   8. Включает unattended-upgrades для security патчей
#   9. Настраивает swap (для CX22 с 4GB RAM — 2GB swap)
#
# Использование:
#   curl -fsSL https://raw.githubusercontent.com/IDonRumata/marshrut-network/main/infra/scripts/setup-server.sh | bash
# ============================================================

set -euo pipefail

# --- Конфигурация (переопредели через env vars) ---
USERNAME="${USERNAME:-andrei}"
SSH_PORT="${SSH_PORT:-22}"
TIMEZONE="${TIMEZONE:-Europe/Warsaw}"

# --- Цвета для логов ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[$(date +'%H:%M:%S')] $*${NC}"; }
warn()  { echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARN: $*${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $*${NC}" >&2; exit 1; }

# --- Проверки ---
[[ "${EUID}" -eq 0 ]] || error "Запускать от root: 'sudo bash setup-server.sh'"
[[ -f /etc/os-release ]] || error "Не найден /etc/os-release"
. /etc/os-release
[[ "${ID}" = "ubuntu" ]] || warn "Не Ubuntu (${ID}), скрипт может работать некорректно"

log "=== Начало настройки сервера ==="
log "Hostname: $(hostname)"
log "IP: $(hostname -I | awk '{print $1}')"
log "User to create: ${USERNAME}"

# ============================================================
# 1. Обновление системы
# ============================================================
log "1/9 Обновление пакетов..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -qq -y
apt-get install -qq -y \
  ca-certificates curl gnupg lsb-release \
  ufw fail2ban unattended-upgrades \
  vim htop ncdu tree jq git \
  software-properties-common

# ============================================================
# 2. Часовой пояс
# ============================================================
log "2/9 Установка часового пояса: ${TIMEZONE}"
timedatectl set-timezone "${TIMEZONE}"

# ============================================================
# 3. Создание пользователя
# ============================================================
if id "${USERNAME}" &>/dev/null; then
  warn "Пользователь ${USERNAME} уже существует, пропускаю создание"
else
  log "3/9 Создание пользователя ${USERNAME}..."
  adduser --disabled-password --gecos "" "${USERNAME}"
  usermod -aG sudo "${USERNAME}"
  echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/90-${USERNAME}"
  chmod 0440 "/etc/sudoers.d/90-${USERNAME}"
fi

# Копируем SSH ключи от root к новому пользователю
if [[ -f /root/.ssh/authorized_keys ]]; then
  log "    Копирую SSH ключи root → ${USERNAME}"
  mkdir -p "/home/${USERNAME}/.ssh"
  cp /root/.ssh/authorized_keys "/home/${USERNAME}/.ssh/authorized_keys"
  chown -R "${USERNAME}:${USERNAME}" "/home/${USERNAME}/.ssh"
  chmod 700 "/home/${USERNAME}/.ssh"
  chmod 600 "/home/${USERNAME}/.ssh/authorized_keys"
else
  warn "У root нет ~/.ssh/authorized_keys — добавь свой SSH ключ вручную в /home/${USERNAME}/.ssh/authorized_keys"
fi

# ============================================================
# 4. Hardening SSH
# ============================================================
log "4/9 Настройка SSH (отключение root, пароля)..."
SSHD_CONFIG="/etc/ssh/sshd_config.d/99-marshrut-hardening.conf"
cat > "${SSHD_CONFIG}" <<EOF
# Marshrut server hardening
Port ${SSH_PORT}
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
X11Forwarding no
AllowAgentForwarding no
ClientAliveInterval 300
ClientAliveCountMax 2
MaxAuthTries 3
LoginGraceTime 30
AllowUsers ${USERNAME}
EOF
sshd -t || error "Невалидная sshd config!"
systemctl restart ssh || systemctl restart sshd

# ============================================================
# 5. UFW Firewall
# ============================================================
log "5/9 Настройка UFW firewall..."
ufw --force reset >/dev/null
ufw default deny incoming
ufw default allow outgoing
ufw allow "${SSH_PORT}/tcp" comment 'SSH'
ufw allow 80/tcp  comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 443/udp comment 'HTTP/3 QUIC'
ufw --force enable

# ============================================================
# 6. fail2ban
# ============================================================
log "6/9 Настройка fail2ban..."
cat > /etc/fail2ban/jail.d/marshrut.conf <<EOF
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled = true
port    = ${SSH_PORT}
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban

# ============================================================
# 7. Docker + Compose
# ============================================================
log "7/9 Установка Docker..."
if ! command -v docker &>/dev/null; then
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -qq -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
fi

usermod -aG docker "${USERNAME}"

# Логи Docker: ротация чтобы не залило диск
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  },
  "live-restore": true
}
EOF
systemctl restart docker

# ============================================================
# 8. Автообновления безопасности
# ============================================================
log "8/9 Включение unattended-upgrades..."
dpkg-reconfigure -plow unattended-upgrades || true
cat > /etc/apt/apt.conf.d/52unattended-upgrades-marshrut <<'EOF'
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "04:00";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
EOF

# ============================================================
# 9. Swap (2GB для CX22 с 4GB RAM)
# ============================================================
if ! swapon --show | grep -q '/swapfile'; then
  log "9/9 Создание 2GB swap..."
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile >/dev/null
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
  sysctl vm.swappiness=10
  echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
else
  log "9/9 Swap уже настроен, пропускаю"
fi

# ============================================================
# Готово
# ============================================================
log "=== Настройка завершена ==="
log ""
log "Следующие шаги:"
log "  1. Выйди из сессии root: exit"
log "  2. Войди как новый пользователь: ssh ${USERNAME}@<server_ip>"
log "  3. Клонируй репо: git clone https://github.com/IDonRumata/marshrut-network.git"
log "  4. Настрой .env в infra/docker/"
log "  5. Запусти: cd marshrut-network/infra/docker && docker compose up -d --build"
log ""
warn "Root SSH ОТКЛЮЧЁН. Залогиниться можно только как '${USERNAME}'."
warn "Парольная аутентификация ОТКЛЮЧЕНА — только по SSH ключу."
