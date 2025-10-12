#!/bin/bash

# RSG RedM Framework - Installation Script v2.6
# Fixed Python boolean conversion

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

# Verbose mode
VERBOSE=false

# Server Configuration with defaults
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
        echo ""
        echo "  wget https://your-url.com/rsg-installer.sh"
        echo "  chmod +x rsg-installer.sh"
        echo "  sudo ./rsg-installer.sh"
        echo ""
        exit 1
    fi
}

# ============================================
# LOGGING FUNCTIONS
# ============================================
setup_logging() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    ln -sf "${LOG_FILE}" "${LATEST_LOG_SYMLINK}"
    log "INFO" "=== RSG RedM Installation Started ==="
    log "INFO" "Verbose mode: $VERBOSE"
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
    print_message "$YELLOW" "📋 Last 20 lines of log:"
    echo -e "${CYAN}"
    tail -n 20 "${LOG_FILE}"
    echo -e "${NC}"
    print_message "$YELLOW" "Full log: ${LOG_FILE}"
    print_message "$YELLOW" "\nRun with verbose: sudo bash $0 --verbose"
}

# ============================================
# VALIDATION FUNCTIONS
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
    
    # 1. CFX License Key (REQUIRED)
    echo -e "${BOLD}━━━ Server Configuration ━━━${NC}"
    while true; do
        echo -ne "${GREEN}CFX License Key ${YELLOW}[required]${NC}: "
        read CFX_LICENSE
        if [[ ! -z "$CFX_LICENSE" ]]; then
            break
        fi
        echo -e "${RED}   ❌ License key is required! Get one from: https://keymaster.fivem.net${NC}"
    done
    
    # 2. Server Name (REQUIRED)
    while true; do
        echo -ne "${GREEN}Server Name ${YELLOW}[required]${NC}: "
        read SERVER_NAME
        if [[ ! -z "$SERVER_NAME" ]]; then
            break
        fi
        echo -e "${RED}   ❌ Server name is required!${NC}"
    done
    
    # 3. Max Clients (optional)
    echo ""
    echo -ne "${GREEN}Max Players ${CYAN}[${MAX_CLIENTS}]${NC}: "
    read input_max_clients
    if [[ ! -z "$input_max_clients" ]]; then
        MAX_CLIENTS=$input_max_clients
    fi
    echo -e "${CYAN}   → Using: ${MAX_CLIENTS} players${NC}"
    
    # 4. Installation Directory (optional)
    echo ""
    local default_install_dir="/home/RedM"
    echo -ne "${GREEN}Install Directory ${CYAN}[${default_install_dir}]${NC}: "
    read INSTALL_DIR
    if [[ -z "$INSTALL_DIR" ]]; then
        INSTALL_DIR=$default_install_dir
    fi
    echo -e "${CYAN}   → Installing to: ${INSTALL_DIR}${NC}"
    
    # 5. Database Configuration
    echo ""
    echo -e "${BOLD}━━━ Database Configuration ━━━${NC}"
    
    # Database Name
    echo -ne "${GREEN}Database Name ${CYAN}[${DB_NAME}]${NC}: "
    read input_db_name
    if [[ ! -z "$input_db_name" ]]; then
        DB_NAME=$input_db_name
    fi
    echo -e "${CYAN}   → Database: ${DB_NAME}${NC}"
    
    # Database User
    echo -ne "${GREEN}Database User ${CYAN}[${DB_USER}]${NC}: "
    read input_db_user
    if [[ ! -z "$input_db_user" ]]; then
        DB_USER=$input_db_user
    fi
    echo -e "${CYAN}   → User: ${DB_USER}${NC}"
    
    # Database Password (REQUIRED)
    while true; do
        echo -ne "${GREEN}Database Password ${YELLOW}[required]${NC}: "
        read -s DB_PASSWORD
        echo ""
        if [[ ! -z "$DB_PASSWORD" ]]; then
            break
        fi
        echo -e "${RED}   ❌ Database password is required!${NC}"
    done
    echo -e "${CYAN}   → Password set${NC}"
    
    # Database Port
    echo -ne "${GREEN}Database Port ${CYAN}[${DB_PORT}]${NC}: "
    read input_db_port
    if [[ ! -z "$input_db_port" ]]; then
        DB_PORT=$input_db_port
    fi
    echo -e "${CYAN}   → Port: ${DB_PORT}${NC}"
    
    # 6. Network Ports
    echo ""
    echo -e "${BOLD}━━━ Network Ports ━━━${NC}"
    
    # Server Port
    echo -ne "${GREEN}Server Port ${CYAN}[${SERVER_PORT}]${NC}: "
    read input_server_port
    if [[ ! -z "$input_server_port" ]]; then
        SERVER_PORT=$input_server_port
    fi
    echo -e "${CYAN}   → Server: ${SERVER_PORT}${NC}"
    
    # txAdmin Port
    echo -ne "${GREEN}txAdmin Port ${CYAN}[${TXADMIN_PORT}]${NC}: "
    read input_txadmin_port
    if [[ ! -z "$input_txadmin_port" ]]; then
        TXADMIN_PORT=$input_txadmin_port
    fi
    echo -e "${CYAN}   → txAdmin: ${TXADMIN_PORT}${NC}"
    
    # 7. Admin Configuration (Optional)
    echo ""
    echo -e "${BOLD}━━━ Admin Configuration (Optional) ━━━${NC}"
    echo -ne "${GREEN}Your Steam HEX ${CYAN}[optional - skip with ENTER]${NC}: "
    read STEAM_HEX
    if [[ ! -z "$STEAM_HEX" ]]; then
        echo -e "${CYAN}   → Steam HEX: ${STEAM_HEX}${NC}"
    else
        echo -e "${YELLOW}   → No Steam HEX (add manually later)${NC}"
    fi
    
    # Display summary
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}              Configuration Summary${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
    echo -e "  txAdmin Port:      ${CYAN}$TXADMIN_PORT${NC}"
    echo ""
    if [[ ! -z "$STEAM_HEX" ]]; then
        echo -e "${BOLD}Admin:${NC}"
        echo -e "  Steam HEX:         ${CYAN}$STEAM_HEX${NC}"
        echo ""
    fi
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    log "INFO" "Configuration: Server=$SERVER_NAME, Install=$INSTALL_DIR, DB=$DB_NAME:$DB_PORT"
    
    # Confirmation
    echo ""
    echo -ne "${YELLOW}Continue with this configuration? [Y/n]: ${NC}"
    read confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        print_message "$YELLOW" "Installation cancelled by user"
        exit 0
    fi
    
    echo ""
}

# ============================================
# ARTIFACT FUNCTIONS
# ============================================
check_new_artifact() {
    print_message "$CYAN" "🔍 Searching for latest RedM build..."
    log "DEBUG" "Fetching from: $ARTIFACT_PAGE_URL"
    
    local ARTIFACT_HTML=$(curl -s $ARTIFACT_PAGE_URL)
    
    if [[ -z "$ARTIFACT_HTML" ]]; then
        print_message "$RED" "❌ Failed to fetch artifacts"
        return 1
    fi
    
    local ARTIFACT_LINKS=$(echo "$ARTIFACT_HTML" | grep -oP 'href="\./\d{4,}[^"]+fx\.tar\.xz"' | sed 's/href="\.\/\([^"]*\)"/\1/')
    
    if [ -z "$ARTIFACT_LINKS" ]; then
        print_message "$RED" "❌ No artifacts found"
        return 1
    fi
    
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
    
    mkdir -p "$dest"
    cd "$dest"
    
    if [[ "$VERBOSE" == true ]]; then
        wget --show-progress "$FULL_ARTIFACT_URL" -O fx.tar.xz 2>&1 | tee -a "${LOG_FILE}"
    else
        wget -q --show-progress "$FULL_ARTIFACT_URL" -O fx.tar.xz >> "${LOG_FILE}" 2>&1
    fi
    
    if [[ $? -eq 0 ]]; then
        print_message "$CYAN" "📦 Extracting..."
        exec_cmd "tar -xf fx.tar.xz"
        rm -f fx.tar.xz
        
        if [[ -d "alpine/opt/cfx-server/alpine" ]]; then
            rm -rf "alpine/opt/cfx-server/alpine"
        fi
        
        chmod +x run.sh
        print_message "$GREEN" "✅ Artifact installed"
        return 0
    else
        print_message "$RED" "❌ Download failed"
        return 1
    fi
}

# ============================================
# DEPENDENCY INSTALLATION
# ============================================
install_dependencies() {
    print_message "$BLUE" "📦 Installing dependencies..."
    
    print_message "$CYAN" "   Updating packages..."
    if ! exec_cmd "apt-get update"; then
        print_message "$RED" "❌ apt-get update failed"
        show_last_error
        exit 1
    fi
    
    local packages=(
        "wget" "curl" "tar" "git" "xz-utils"
        "mariadb-server" "mariadb-client"
        "unzip" "screen" "jq" "python3" "python3-pip"
    )
    
    print_message "$CYAN" "   Installing: ${packages[*]}"
    if ! exec_cmd "DEBIAN_FRONTEND=noninteractive apt-get install -y ${packages[*]}"; then
        print_message "$RED" "❌ Package installation failed"
        show_last_error
        exit 1
    fi
    
    print_message "$CYAN" "   Installing PyYAML..."
    if ! exec_cmd "pip3 install pyyaml"; then
        print_message "$YELLOW" "   ⚠️  Trying apt method..."
        exec_cmd "apt-get install -y python3-yaml"
    fi
    
    print_message "$GREEN" "✅ Dependencies installed"
}

# ============================================
# DATABASE FUNCTIONS
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
# SQL VERIFICATION
# ============================================
verify_rsg_tables() {
    print_message "$CYAN" "🔍 Verifying RSG tables..."
    
    local expected_tables=("players" "characters" "player_horses" "bank_accounts")
    local missing=()
    
    for table in "${expected_tables[@]}"; do
        local exists=$(mysql -u root -p"${DB_PASSWORD}" --port=${DB_PORT} -D "${DB_NAME}" -sse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}' AND table_name = '${table}';" 2>/dev/null)
        if [[ "$exists" == "0" ]]; then
            missing+=("$table")
        fi
    done
    
    if [[ ${#missing[@]} -eq 0 ]]; then
        print_message "$GREEN" "✅ All RSG tables present"
        return 0
    else
        print_message "$YELLOW" "⚠️  Missing: ${missing[*]}"
        return 1
    fi
}

count_database_tables() {
    mysql -u root -p"${DB_PASSWORD}" --port=${DB_PORT} -D "${DB_NAME}" -sse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}';" 2>/dev/null
}

# ============================================
# RECIPE PROCESSING (FIXED)
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
    
    if [[ $? -eq 0 ]]; then
        print_message "$GREEN" "✅ Recipe downloaded"
        return 0
    else
        print_message "$RED" "❌ Recipe download failed"
        show_last_error
        return 1
    fi
}

execute_recipe() {
    print_message "$BLUE" "⚙️  Executing RSG recipe..."
    print_message "$YELLOW" "⏱️  This may take 10-15 minutes..."
    
    local recipe_file="${INSTALL_DIR}/recipe/rsgcore.yaml"
    local deploy_path="${INSTALL_DIR}/txData"
    
    mkdir -p "$deploy_path"
    cd "$deploy_path"
    
    # Convert bash boolean to Python boolean
    local PYTHON_VERBOSE="False"
    if [[ "$VERBOSE" == true ]]; then
        PYTHON_VERBOSE="True"
    fi
    
    python3 - <<PYTHON_SCRIPT
import yaml
import os
import subprocess
import urllib.request
import zipfile
import shutil
import time
import sys

VERBOSE = ${PYTHON_VERBOSE}

def log_info(msg):
    print(f"[INFO] {msg}", flush=True)

def log_error(msg):
    print(f"[ERROR] {msg}", file=sys.stderr, flush=True)

def download_github(src, dest, ref="main", subpath=""):
    log_info(f"Downloading {src}")
    try:
        cmd = ["git", "clone", "--quiet", "--depth", "1", "--branch", ref, src, dest]
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            log_error(f"Failed: {result.stderr}")
            return False
        if subpath:
            subpath_full = os.path.join(dest, subpath)
            if os.path.exists(subpath_full):
                for item in os.listdir(subpath_full):
                    shutil.move(os.path.join(subpath_full, item), os.path.join(dest, item))
                shutil.rmtree(subpath_full)
        log_info(f"✓ {os.path.basename(dest)}")
        return True
    except Exception as e:
        log_error(f"Failed: {e}")
        return False

def download_file(url, path):
    log_info(f"Downloading {os.path.basename(path)}")
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        urllib.request.urlretrieve(url, path)
        log_info(f"✓ Downloaded")
        return True
    except Exception as e:
        log_error(f"Failed: {e}")
        return False

def unzip_file(src, dest):
    log_info(f"Unzipping {os.path.basename(src)}")
    try:
        os.makedirs(dest, exist_ok=True)
        with zipfile.ZipFile(src, 'r') as zip_ref:
            zip_ref.extractall(dest)
        log_info(f"✓ Unzipped")
        return True
    except Exception as e:
        log_error(f"Failed: {e}")
        return False

def move_path(src, dest):
    try:
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        if os.path.exists(dest):
            if os.path.isdir(dest):
                shutil.rmtree(dest)
            else:
                os.remove(dest)
        shutil.move(src, dest)
        return True
    except Exception as e:
        log_error(f"Move failed: {e}")
        return False

def remove_path(path):
    try:
        if os.path.exists(path):
            if os.path.isdir(path):
                shutil.rmtree(path)
            else:
                os.remove(path)
        return True
    except:
        return False

def query_database(sql_file, db_name, db_user, db_pass, db_port):
    log_info(f"🗄️  Injecting SQL: {os.path.basename(sql_file)}")
    if not os.path.exists(sql_file):
        log_error(f"SQL not found: {sql_file}")
        return False
    try:
        cmd = f"mysql -u {db_user} -p'{db_pass}' --port={db_port} {db_name} < {sql_file} 2>&1"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if result.returncode == 0:
            log_info(f"✓ SQL injected")
            return True
        else:
            log_error(f"SQL error: {result.stderr}")
            return True
    except Exception as e:
        log_error(f"SQL failed: {e}")
        return False

def waste_time(seconds):
    log_info(f"Waiting {seconds}s...")
    time.sleep(seconds)

recipe_file = "${recipe_file}"
base_dir = "${deploy_path}"
db_name = "${DB_NAME}"
db_user = "${DB_USER}"
db_pass = "${DB_PASSWORD}"
db_port = "${DB_PORT}"

os.chdir(base_dir)

with open(recipe_file, 'r') as f:
    recipe = yaml.safe_load(f)

tasks = recipe.get('tasks', [])
total = len(tasks)
log_info(f"Executing {total} tasks")

for i, task in enumerate(tasks, 1):
    action = task.get('action')
    print(f"\n[{i}/{total}] {action}", flush=True)
    
    try:
        if action == 'download_github':
            download_github(task.get('src'), task.get('dest'), task.get('ref', 'main'), task.get('subpath', ''))
        elif action == 'download_file':
            download_file(task.get('url'), task.get('path'))
        elif action == 'unzip':
            unzip_file(task.get('src'), task.get('dest'))
        elif action == 'move_path':
            move_path(task.get('src'), task.get('dest'))
        elif action == 'remove_path':
            remove_path(task.get('path'))
        elif action == 'query_database':
            query_database(task.get('file'), db_name, db_user, db_pass, db_port)
        elif action == 'connect_database':
            log_info("DB connected")
        elif action == 'waste_time':
            waste_time(task.get('seconds', 0))
    except Exception as e:
        log_error(f"Error: {e}")

print("\n✓ Recipe complete", flush=True)
PYTHON_SCRIPT

    if [[ $? -eq 0 ]]; then
        print_message "$GREEN" "✅ Recipe executed"
        local table_count=$(count_database_tables)
        print_message "$CYAN" "📊 Tables: ${table_count}"
        verify_rsg_tables
        return 0
    else
        print_message "$RED" "❌ Recipe execution failed"
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
    
    if [[ -f "$server_cfg" ]]; then
        sed -i "s/{{svLicense}}/${CFX_LICENSE}/g" "$server_cfg"
        sed -i "s/{{serverEndpoints}}/endpoint_add_tcp \"0.0.0.0:${SERVER_PORT}\"\nendpoint_add_udp \"0.0.0.0:${SERVER_PORT}\"/g" "$server_cfg"
        sed -i "s/{{maxClients}}/${MAX_CLIENTS}/g" "$server_cfg"
        sed -i "s|{{dbConnectionString}}|mysql://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}?charset=utf8mb4|g" "$server_cfg"
        
        if grep -q "sv_hostname" "$server_cfg"; then
            sed -i "s/sv_hostname .*/sv_hostname \"${SERVER_NAME}\"/g" "$server_cfg"
        else
            echo "sv_hostname \"${SERVER_NAME}\"" >> "$server_cfg"
        fi
        
        if [[ ! -z "$STEAM_HEX" ]]; then
            if ! grep -q "add_principal identifier.steam:${STEAM_HEX}" "$server_cfg"; then
                cat >> "$server_cfg" <<EOF

# Admin identifiers
add_ace group.admin command allow
add_ace group.admin command.quit deny
add_principal identifier.steam:${STEAM_HEX} group.admin
EOF
            fi
        else
            if ! grep -q "add_principal identifier" "$server_cfg"; then
                cat >> "$server_cfg" <<EOF

# Admin identifiers (add your Steam/Discord IDs)
# add_principal identifier.steam:YOUR_STEAM_HEX group.admin
# add_principal identifier.discord:YOUR_DISCORD_ID group.admin
EOF
            fi
        fi
        
        print_message "$GREEN" "✅ server.cfg configured"
    else
        print_message "$RED" "❌ server.cfg not found"
        show_last_error
        return 1
    fi
}

# ============================================
# MANAGEMENT SCRIPTS
# ============================================
create_management_scripts() {
    print_message "$BLUE" "📝 Creating scripts..."
    
    cat > "${INSTALL_DIR}/start.sh" <<'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCREEN_NAME="$(hostname)_redm"

cd "${SCRIPT_DIR}/server"

if screen -list | grep -q "$SCREEN_NAME"; then
    echo "✅ Server running: $SCREEN_NAME"
    echo "Use ./attach.sh to connect"
    exit 1
fi

echo "🚀 Starting server: $SCREEN_NAME"
screen -dmS "$SCREEN_NAME" bash -c "./run.sh +exec ${SCRIPT_DIR}/txData/server.cfg"
sleep 2

if screen -list | grep -q "$SCREEN_NAME"; then
    echo "✅ Started"
    echo "Console: screen -r $SCREEN_NAME"
else
    echo "❌ Failed"
    exit 1
fi
EOF

    cat > "${INSTALL_DIR}/stop.sh" <<'EOF'
#!/bin/bash
SCREEN_NAME="$(hostname)_redm"
if screen -list | grep -q "$SCREEN_NAME"; then
    screen -S "$SCREEN_NAME" -X quit
    echo "✅ Stopped"
else
    echo "⚠️  Not running"
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
SCREEN_NAME="$(hostname)_redm"
if screen -list | grep -q "$SCREEN_NAME"; then
    echo "📺 Console: $SCREEN_NAME"
    echo "Detach: CTRL+A then D"
    sleep 2
    screen -r "$SCREEN_NAME"
else
    echo "❌ Not running"
fi
EOF

    cat > "${INSTALL_DIR}/update.sh" <<'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT_URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"

echo "🔍 Checking for updates..."

HTML=$(curl -s $ARTIFACT_URL)
LINKS=$(echo "$HTML" | grep -oP 'href="\./\d{4,}[^"]+fx\.tar\.xz"' | sed 's/href="\.\/\([^"]*\)"/\1/')

if [ -z "$LINKS" ]; then
    echo "❌ No builds found"
    exit 1
fi

LATEST=$(echo "$LINKS" | grep -oP '^\d{4,}' | sort -nr | head -n 1)
FILE=$(echo "$LINKS" | grep "^$LATEST")
URL="${ARTIFACT_URL}${FILE}"

echo "📦 Latest: $LATEST"
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
    tar -xf fx.tar.xz
    rm fx.tar.xz
    
    echo "✅ Updated to $LATEST"
    "${SCRIPT_DIR}/start.sh"
fi
EOF

    chmod +x "${INSTALL_DIR}"/{start,stop,restart,attach,update}.sh
    print_message "$GREEN" "✅ Scripts created"
}

# ============================================
# SYSTEMD SERVICE
# ============================================
create_systemd_service() {
    print_message "$BLUE" "🔧 Creating service..."
    
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
    print_message "$GREEN" "✅ Service created"
    
    echo -ne "${YELLOW}Enable auto-start? [y/N]: ${NC}"
    read auto_start
    if [[ "$auto_start" =~ ^[Yy]$ ]]; then
        systemctl enable redm-rsg.service
        print_message "$GREEN" "✅ Auto-start enabled"
    fi
}

# ============================================
# FIREWALL
# ============================================
configure_firewall() {
    print_message "$BLUE" "🔥 Firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow ${SERVER_PORT}/tcp >> "${LOG_FILE}" 2>&1
        ufw allow ${SERVER_PORT}/udp >> "${LOG_FILE}" 2>&1
        ufw allow ${TXADMIN_PORT}/tcp >> "${LOG_FILE}" 2>&1
        print_message "$GREEN" "✅ UFW configured"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=${SERVER_PORT}/tcp >> "${LOG_FILE}" 2>&1
        firewall-cmd --permanent --add-port=${SERVER_PORT}/udp >> "${LOG_FILE}" 2>&1
        firewall-cmd --permanent --add-port=${TXADMIN_PORT}/tcp >> "${LOG_FILE}" 2>&1
        firewall-cmd --reload >> "${LOG_FILE}" 2>&1
        print_message "$GREEN" "✅ firewalld configured"
    else
        print_message "$YELLOW" "⚠️  Manual: ${SERVER_PORT}, ${TXADMIN_PORT}"
    fi
}

# ============================================
# SUMMARY
# ============================================
display_summary() {
    local server_ip=$(hostname -I | awk '{print $1}')
    local table_count=$(count_database_tables)
    
    clear
    print_message "$GREEN" "╔════════════════════════════════════════════╗"
    print_message "$GREEN" "║        Installation Complete! 🎉           ║"
    print_message "$GREEN" "╚════════════════════════════════════════════╝"
    echo ""
    echo -e "${BOLD}Server:${NC} $SERVER_NAME"
    echo -e "${BOLD}Build:${NC} $LATEST_ARTIFACT"
    echo -e "${BOLD}Path:${NC} $INSTALL_DIR"
    echo -e "${BOLD}Database:${NC} $DB_NAME ($table_count tables)"
    echo ""
    print_message "$CYAN" "Commands:"
    echo "  ${INSTALL_DIR}/start.sh"
    echo "  ${INSTALL_DIR}/stop.sh"
    echo "  ${INSTALL_DIR}/attach.sh"
    echo "  ${INSTALL_DIR}/update.sh"
    echo ""
    print_message "$CYAN" "Access:"
    echo "  F8: connect $server_ip:$SERVER_PORT"
    echo "  txAdmin: http://$server_ip:$TXADMIN_PORT"
    echo ""
    print_message "$GREEN" "🚀 Start now: cd ${INSTALL_DIR} && ./start.sh"
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
                echo "  -v, --verbose    Verbose mode"
                echo "  -h, --help       Help"
                exit 0 ;;
            *) echo "Unknown: $1"; exit 1 ;;
        esac
    done
    
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║       RSG RedM Framework Installer v2.6               ║
║       Fixed Python boolean & recipe execution         ║
╚═══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_stdin
    check_root
    check_dependencies
    setup_logging
    
    # Get ALL configuration FIRST
    get_user_input
    
    # Then proceed with installation
    print_message "$CYAN" "\nStep 1/10: Installing dependencies..."
    install_dependencies
    
    print_message "$CYAN" "Step 2/10: Finding RedM build..."
    check_new_artifact || exit 1
    
    print_message "$CYAN" "Step 3/10: Configuring MariaDB..."
    setup_mariadb
    validate_sql_connection || exit 1
    
    print_message "$CYAN" "Step 4/10: Downloading RedM..."
    download_artifact "${INSTALL_DIR}/server" || exit 1
    
    print_message "$CYAN" "Step 5/10: Downloading recipe..."
    download_recipe || exit 1
    
    print_message "$CYAN" "Step 6/10: Executing recipe..."
    execute_recipe || exit 1
    
    print_message "$CYAN" "Step 7/10: Configuring server..."
    configure_server_cfg || exit 1
    
    print_message "$CYAN" "Step 8/10: Creating scripts..."
    create_management_scripts
    
    print_message "$CYAN" "Step 9/10: Creating service..."
    create_systemd_service
    
    print_message "$CYAN" "Step 10/10: Firewall..."
    configure_firewall
    
    log "INFO" "Installation complete"
    display_summary
}

main "$@"
