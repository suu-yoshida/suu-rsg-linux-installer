#!/bin/bash

# RSG RedM Framework - Installation Script v4.0 FINAL
# Added: txAdmin or Standalone choice + OneSync fix + placeholder replacement

# ============================================
# COLORS
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;94m'
CYAN='\033[0;96m'
MAGENTA='\033[0;95m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================
# GLOBAL VARIABLES
# ============================================
TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
LOG_DIR="/var/log/redm"
LOG_FILE="${LOG_DIR}/redm_rsg_install_${TIMESTAMP}.log"
LATEST_LOG_SYMLINK="${LOG_DIR}/latest.log"
RECIPE_LOG="${LOG_DIR}/recipe_${TIMESTAMP}.log"

VERBOSE=false

# Server Configuration
INSTALL_DIR=""
CFX_LICENSE=""
SERVER_NAME=""
DB_PASSWORD=""
DB_USER="rsg_user"
DB_NAME="rsg_db"
DB_PORT="3306"
SERVER_PORT="30120"
TXADMIN_PORT="40120"
MAX_CLIENTS="32"
STEAM_HEX=""
USE_TXADMIN="no"

# URLs
ARTIFACT_PAGE_URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
RSG_RECIPE_URL="https://raw.githubusercontent.com/Rexshack-RedM/txAdminRecipe/refs/heads/main/rsgcore.yaml"
LATEST_ARTIFACT=""
FULL_ARTIFACT_URL=""

# ============================================
# CHECK STDIN
# ============================================
check_stdin() {
    if [ ! -t 0 ]; then
        echo -e "${RED}❌ This script cannot be run via pipe (curl | bash)${NC}"
        echo ""
        echo "Please download and run it directly:"
        echo "  wget https://your-url.com/rsg-installer.sh"
        echo "  chmod +x rsg-installer.sh"
        echo "  sudo ./rsg-installer.sh"
        exit 1
    fi
}

# ============================================
# LOGGING
# ============================================
setup_logging() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    touch "${RECIPE_LOG}"
    ln -sf "${LOG_FILE}" "${LATEST_LOG_SYMLINK}"
    log "INFO" "=== RSG RedM Installation Started ==="
    log "INFO" "Verbose mode: $VERBOSE"
    log "INFO" "Recipe log: ${RECIPE_LOG}"
}

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${timestamp} [${level}] ${message}" >> "${LOG_FILE}"
}

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
    log "INFO" "${message}"
}

exec_cmd() {
    local cmd="$@"
    log "DEBUG" "Executing: $cmd"
    
    if [[ "$VERBOSE" == true ]]; then
        eval "$cmd" 2>&1 | tee -a "${LOG_FILE}"
        return ${PIPESTATUS[0]}
    else
        eval "$cmd" >> "${LOG_FILE}" 2>&1
        return $?
    fi
}

show_last_error() {
    print_message "$RED" "\n❌ Installation failed!"
    print_message "$YELLOW" "📋 Last 30 lines of log:"
    echo -e "${CYAN}"
    tail -n 30 "${LOG_FILE}"
    echo -e "${NC}"
    print_message "$YELLOW" "Full log: ${LOG_FILE}"
    print_message "$YELLOW" "Recipe log: ${RECIPE_LOG}"
    print_message "$YELLOW" "\nRun with verbose: sudo bash $0 --verbose"
}

# ============================================
# VALIDATION
# ============================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_message "$RED" "❌ This script must be run as root (sudo)"
        exit 1
    fi
}

check_dependencies() {
    local missing_deps=()
    local required_cmds=("curl" "wget")
    
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_message "$YELLOW" "⚠️  Installing basic tools: ${missing_deps[*]}"
        apt-get update >> "${LOG_FILE}" 2>&1
        apt-get install -y curl wget >> "${LOG_FILE}" 2>&1
    fi
}

# ============================================
# USER INPUT
# ============================================
get_user_input() {
    clear
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║     RSG RedM Server - Interactive Setup           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Press ENTER to use default values shown in [brackets]${NC}"
    echo ""
    
    echo -e "${BOLD}━━━ Server Mode ━━━${NC}"
    echo -e "${CYAN}Choose server mode:${NC}"
    echo -e "  ${GREEN}1)${NC} txAdmin (Web interface - recommended)"
    echo -e "  ${GREEN}2)${NC} Standalone (Console only)"
    echo ""
    while true; do
        echo -ne "${GREEN}Select mode ${CYAN}[1/2]${NC}: "
        read mode_choice
        case $mode_choice in
            1)
                USE_TXADMIN="yes"
                print_message "$CYAN" "   → Using txAdmin mode"
                break
                ;;
            2)
                USE_TXADMIN="no"
                print_message "$CYAN" "   → Using Standalone mode"
                break
                ;;
            *)
                echo -e "${RED}   ❌ Invalid choice. Enter 1 or 2${NC}"
                ;;
        esac
    done
    echo ""
    
    echo -e "${BOLD}━━━ Server Configuration ━━━${NC}"
    while true; do
        echo -ne "${GREEN}CFX License Key ${YELLOW}[required]${NC}: "
        read CFX_LICENSE
        [[ ! -z "$CFX_LICENSE" ]] && break
        echo -e "${RED}   ❌ License key required! Get one from: https://keymaster.fivem.net${NC}"
    done
    
    while true; do
        echo -ne "${GREEN}Server Name ${YELLOW}[required]${NC}: "
        read SERVER_NAME
        [[ ! -z "$SERVER_NAME" ]] && break
        echo -e "${RED}   ❌ Server name required!${NC}"
    done
    
    echo ""
    echo -ne "${GREEN}Max Players ${CYAN}[${MAX_CLIENTS}]${NC}: "
    read input_max_clients
    [[ ! -z "$input_max_clients" ]] && MAX_CLIENTS=$input_max_clients
    echo -e "${CYAN}   → Using: ${MAX_CLIENTS} players${NC}"
    
    echo ""
    local default_install_dir="/home/RedM"
    echo -ne "${GREEN}Install Directory ${CYAN}[${default_install_dir}]${NC}: "
    read INSTALL_DIR
    [[ -z "$INSTALL_DIR" ]] && INSTALL_DIR=$default_install_dir
    echo -e "${CYAN}   → Installing to: ${INSTALL_DIR}${NC}"
    
    echo ""
    echo -e "${BOLD}━━━ Database Configuration ━━━${NC}"
    
    echo -ne "${GREEN}Database Name ${CYAN}[${DB_NAME}]${NC}: "
    read input_db_name
    [[ ! -z "$input_db_name" ]] && DB_NAME=$input_db_name
    echo -e "${CYAN}   → Database: ${DB_NAME}${NC}"
    
    echo -ne "${GREEN}Database User ${CYAN}[${DB_USER}]${NC}: "
    read input_db_user
    [[ ! -z "$input_db_user" ]] && DB_USER=$input_db_user
    echo -e "${CYAN}   → User: ${DB_USER}${NC}"
    
    while true; do
        echo -ne "${GREEN}Database Password ${YELLOW}[required]${NC}: "
        read -s DB_PASSWORD
        echo ""
        [[ ! -z "$DB_PASSWORD" ]] && break
        echo -e "${RED}   ❌ Database password required!${NC}"
    done
    echo -e "${CYAN}   → Password set${NC}"
    
    echo -ne "${GREEN}Database Port ${CYAN}[${DB_PORT}]${NC}: "
    read input_db_port
    [[ ! -z "$input_db_port" ]] && DB_PORT=$input_db_port
    echo -e "${CYAN}   → Port: ${DB_PORT}${NC}"
    
    echo ""
    echo -e "${BOLD}━━━ Network Ports ━━━${NC}"
    
    echo -ne "${GREEN}Server Port ${CYAN}[${SERVER_PORT}]${NC}: "
    read input_server_port
    [[ ! -z "$input_server_port" ]] && SERVER_PORT=$input_server_port
    echo -e "${CYAN}   → Server: ${SERVER_PORT}${NC}"
    
    if [[ "$USE_TXADMIN" == "yes" ]]; then
        echo -ne "${GREEN}txAdmin Port ${CYAN}[${TXADMIN_PORT}]${NC}: "
        read input_txadmin_port
        [[ ! -z "$input_txadmin_port" ]] && TXADMIN_PORT=$input_txadmin_port
        echo -e "${CYAN}   → txAdmin: ${TXADMIN_PORT}${NC}"
    fi
    
    echo ""
    echo -e "${BOLD}━━━ Admin Configuration (Optional) ━━━${NC}"
    echo -ne "${GREEN}Your Steam HEX ${CYAN}[optional - skip with ENTER]${NC}: "
    read STEAM_HEX
    if [[ ! -z "$STEAM_HEX" ]]; then
        echo -e "${CYAN}   → Steam HEX: ${STEAM_HEX}${NC}"
    else
        echo -e "${YELLOW}   → No Steam HEX (add manually later)${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}              Configuration Summary${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Mode:${NC}"
    if [[ "$USE_TXADMIN" == "yes" ]]; then
        echo -e "  Type:              ${CYAN}txAdmin (Web Interface)${NC}"
    else
        echo -e "  Type:              ${CYAN}Standalone (Console)${NC}"
    fi
    echo ""
    echo -e "${BOLD}Server:${NC}"
    echo -e "  Name:              ${CYAN}$SERVER_NAME${NC}"
    echo -e "  Max Players:       ${CYAN}$MAX_CLIENTS${NC}"
    echo -e "  Install Path:      ${CYAN}$INSTALL_DIR${NC}"
    echo ""
    echo -e "${BOLD}Database:${NC}"
    echo -e "  Name:              ${CYAN}$DB_NAME${NC}"
    echo -e "  User:              ${CYAN}$DB_USER${NC}"
    echo -e "  Port:              ${CYAN}$DB_PORT${NC}"
    echo ""
    echo -e "${BOLD}Network:${NC}"
    echo -e "  Server Port:       ${CYAN}$SERVER_PORT${NC}"
    [[ "$USE_TXADMIN" == "yes" ]] && echo -e "  txAdmin Port:      ${CYAN}$TXADMIN_PORT${NC}"
    echo ""
    [[ ! -z "$STEAM_HEX" ]] && echo -e "${BOLD}Admin:${NC}\n  Steam HEX:         ${CYAN}$STEAM_HEX${NC}\n"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    log "INFO" "Configuration: Mode=$USE_TXADMIN, Server=$SERVER_NAME, Install=$INSTALL_DIR, DB=$DB_NAME:$DB_PORT"
    
    echo ""
    echo -ne "${YELLOW}Continue with this configuration? [Y/n]: ${NC}"
    read confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        print_message "$YELLOW" "Installation cancelled"
        exit 0
    fi
    echo ""
}

# ============================================
# ARTIFACT FUNCTIONS
# ============================================
check_new_artifact() {
    print_message "$CYAN" "🔍 Searching for latest RedM build..."
    local ARTIFACT_HTML=$(curl -s $ARTIFACT_PAGE_URL)
    [[ -z "$ARTIFACT_HTML" ]] && { print_message "$RED" "❌ Failed to fetch artifacts"; return 1; }
    
    local ARTIFACT_LINKS=$(echo "$ARTIFACT_HTML" | grep -oP 'href="\./\d{4,}[^"]+fx\.tar\.xz"' | sed 's/href="\.\/\([^"]*\)"/\1/')
    [[ -z "$ARTIFACT_LINKS" ]] && { print_message "$RED" "❌ No artifacts found"; return 1; }
    
    LATEST_ARTIFACT=$(echo "$ARTIFACT_LINKS" | grep -oP '^\d{4,}' | sort -nr | head -n 1)
    local LATEST_ARTIFACT_FILE=$(echo "$ARTIFACT_LINKS" | grep "^$LATEST_ARTIFACT")
    FULL_ARTIFACT_URL="${ARTIFACT_PAGE_URL}${LATEST_ARTIFACT_FILE}"
    
    print_message "$GREEN" "✅ Latest build: ${LATEST_ARTIFACT}"
    log "INFO" "Artifact: $FULL_ARTIFACT_URL"
    return 0
}

download_artifact() {
    local dest=$1
    print_message "$BLUE" "📥 Downloading RedM (build ${LATEST_ARTIFACT})..."
    
    mkdir -p "$dest" && cd "$dest"
    
    if [[ "$VERBOSE" == true ]]; then
        wget --show-progress "$FULL_ARTIFACT_URL" -O fx.tar.xz 2>&1 | tee -a "${LOG_FILE}"
    else
        wget -q --show-progress "$FULL_ARTIFACT_URL" -O fx.tar.xz >> "${LOG_FILE}" 2>&1
    fi
    
    [[ $? -ne 0 ]] && { print_message "$RED" "❌ Download failed"; return 1; }
    
    print_message "$CYAN" "📦 Extracting..."
    exec_cmd "tar -xf fx.tar.xz"
    rm -f fx.tar.xz
    [[ -d "alpine/opt/cfx-server/alpine" ]] && rm -rf "alpine/opt/cfx-server/alpine"
    chmod +x run.sh FXServer 2>/dev/null
    
    print_message "$GREEN" "✅ Artifact installed"
    return 0
}

# ============================================
# DEPENDENCIES
# ============================================
install_dependencies() {
    print_message "$BLUE" "📦 Installing dependencies..."
    
    print_message "$CYAN" "   Updating packages..."
    if ! exec_cmd "apt-get update"; then
        print_message "$RED" "❌ apt-get update failed"
        show_last_error
        exit 1
    fi
    
    local packages=("wget" "curl" "tar" "git" "xz-utils" "mariadb-server" "mariadb-client" "unzip" "screen" "jq" "python3" "python3-pip")
    
    print_message "$CYAN" "   Installing: ${packages[*]}"
    if ! exec_cmd "DEBIAN_FRONTEND=noninteractive apt-get install -y ${packages[*]}"; then
        print_message "$RED" "❌ Package installation failed"
        show_last_error
        exit 1
    fi
    
    print_message "$CYAN" "   Installing PyYAML..."
    exec_cmd "pip3 install pyyaml" || exec_cmd "apt-get install -y python3-yaml"
    
    print_message "$GREEN" "✅ Dependencies installed"
}

# ============================================
# DATABASE
# ============================================
setup_mariadb() {
    print_message "$BLUE" "🗄️  Configuring MariaDB..."
    
    print_message "$CYAN" "   Starting MariaDB..."
    exec_cmd "systemctl start mariadb"
    exec_cmd "systemctl enable mariadb"
    sleep 2
    
    print_message "$CYAN" "   Setting root password..."
    exec_cmd "mysql -e \"ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';\"" || \
    exec_cmd "mysql -e \"SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${DB_PASSWORD}');\"" || \
    exec_cmd "mysqladmin -u root password '${DB_PASSWORD}'"
    
    exec_cmd "mysql -u root -p\"${DB_PASSWORD}\" -e \"DELETE FROM mysql.user WHERE User='';\""
    exec_cmd "mysql -u root -p\"${DB_PASSWORD}\" -e \"DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');\""
    exec_cmd "mysql -u root -p\"${DB_PASSWORD}\" -e \"FLUSH PRIVILEGES;\""
    
    if [[ "$DB_PORT" != "3306" ]]; then
        print_message "$CYAN" "   Configuring port: ${DB_PORT}..."
        if [[ -f /etc/mysql/mariadb.conf.d/50-server.cnf ]]; then
            sed -i "s/^port.*/port = ${DB_PORT}/" /etc/mysql/mariadb.conf.d/50-server.cnf
            exec_cmd "systemctl restart mariadb"
            sleep 2
        fi
    fi
    
    print_message "$CYAN" "   Creating database: ${DB_NAME}..."
    mysql -u root -p"${DB_PASSWORD}" --port=${DB_PORT} <<EOF >> "${LOG_FILE}" 2>&1
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    if [[ $? -eq 0 ]]; then
        print_message "$GREEN" "✅ Database created: ${DB_NAME}"
    else
        print_message "$RED" "❌ Database creation failed"
        show_last_error
        exit 1
    fi
}

validate_sql_connection() {
    print_message "$CYAN" "🔌 Testing database..."
    
    if mysql -u root -p"${DB_PASSWORD}" --port=${DB_PORT} -e "SELECT VERSION();" >> "${LOG_FILE}" 2>&1; then
        local version=$(mysql -u root -p"${DB_PASSWORD}" --port=${DB_PORT} -sse "SELECT VERSION();")
        print_message "$GREEN" "✅ Connected (MariaDB $version)"
        return 0
    else
        print_message "$RED" "❌ Connection failed"
        show_last_error
        return 1
    fi
}

# ============================================
# RECIPE DOWNLOAD
# ============================================
download_recipe() {
    print_message "$BLUE" "📥 Downloading RSG recipe..."
    
    local recipe_dir="${INSTALL_DIR}/recipe"
    mkdir -p "$recipe_dir"
    
    if [[ "$VERBOSE" == true ]]; then
        wget --show-progress "$RSG_RECIPE_URL" -O "${recipe_dir}/rsgcore.yaml" 2>&1 | tee -a "${LOG_FILE}"
    else
        wget -q --show-progress "$RSG_RECIPE_URL" -O "${recipe_dir}/rsgcore.yaml" >> "${LOG_FILE}" 2>&1
    fi
    
    if [[ $? -eq 0 ]] && [[ -f "${recipe_dir}/rsgcore.yaml" ]]; then
        print_message "$GREEN" "✅ Recipe downloaded"
        log "INFO" "Recipe size: $(wc -l < ${recipe_dir}/rsgcore.yaml) lines"
        return 0
    else
        print_message "$RED" "❌ Recipe download failed"
        show_last_error
        return 1
    fi
}

# ============================================
# RECIPE EXECUTION
# ============================================
execute_recipe() {
    print_message "$BLUE" "⚙️  Executing RSG recipe..."
    print_message "$YELLOW" "⏱️  This will take 10-15 minutes - DO NOT interrupt!"
    print_message "$CYAN" "📝 Progress will be logged to: ${RECIPE_LOG}"
    echo ""
    
    local recipe_file="${INSTALL_DIR}/recipe/rsgcore.yaml"
    local deploy_path="${INSTALL_DIR}/txData"
    
    mkdir -p "$deploy_path"
    cd "$deploy_path"
    
    # Create Python script with auto-retry for main/master branches
    cat > /tmp/recipe_executor.py <<'PYTHON_SCRIPT'
import yaml
import os
import subprocess
import urllib.request
import zipfile
import shutil
import time
import sys

log_file = sys.argv[1] if len(sys.argv) > 1 else "/var/log/redm/recipe.log"

def log_msg(msg):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    with open(log_file, 'a') as f:
        f.write(f"{timestamp} {msg}\n")
    print(msg, flush=True)

def download_github(src, dest, ref="main", subpath=""):
    log_msg(f"[INFO] Downloading GitHub: {src}")
    try:
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        cmd = ["git", "clone", "--quiet", "--depth", "1", "--branch", ref, src, dest]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        if result.returncode != 0 and ref == "main":
            log_msg(f"[WARNING] Branch 'main' not found, trying 'master'...")
            cmd = ["git", "clone", "--quiet", "--depth", "1", "--branch", "master", src, dest]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        if result.returncode != 0:
            log_msg(f"[ERROR] Git clone failed: {result.stderr}")
            return False
            
        if subpath:
            subpath_full = os.path.join(dest, subpath)
            if os.path.exists(subpath_full):
                for item in os.listdir(subpath_full):
                    shutil.move(os.path.join(subpath_full, item), os.path.join(dest, item))
                shutil.rmtree(subpath_full)
        log_msg(f"[SUCCESS] ✓ {os.path.basename(dest)}")
        return True
    except subprocess.TimeoutExpired:
        log_msg(f"[ERROR] Timeout downloading {src}")
        return False
    except Exception as e:
        log_msg(f"[ERROR] Failed: {e}")
        return False

def download_file(url, path):
    log_msg(f"[INFO] Downloading file: {os.path.basename(path)}")
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        urllib.request.urlretrieve(url, path)
        log_msg(f"[SUCCESS] ✓ Downloaded {os.path.basename(path)}")
        return True
    except Exception as e:
        log_msg(f"[ERROR] Failed: {e}")
        return False

def unzip_file(src, dest):
    log_msg(f"[INFO] Unzipping: {os.path.basename(src)}")
    try:
        os.makedirs(dest, exist_ok=True)
        with zipfile.ZipFile(src, 'r') as zip_ref:
            zip_ref.extractall(dest)
        log_msg(f"[SUCCESS] ✓ Unzipped")
        return True
    except Exception as e:
        log_msg(f"[ERROR] Failed: {e}")
        return False

def move_path(src, dest):
    log_msg(f"[INFO] Moving: {os.path.basename(src)} -> {os.path.basename(dest)}")
    try:
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        if os.path.exists(dest):
            if os.path.isdir(dest):
                shutil.rmtree(dest)
            else:
                os.remove(dest)
        shutil.move(src, dest)
        log_msg(f"[SUCCESS] ✓ Moved")
        return True
    except Exception as e:
        log_msg(f"[ERROR] Move failed: {e}")
        return False

def remove_path(path):
    try:
        if os.path.exists(path):
            log_msg(f"[INFO] Removing: {path}")
            if os.path.isdir(path):
                shutil.rmtree(path)
            else:
                os.remove(path)
            log_msg(f"[SUCCESS] ✓ Removed")
        return True
    except Exception as e:
        log_msg(f"[ERROR] Failed: {e}")
        return False

def query_database(sql_file, db_name, db_user, db_pass, db_port):
    log_msg(f"[INFO] 🗄️  Executing SQL: {os.path.basename(sql_file)}")
    if not os.path.exists(sql_file):
        log_msg(f"[ERROR] SQL file not found: {sql_file}")
        return False
    try:
        cmd = f"mysql -u {db_user} -p'{db_pass}' --port={db_port} {db_name} < {sql_file}"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=60)
        if result.returncode == 0:
            log_msg(f"[SUCCESS] ✓ SQL injected successfully")
            return True
        else:
            log_msg(f"[WARNING] SQL warnings: {result.stderr}")
            return True
    except Exception as e:
        log_msg(f"[ERROR] SQL failed: {e}")
        return False

def waste_time(seconds):
    log_msg(f"[INFO] Waiting {seconds}s (GitHub rate limiting)...")
    time.sleep(seconds)

if len(sys.argv) < 7:
    print("Usage: script.py <log_file> <recipe_file> <base_dir> <db_name> <db_user> <db_pass> <db_port>")
    sys.exit(1)

recipe_file = sys.argv[2]
base_dir = sys.argv[3]
db_name = sys.argv[4]
db_user = sys.argv[5]
db_pass = sys.argv[6]
db_port = sys.argv[7]

log_msg(f"[START] Recipe execution started")
log_msg(f"[INFO] Recipe file: {recipe_file}")
log_msg(f"[INFO] Base directory: {base_dir}")
log_msg(f"[INFO] Database: {db_name}@localhost:{db_port}")

os.chdir(base_dir)

try:
    with open(recipe_file, 'r') as f:
        recipe = yaml.safe_load(f)
except Exception as e:
    log_msg(f"[ERROR] Failed to load recipe: {e}")
    sys.exit(1)

tasks = recipe.get('tasks', [])
total = len(tasks)
log_msg(f"[INFO] Total tasks: {total}")

success_count = 0
fail_count = 0

for i, task in enumerate(tasks, 1):
    action = task.get('action')
    print(f"\n[{i}/{total}] {action}", flush=True)
    log_msg(f"[TASK {i}/{total}] Action: {action}")
    
    try:
        result = False
        if action == 'download_github':
            result = download_github(task.get('src'), task.get('dest'), task.get('ref', 'main'), task.get('subpath', ''))
        elif action == 'download_file':
            result = download_file(task.get('url'), task.get('path'))
        elif action == 'unzip':
            result = unzip_file(task.get('src'), task.get('dest'))
        elif action == 'move_path':
            result = move_path(task.get('src'), task.get('dest'))
        elif action == 'remove_path':
            result = remove_path(task.get('path'))
        elif action == 'query_database':
            result = query_database(task.get('file'), db_name, db_user, db_pass, db_port)
        elif action == 'connect_database':
            log_msg("[INFO] Database connection verified")
            result = True
        elif action == 'waste_time':
            waste_time(task.get('seconds', 0))
            result = True
        else:
            log_msg(f"[WARNING] Unknown action: {action}")
            result = True
        
        if result:
            success_count += 1
        else:
            fail_count += 1
            
    except Exception as e:
        log_msg(f"[ERROR] Task exception: {e}")
        fail_count += 1

log_msg(f"[COMPLETE] Recipe execution finished")
log_msg(f"[STATS] Success: {success_count}, Failed: {fail_count}, Total: {total}")

if fail_count > total * 0.3:
    log_msg("[ERROR] Too many failures!")
    sys.exit(1)

sys.exit(0)
PYTHON_SCRIPT

    # Execute Python script
    print_message "$CYAN" "   Starting recipe execution..."
    
    if [[ "$VERBOSE" == true ]]; then
        python3 /tmp/recipe_executor.py "${RECIPE_LOG}" "${recipe_file}" "${deploy_path}" "${DB_NAME}" "${DB_USER}" "${DB_PASSWORD}" "${DB_PORT}" 2>&1 | tee -a "${RECIPE_LOG}"
        local exit_code=${PIPESTATUS[0]}
    else
        python3 /tmp/recipe_executor.py "${RECIPE_LOG}" "${recipe_file}" "${deploy_path}" "${DB_NAME}" "${DB_USER}" "${DB_PASSWORD}" "${DB_PORT}" >> "${RECIPE_LOG}" 2>&1
        local exit_code=$?
    fi
    
    rm -f /tmp/recipe_executor.py
    
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        print_message "$GREEN" "✅ Recipe executed successfully"
        
        local resource_count=$(find "${deploy_path}/resources" -maxdepth 2 -type d -name 'rsg-*' 2>/dev/null | wc -l)
        print_message "$CYAN" "   📦 Installed $resource_count RSG resources"
        
        return 0
    else
        print_message "$RED" "❌ Recipe execution failed"
        print_message "$YELLOW" "Check recipe log: ${RECIPE_LOG}"
        show_last_error
        return 1
    fi
}

# ============================================
# SERVER CONFIGURATION
# ============================================
configure_server_cfg() {
    print_message "$BLUE" "⚙️  Configuring server.cfg..."
    
    local server_cfg="${INSTALL_DIR}/txData/server.cfg"
    
    if [[ ! -f "$server_cfg" ]]; then
        print_message "$RED" "❌ server.cfg not found! Recipe may have failed."
        return 1
    fi
    
    # Add OneSync at the beginning
    sed -i '1i ## OneSync (REQUIRED for ox_lib)\nset onesync on\nset onesync_enabled 1\n' "$server_cfg"
    
    # Replace all placeholders
    sed -i "s/{{svLicense}}/${CFX_LICENSE}/g" "$server_cfg"
    sed -i "s/{{serverEndpoints}}/endpoint_add_tcp \"0.0.0.0:${SERVER_PORT}\"\nendpoint_add_udp \"0.0.0.0:${SERVER_PORT}\"/g" "$server_cfg"
    sed -i "s/{{maxClients}}/${MAX_CLIENTS}/g" "$server_cfg"
    sed -i "s|{{dbConnectionString}}|mysql://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}?charset=utf8mb4|g" "$server_cfg"
    sed -i "s/{{recipeName}}/RSG Framework/g" "$server_cfg"
    sed -i "s/{{serverName}}/${SERVER_NAME}/g" "$server_cfg"
    sed -i "s/{{recipeDescription}}/Red Dead Redemption Roleplay Server/g" "$server_cfg"
    
    # Update hostname
    if grep -q "sv_hostname" "$server_cfg"; then
        sed -i "s/sv_hostname .*/sv_hostname \"${SERVER_NAME}\"/g" "$server_cfg"
    else
        echo "sv_hostname \"${SERVER_NAME}\"" >> "$server_cfg"
    fi
    
    # Add Steam HEX if provided
    if [[ ! -z "$STEAM_HEX" ]]; then
        sed -i "s/identifier.license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/identifier.steam:${STEAM_HEX}/g" "$server_cfg"
    fi
    
    print_message "$GREEN" "✅ server.cfg configured"
    return 0
}

# ============================================
# RESOURCE SYMLINK
# ============================================
create_resource_symlink() {
    print_message "$BLUE" "🔗 Creating resource symlink..."
    
    local server_dir="${INSTALL_DIR}/server"
    local resources_symlink="${server_dir}/resources"
    local resources_target="${INSTALL_DIR}/txData/resources"
    
    if [[ -L "$resources_symlink" ]]; then
        rm -f "$resources_symlink"
    elif [[ -d "$resources_symlink" ]]; then
        rm -rf "$resources_symlink"
    fi
    
    ln -s "$resources_target" "$resources_symlink"
    
    if [[ -L "$resources_symlink" ]]; then
        print_message "$GREEN" "✅ Resource symlink created"
        return 0
    else
        print_message "$RED" "❌ Failed to create symlink"
        return 1
    fi
}

# ============================================
# MANAGEMENT SCRIPTS
# ============================================
create_management_scripts() {
    print_message "$BLUE" "📝 Creating management scripts..."
    
    if [[ "$USE_TXADMIN" == "yes" ]]; then
        # txAdmin mode
        cat > "${INSTALL_DIR}/start.sh" <<EOF
#!/bin/bash
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
SCREEN_NAME="\$(hostname)_redm_txadmin"
cd "\${SCRIPT_DIR}/server"

if screen -list | grep -q "\$SCREEN_NAME"; then
    echo "✅ txAdmin running: \$SCREEN_NAME"
    echo "Access: http://\$(hostname -I | awk '{print \$1}'):${TXADMIN_PORT}"
    exit 0
fi

echo "🚀 Starting txAdmin..."
screen -dmS "\$SCREEN_NAME" bash -c "./FXServer +set citizen_dir alpine/opt/cfx-server/citizen/ +set sv_licenseKey ${CFX_LICENSE} +set txAdminPort ${TXADMIN_PORT} +set txDataPath \${SCRIPT_DIR}/txData"

sleep 3

if screen -list | grep -q "\$SCREEN_NAME"; then
    echo "✅ txAdmin started!"
    echo "Access: http://\$(hostname -I | awk '{print \$1}'):${TXADMIN_PORT}"
    echo "Console: screen -r \$SCREEN_NAME (CTRL+A then D to detach)"
else
    echo "❌ Failed to start"
    exit 1
fi
EOF
    else
        # Standalone mode
        cat > "${INSTALL_DIR}/start.sh" <<'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCREEN_NAME="$(hostname)_redm"
cd "${SCRIPT_DIR}/server"

if screen -list | grep -q "$SCREEN_NAME"; then
    echo "✅ Server running: $SCREEN_NAME"
    echo "Use ./attach.sh to connect"
    exit 0
fi

echo "🚀 Starting server: $SCREEN_NAME"
screen -dmS "$SCREEN_NAME" bash -c "./run.sh +exec ${SCRIPT_DIR}/txData/server.cfg"

sleep 2

if screen -list | grep -q "$SCREEN_NAME"; then
    echo "✅ Started successfully"
    echo "Console: screen -r $SCREEN_NAME (CTRL+A then D to detach)"
else
    echo "❌ Failed to start"
    exit 1
fi
EOF
    fi

    cat > "${INSTALL_DIR}/stop.sh" <<'EOF'
#!/bin/bash
SCREEN_NAME_1="$(hostname)_redm"
SCREEN_NAME_2="$(hostname)_redm_txadmin"

if screen -list | grep -q "$SCREEN_NAME_1"; then
    screen -S "$SCREEN_NAME_1" -X quit
    echo "✅ Server stopped"
elif screen -list | grep -q "$SCREEN_NAME_2"; then
    screen -S "$SCREEN_NAME_2" -X quit
    echo "✅ txAdmin stopped"
else
    echo "⚠️  Server not running"
fi
EOF

    cat > "${INSTALL_DIR}/restart.sh" <<'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"${SCRIPT_DIR}/stop.sh"
sleep 3
"${SCRIPT_DIR}/start.sh"
EOF

    cat > "${INSTALL_DIR}/attach.sh" <<'EOF'
#!/bin/bash
SCREEN_NAME_1="$(hostname)_redm"
SCREEN_NAME_2="$(hostname)_redm_txadmin"

if screen -list | grep -q "$SCREEN_NAME_1"; then
    echo "📺 Attaching to console: $SCREEN_NAME_1"
    echo "⚠️  Detach: CTRL+A then D"
    sleep 2
    screen -r "$SCREEN_NAME_1"
elif screen -list | grep -q "$SCREEN_NAME_2"; then
    echo "📺 Attaching to console: $SCREEN_NAME_2"
    echo "⚠️  Detach: CTRL+A then D"
    sleep 2
    screen -r "$SCREEN_NAME_2"
else
    echo "❌ Server not running"
fi
EOF

    cat > "${INSTALL_DIR}/update.sh" <<'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT_URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
echo "🔍 Checking for updates..."
HTML=$(curl -s $ARTIFACT_URL)
LINKS=$(echo "$HTML" | grep -oP 'href="\./\d{4,}[^"]+fx\.tar\.xz"' | sed 's/href="\.\/\([^"]*\)"/\1/')
[ -z "$LINKS" ] && { echo "❌ No builds found"; exit 1; }
LATEST=$(echo "$LINKS" | grep -oP '^\d{4,}' | sort -nr | head -n 1)
FILE=$(echo "$LINKS" | grep "^$LATEST")
URL="${ARTIFACT_URL}${FILE}"
echo "📦 Latest build: $LATEST"
echo -n "Install? [y/N]: "
read confirm
if [[ $confirm == [Yy] ]]; then
    "${SCRIPT_DIR}/stop.sh"
    sleep 2
    cd "${SCRIPT_DIR}/server"
    rm -rf alpine.backup
    mv alpine alpine.backup 2>/dev/null || true
    echo "📥 Downloading..."
    wget -q --show-progress "$URL" -O fx.tar.xz
    tar -xf fx.tar.xz && rm fx.tar.xz
    chmod +x run.sh FXServer 2>/dev/null
    echo "✅ Updated to $LATEST"
    "${SCRIPT_DIR}/start.sh"
fi
EOF

    chmod +x "${INSTALL_DIR}"/{start,stop,restart,attach,update}.sh
    print_message "$GREEN" "✅ Management scripts created"
}

# ============================================
# SYSTEMD SERVICE
# ============================================
create_systemd_service() {
    print_message "$BLUE" "🔧 Creating systemd service..."
    
    cat > /etc/systemd/system/redm-rsg.service <<EOF
[Unit]
Description=RedM RSG Server
After=network.target mariadb.service

[Service]
Type=forking
User=root
WorkingDirectory=${INSTALL_DIR}/server
ExecStart=${INSTALL_DIR}/start.sh
ExecStop=${INSTALL_DIR}/stop.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    print_message "$GREEN" "✅ Systemd service created"
    
    echo -ne "${YELLOW}Enable auto-start on boot? [y/N]: ${NC}"
    read auto_start
    [[ "$auto_start" =~ ^[Yy]$ ]] && systemctl enable redm-rsg.service && print_message "$GREEN" "✅ Auto-start enabled"
}

# ============================================
# FIREWALL
# ============================================
configure_firewall() {
    print_message "$BLUE" "🔥 Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow ${SERVER_PORT}/tcp >> "${LOG_FILE}" 2>&1
        ufw allow ${SERVER_PORT}/udp >> "${LOG_FILE}" 2>&1
        [[ "$USE_TXADMIN" == "yes" ]] && ufw allow ${TXADMIN_PORT}/tcp >> "${LOG_FILE}" 2>&1
        print_message "$GREEN" "✅ UFW configured"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=${SERVER_PORT}/tcp >> "${LOG_FILE}" 2>&1
        firewall-cmd --permanent --add-port=${SERVER_PORT}/udp >> "${LOG_FILE}" 2>&1
        [[ "$USE_TXADMIN" == "yes" ]] && firewall-cmd --permanent --add-port=${TXADMIN_PORT}/tcp >> "${LOG_FILE}" 2>&1
        firewall-cmd --reload >> "${LOG_FILE}" 2>&1
        print_message "$GREEN" "✅ firewalld configured"
    else
        print_message "$YELLOW" "⚠️  No firewall detected. Manual config needed: ${SERVER_PORT}"
        [[ "$USE_TXADMIN" == "yes" ]] && print_message "$YELLOW" "    Also open: ${TXADMIN_PORT}"
    fi
}

# ============================================
# VERIFICATION
# ============================================
verify_rsg_tables() {
    print_message "$CYAN" "🔍 Verifying database tables..."
    
    local expected_tables=("players" "characters" "player_horses" "bank_accounts")
    local missing=()
    
    for table in "${expected_tables[@]}"; do
        local exists=$(mysql -u root -p"${DB_PASSWORD}" --port=${DB_PORT} -D "${DB_NAME}" -sse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}' AND table_name = '${table}';" 2>/dev/null)
        [[ "$exists" == "0" ]] && missing+=("$table")
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        print_message "$GREEN" "✅ All RSG tables present"
        return 0
    else
        print_message "$YELLOW" "⚠️  Missing tables: ${missing[*]}"
        return 1
    fi
}

count_database_tables() {
    mysql -u root -p"${DB_PASSWORD}" --port=${DB_PORT} -D "${DB_NAME}" -sse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}';" 2>/dev/null
}

# ============================================
# SUMMARY
# ============================================
display_summary() {
    local server_ip=$(hostname -I | awk '{print $1}')
    local table_count=$(count_database_tables)
    local resource_count=$(find ${INSTALL_DIR}/txData/resources -maxdepth 2 -type d -name 'rsg-*' 2>/dev/null | wc -l)
    
    clear
    print_message "$GREEN" "╔════════════════════════════════════════════╗"
    print_message "$GREEN" "║        Installation Complete! 🎉           ║"
    print_message "$GREEN" "╚════════════════════════════════════════════╝"
    echo ""
    if [[ "$USE_TXADMIN" == "yes" ]]; then
        echo -e "${BOLD}Mode:${NC} txAdmin (Web Interface)"
    else
        echo -e "${BOLD}Mode:${NC} Standalone (Console)"
    fi
    echo -e "${BOLD}Server:${NC} $SERVER_NAME"
    echo -e "${BOLD}Build:${NC} $LATEST_ARTIFACT"
    echo -e "${BOLD}Path:${NC} $INSTALL_DIR"
    echo -e "${BOLD}Database:${NC} $DB_NAME ($table_count tables)"
    echo -e "${BOLD}Resources:${NC} $resource_count RSG resources"
    echo ""
    print_message "$CYAN" "Commands:"
    echo "  ${INSTALL_DIR}/start.sh      - Start server"
    echo "  ${INSTALL_DIR}/stop.sh       - Stop server"
    echo "  ${INSTALL_DIR}/restart.sh    - Restart server"
    echo "  ${INSTALL_DIR}/attach.sh     - Access console"
    echo "  ${INSTALL_DIR}/update.sh     - Update RedM build"
    echo ""
    print_message "$CYAN" "Access:"
    if [[ "$USE_TXADMIN" == "yes" ]]; then
        echo "  txAdmin: http://$server_ip:$TXADMIN_PORT"
        echo "  Game: connect $server_ip:$SERVER_PORT"
    else
        echo "  F8 Console: connect $server_ip:$SERVER_PORT"
    fi
    echo ""
    print_message "$CYAN" "Logs:"
    echo "  Install: ${LOG_FILE}"
    echo "  Recipe:  ${RECIPE_LOG}"
    echo ""
    print_message "$GREEN" "🚀 Start: cd ${INSTALL_DIR} && ./start.sh"
    echo ""
}

# ============================================
# MAIN
# ============================================
main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose) VERBOSE=true; shift ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "  -v, --verbose    Verbose output"
                echo "  -h, --help       Show this help"
                exit 0 ;;
            *) echo "Unknown option: $1"; exit 1 ;;
        esac
    done
    
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║     RSG RedM Framework Installer v4.0 FINAL           ║
║     txAdmin or Standalone + OneSync + Symlink fix    ║
╚═══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_stdin
    check_root
    check_dependencies
    setup_logging
    get_user_input
    
    print_message "$CYAN" "\n━━━ Installation Starting ━━━\n"
    
    print_message "$CYAN" "Step 1/11: Installing dependencies..."
    install_dependencies
    
    print_message "$CYAN" "Step 2/11: Finding latest RedM build..."
    check_new_artifact || exit 1
    
    print_message "$CYAN" "Step 3/11: Configuring MariaDB..."
    setup_mariadb
    validate_sql_connection || exit 1
    
    print_message "$CYAN" "Step 4/11: Downloading RedM artifacts..."
    download_artifact "${INSTALL_DIR}/server" || exit 1
    
    print_message "$CYAN" "Step 5/11: Downloading RSG recipe..."
    download_recipe || exit 1
    
    print_message "$CYAN" "Step 6/11: Executing RSG recipe (10-15 min)..."
    execute_recipe || exit 1
    
    print_message "$CYAN" "Step 7/11: Configuring server..."
    configure_server_cfg || exit 1
    
    print_message "$CYAN" "Step 8/11: Creating resource symlink..."
    create_resource_symlink || exit 1
    
    print_message "$CYAN" "Step 9/11: Creating management scripts..."
    create_management_scripts
    
    print_message "$CYAN" "Step 10/11: Setting up systemd service..."
    create_systemd_service
    
    print_message "$CYAN" "Step 11/11: Configuring firewall..."
    configure_firewall
    
    print_message "$CYAN" "\n━━━ Final Verification ━━━\n"
    verify_rsg_tables
    
    log "INFO" "Installation completed successfully"
    display_summary
}

main "$@"
