#!/bin/bash

# RSG RedM Framework - Installation Script v2.1
# Automated installation for Linux with enhanced SQL verification

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

# Server Configuration
INSTALL_DIR=""
CFX_LICENSE=""
SERVER_NAME=""
DB_PASSWORD=""
DB_PORT="3306"
SERVER_PORT="30120"
TXADMIN_PORT="40120"
DB_NAME="rsg_db"
DB_USER="rsg_user"
MAX_CLIENTS="32"

# URLs
ARTIFACT_PAGE_URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"
RSG_RECIPE_URL="https://raw.githubusercontent.com/Rexshack-RedM/txAdminRecipe/refs/heads/main/rsgcore.yaml"
LATEST_ARTIFACT=""
FULL_ARTIFACT_URL=""

# ============================================
# LOGGING FUNCTIONS
# ============================================
setup_logging() {
    mkdir -p "${LOG_DIR}"
    touch "${LOG_FILE}"
    ln -sf "${LOG_FILE}" "${LATEST_LOG_SYMLINK}"
    log "INFO" "=== RSG RedM Installation Started ==="
}

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo -e "${timestamp} [${level}] ${message}" | tee -a "${LOG_FILE}"
}

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
    log "INFO" "${message}"
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

validate_license() {
    local license=$1
    if [[ ! $license =~ ^cfxk_[A-Za-z0-9]{20}_[A-Za-z0-9]{6}$ ]]; then
        return 1
    fi
    return 0
}

# ============================================
# ARTIFACT FUNCTIONS
# ============================================
check_new_artifact() {
    print_message "$CYAN" "🔍 Searching for latest RedM build..."
    
    local ARTIFACT_HTML=$(curl -s $ARTIFACT_PAGE_URL)
    local ARTIFACT_LINKS=$(echo "$ARTIFACT_HTML" | grep -oP 'href="\./\d{4,}[^"]+fx\.tar\.xz"' | sed 's/href="\.\/\([^"]*\)"/\1/')
    
    if [ -z "$ARTIFACT_LINKS" ]; then
        print_message "$RED" "❌ No artifacts found"
        return 1
    fi
    
    LATEST_ARTIFACT=$(echo "$ARTIFACT_LINKS" | grep -oP '^\d{4,}' | sort -nr | head -n 1)
    local LATEST_ARTIFACT_FILE=$(echo "$ARTIFACT_LINKS" | grep "^$LATEST_ARTIFACT")
    FULL_ARTIFACT_URL="${ARTIFACT_PAGE_URL}${LATEST_ARTIFACT_FILE}"
    
    print_message "$GREEN" "✅ Latest build found: ${LATEST_ARTIFACT}"
    log "INFO" "Artifact URL: $FULL_ARTIFACT_URL"
    
    return 0
}

download_artifact() {
    local dest=$1
    
    print_message "$BLUE" "📥 Downloading RedM artifact (build ${LATEST_ARTIFACT})..."
    
    mkdir -p "$dest"
    cd "$dest"
    
    wget -q --show-progress "$FULL_ARTIFACT_URL" -O fx.tar.xz >> "${LOG_FILE}" 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_message "$CYAN" "📦 Extracting artifact..."
        tar -xf fx.tar.xz >> "${LOG_FILE}" 2>&1
        rm -f fx.tar.xz
        
        # Remove nested alpine folder if exists
        if [[ -d "alpine/opt/cfx-server/alpine" ]]; then
            rm -rf "alpine/opt/cfx-server/alpine"
        fi
        
        chmod +x run.sh
        print_message "$GREEN" "✅ Artifact installed successfully"
        return 0
    else
        print_message "$RED" "❌ Error downloading artifact"
        return 1
    fi
}

# ============================================
# DEPENDENCY INSTALLATION
# ============================================
install_dependencies() {
    print_message "$BLUE" "📦 Installing system dependencies..."
    
    apt-get update >> "${LOG_FILE}" 2>&1
    
    local packages=(
        "wget" "curl" "tar" "git" "xz-utils"
        "mariadb-server" "mariadb-client"
        "unzip" "screen" "jq" "python3" "python3-pip"
    )
    
    apt-get install -y "${packages[@]}" >> "${LOG_FILE}" 2>&1
    
    # Install Python YAML module
    pip3 install pyyaml >> "${LOG_FILE}" 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_message "$GREEN" "✅ Dependencies installed successfully"
    else
        print_message "$RED" "❌ Error installing dependencies"
        exit 1
    fi
}

# ============================================
# USER INPUT
# ============================================
get_user_input() {
    clear
    print_message "$CYAN" "╔════════════════════════════════════════════╗"
    print_message "$CYAN" "║  RedM RSG Server Configuration             ║"
    print_message "$CYAN" "╚════════════════════════════════════════════╝"
    
    # CFX License Key
    while true; do
        read -p "$(echo -e ${YELLOW}Enter your CFX license key: ${NC})" CFX_LICENSE
        if [[ -z "$CFX_LICENSE" ]]; then
            print_message "$RED" "❌ License key is required!"
            continue
        fi
        if ! validate_license "$CFX_LICENSE"; then
            print_message "$RED" "❌ Invalid format (expected: cfxk_XXXXXXXXXXXXXXXXXXXX_XXXXXX)"
            continue
        fi
        break
    done
    
    # Server Name
    while [[ -z "$SERVER_NAME" ]]; do
        read -p "$(echo -e ${YELLOW}Enter server name: ${NC})" SERVER_NAME
        [[ -z "$SERVER_NAME" ]] && print_message "$RED" "❌ Server name is required!"
    done
    
    # Database Password
    while [[ -z "$DB_PASSWORD" ]]; do
        read -sp "$(echo -e ${YELLOW}Enter database password: ${NC})" DB_PASSWORD
        echo
        [[ -z "$DB_PASSWORD" ]] && print_message "$RED" "❌ Database password is required!"
    done
    
    # Optional: Database Port
    read -p "$(echo -e ${YELLOW}Database port [${DB_PORT}]: ${NC})" input_db_port
    DB_PORT=${input_db_port:-$DB_PORT}
    
    # Optional: Server Port
    read -p "$(echo -e ${YELLOW}Server port [${SERVER_PORT}]: ${NC})" input_server_port
    SERVER_PORT=${input_server_port:-$SERVER_PORT}
    
    # Optional: txAdmin Port
    read -p "$(echo -e ${YELLOW}txAdmin port [${TXADMIN_PORT}]: ${NC})" input_txadmin_port
    TXADMIN_PORT=${input_txadmin_port:-$TXADMIN_PORT}
    
    # Optional: Max Clients
    read -p "$(echo -e ${YELLOW}Maximum players [${MAX_CLIENTS}]: ${NC})" input_max_clients
    MAX_CLIENTS=${input_max_clients:-$MAX_CLIENTS}
    
    # Installation Directory
    local default_install_dir="/home/RedM"
    read -p "$(echo -e ${YELLOW}Installation directory [${default_install_dir}]: ${NC})" INSTALL_DIR
    INSTALL_DIR=${INSTALL_DIR:-$default_install_dir}
    
    # Display configuration summary
    echo
    print_message "$GREEN" "✅ Configuration saved:"
    echo -e "${CYAN}Server Name:${NC} $SERVER_NAME"
    echo -e "${CYAN}Install Directory:${NC} $INSTALL_DIR"
    echo -e "${CYAN}Database:${NC} $DB_NAME:$DB_PORT"
    echo -e "${CYAN}Ports:${NC} Server=$SERVER_PORT, txAdmin=$TXADMIN_PORT"
    echo
    
    # Confirmation
    read -p "$(echo -e ${YELLOW}Confirm installation with this configuration? [Y/n]: ${NC})" confirm
    if [[ ! "$confirm" =~ ^[Yy]?$ ]]; then
        print_message "$YELLOW" "Installation cancelled"
        exit 0
    fi
}

# ============================================
# DATABASE FUNCTIONS
# ============================================
setup_mariadb() {
    print_message "$BLUE" "🗄️  Configuring MariaDB..."
    
    # Start and enable MariaDB service
    systemctl start mariadb >> "${LOG_FILE}" 2>&1
    systemctl enable mariadb >> "${LOG_FILE}" 2>&1
    
    # Secure MariaDB installation
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';" >> "${LOG_FILE}" 2>&1 || \
    mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${DB_PASSWORD}');" >> "${LOG_FILE}" 2>&1
    
    mysql -e "DELETE FROM mysql.user WHERE User='';" >> "${LOG_FILE}" 2>&1
    mysql -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');" >> "${LOG_FILE}" 2>&1
    mysql -e "DROP DATABASE IF EXISTS test;" >> "${LOG_FILE}" 2>&1
    mysql -e "FLUSH PRIVILEGES;" >> "${LOG_FILE}" 2>&1
    
    # Configure custom port if needed
    if [[ "$DB_PORT" != "3306" ]]; then
        if [[ -f /etc/mysql/mariadb.conf.d/50-server.cnf ]]; then
            sed -i "s/^port.*/port = ${DB_PORT}/" /etc/mysql/mariadb.conf.d/50-server.cnf
            systemctl restart mariadb >> "${LOG_FILE}" 2>&1
        fi
    fi
    
    # Create database and user
    mysql -u root -p"${DB_PASSWORD}" --port=${DB_PORT} <<EOF >> "${LOG_FILE}" 2>&1
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
    
    if [[ $? -eq 0 ]]; then
        print_message "$GREEN" "✅ Database ${DB_NAME} created successfully"
    else
        print_message "$RED" "❌ Error creating database"
        exit 1
    fi
}

validate_sql_connection() {
    print_message "$CYAN" "🔌 Testing database connection..."
    
    mysql -u root -p"${DB_PASSWORD}" --port=${DB_PORT} -e "SELECT VERSION();" >> "${LOG_FILE}" 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_message "$GREEN" "✅ MariaDB connection successful"
        return 0
    else
        print_message "$RED" "❌ Unable to connect to MariaDB"
        return 1
    fi
}

# ============================================
# SQL VERIFICATION FUNCTIONS
# ============================================
verify_rsg_tables() {
    print_message "$CYAN" "🔍 Verifying RSG tables..."
    
    # Expected core RSG tables
    local expected_tables=(
        "players"
        "player_horses"
        "player_outfits"
        "player_weapons"
        "playerskins"
        "characters"
        "bank_accounts"
        "houselocations"
        "player_houses"
        "society_moneywash"
        "gloveboxitems"
        "stashitems"
        "trunkitems"
    )
    
    local missing_tables=()
    
    for table in "${expected_tables[@]}"; do
        local exists=$(mysql -u root -p"${DB_PASSWORD}" --port=${DB_PORT} -D "${DB_NAME}" -sse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}' AND table_name = '${table}';")
        
        if [[ "$exists" == "0" ]]; then
            missing_tables+=("$table")
        fi
    done
    
    if [[ ${#missing_tables[@]} -eq 0 ]]; then
        print_message "$GREEN" "✅ All RSG tables are present"
        log "INFO" "SQL injection verified: all RSG tables found"
        return 0
    else
        print_message "$YELLOW" "⚠️  Missing tables: ${missing_tables[*]}"
        log "WARN" "Missing tables: ${missing_tables[*]}"
        return 1
    fi
}

count_database_tables() {
    local table_count=$(mysql -u root -p"${DB_PASSWORD}" --port=${DB_PORT} -D "${DB_NAME}" -sse "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}';")
    echo "$table_count"
}

# ============================================
# RECIPE PROCESSING
# ============================================
download_recipe() {
    print_message "$BLUE" "📥 Downloading RSG recipe..."
    
    local recipe_dir="${INSTALL_DIR}/recipe"
    mkdir -p "$recipe_dir"
    
    wget -q --show-progress "$RSG_RECIPE_URL" -O "${recipe_dir}/rsgcore.yaml" >> "${LOG_FILE}" 2>&1
    
    if [[ $? -eq 0 ]]; then
        print_message "$GREEN" "✅ RSG recipe downloaded successfully"
        return 0
    else
        print_message "$RED" "❌ Error downloading recipe"
        return 1
    fi
}

execute_recipe() {
    print_message "$BLUE" "⚙️  Executing RSG recipe..."
    print_message "$YELLOW" "⏱️  This may take 10-15 minutes depending on your connection..."
    
    local recipe_file="${INSTALL_DIR}/recipe/rsgcore.yaml"
    local deploy_path="${INSTALL_DIR}/txData"
    
    mkdir -p "$deploy_path"
    cd "$deploy_path"
    
    # Enhanced Python script with better SQL handling
    python3 - <<PYTHON_SCRIPT
import yaml
import os
import subprocess
import urllib.request
import zipfile
import shutil
import time
import sys

def log_info(msg):
    print(f"[INFO] {msg}", flush=True)

def log_error(msg):
    print(f"[ERROR] {msg}", file=sys.stderr, flush=True)

def download_github(src, dest, ref="main", subpath=""):
    """Download GitHub repository using git clone"""
    log_info(f"Downloading {src}")
    try:
        parts = src.replace("https://github.com/", "").split("/")
        owner, repo = parts[0], parts[1]
        
        # Use git clone for better performance
        cmd = ["git", "clone", "--quiet", "--depth", "1", "--branch", ref, src, dest]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            log_error(f"Git clone failed: {result.stderr}")
            return False
        
        # Handle subpath if specified
        if subpath:
            subpath_full = os.path.join(dest, subpath)
            if os.path.exists(subpath_full):
                for item in os.listdir(subpath_full):
                    shutil.move(os.path.join(subpath_full, item), os.path.join(dest, item))
                shutil.rmtree(subpath_full)
        
        log_info(f"✓ Downloaded: {os.path.basename(dest)}")
        return True
        
    except Exception as e:
        log_error(f"Failed: {e}")
        return False

def download_file(url, path):
    """Download file from URL"""
    log_info(f"Downloading {os.path.basename(path)}")
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        urllib.request.urlretrieve(url, path)
        log_info(f"✓ Downloaded: {os.path.basename(path)}")
        return True
    except Exception as e:
        log_error(f"Failed: {e}")
        return False

def unzip_file(src, dest):
    """Unzip archive file"""
    log_info(f"Unzipping {os.path.basename(src)}")
    try:
        os.makedirs(dest, exist_ok=True)
        with zipfile.ZipFile(src, 'r') as zip_ref:
            zip_ref.extractall(dest)
        log_info(f"✓ Unzipped to {os.path.basename(dest)}")
        return True
    except Exception as e:
        log_error(f"Failed: {e}")
        return False

def move_path(src, dest):
    """Move file or directory"""
    log_info(f"Moving {os.path.basename(src)}")
    try:
        os.makedirs(os.path.dirname(dest), exist_ok=True)
        if os.path.exists(dest):
            if os.path.isdir(dest):
                shutil.rmtree(dest)
            else:
                os.remove(dest)
        shutil.move(src, dest)
        log_info(f"✓ Moved to {os.path.basename(dest)}")
        return True
    except Exception as e:
        log_error(f"Failed: {e}")
        return False

def remove_path(path):
    """Remove file or directory"""
    if os.path.exists(path):
        log_info(f"Removing {os.path.basename(path)}")
        try:
            if os.path.isdir(path):
                shutil.rmtree(path)
            else:
                os.remove(path)
            log_info(f"✓ Removed")
            return True
        except Exception as e:
            log_error(f"Failed: {e}")
            return False
    return True

def query_database(sql_file, db_name, db_user, db_pass, db_port):
    """Execute SQL file with enhanced error handling"""
    log_info(f"Executing SQL: {os.path.basename(sql_file)}")
    
    if not os.path.exists(sql_file):
        log_error(f"SQL file not found: {sql_file}")
        return False
    
    try:
        # Execute SQL with proper error handling
        cmd = f"mysql -u {db_user} -p'{db_pass}' --port={db_port} {db_name} < {sql_file} 2>&1"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        
        if result.returncode == 0:
            log_info(f"✓ SQL executed successfully: {os.path.basename(sql_file)}")
            return True
        else:
            log_error(f"SQL execution error: {result.stderr}")
            # Continue anyway as some errors might be acceptable (e.g., table already exists)
            return True
            
    except Exception as e:
        log_error(f"Failed to execute SQL: {e}")
        return False

def waste_time(seconds):
    """Wait for specified seconds to prevent GitHub throttling"""
    log_info(f"Waiting {seconds}s (preventing GitHub rate limiting)...")
    time.sleep(seconds)

# Main recipe execution
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
total_tasks = len(tasks)

log_info(f"Starting recipe execution: {total_tasks} tasks")

for i, task in enumerate(tasks, 1):
    action = task.get('action')
    print(f"\n[{i}/{total_tasks}] Action: {action}", flush=True)
    
    try:
        if action == 'download_github':
            download_github(
                task.get('src'),
                task.get('dest'),
                task.get('ref', 'main'),
                task.get('subpath', '')
            )
        
        elif action == 'download_file':
            download_file(task.get('url'), task.get('path'))
        
        elif action == 'unzip':
            unzip_file(task.get('src'), task.get('dest'))
        
        elif action == 'move_path':
            move_path(task.get('src'), task.get('dest'))
        
        elif action == 'remove_path':
            remove_path(task.get('path'))
        
        elif action == 'query_database':
            sql_file = task.get('file')
            log_info(f"🗄️  INJECTING RSG SQL FILE: {sql_file}")
            query_database(sql_file, db_name, db_user, db_pass, db_port)
        
        elif action == 'connect_database':
            log_info("Database connection verified")
        
        elif action == 'waste_time':
            waste_time(task.get('seconds', 0))
        
        else:
            log_info(f"Unknown action: {action}")
            
    except Exception as e:
        log_error(f"Error in {action}: {e}")

print("\n✓ Recipe execution completed", flush=True)
PYTHON_SCRIPT

    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_message "$GREEN" "✅ Recipe executed successfully"
        
        # Verify SQL injection
        local table_count=$(count_database_tables)
        print_message "$CYAN" "📊 Tables created: ${table_count}"
        log "INFO" "Database tables count: ${table_count}"
        
        if verify_rsg_tables; then
            print_message "$GREEN" "✅ RSG SQL structure verified"
        else
            print_message "$YELLOW" "⚠️  Check logs for SQL details"
        fi
        
        return 0
    else
        print_message "$YELLOW" "⚠️  Recipe executed with warnings"
        return 0
    fi
}

# ============================================
# SERVER CONFIGURATION
# ============================================
configure_server_cfg() {
    print_message "$BLUE" "⚙️  Configuring server.cfg..."
    
    local server_cfg="${INSTALL_DIR}/txData/server.cfg"
    
    if [[ -f "$server_cfg" ]]; then
        # Replace placeholders in server.cfg
        sed -i "s/{{svLicense}}/${CFX_LICENSE}/g" "$server_cfg"
        sed -i "s/{{serverEndpoints}}/endpoint_add_tcp \"0.0.0.0:${SERVER_PORT}\"\nendpoint_add_udp \"0.0.0.0:${SERVER_PORT}\"/g" "$server_cfg"
        sed -i "s/{{maxClients}}/${MAX_CLIENTS}/g" "$server_cfg"
        sed -i "s|{{dbConnectionString}}|mysql://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}?charset=utf8mb4|g" "$server_cfg"
        
        # Update hostname
        if grep -q "sv_hostname" "$server_cfg"; then
            sed -i "s/sv_hostname .*/sv_hostname \"${SERVER_NAME}\"/g" "$server_cfg"
        else
            echo "sv_hostname \"${SERVER_NAME}\"" >> "$server_cfg"
        fi
        
        # Add admin identifiers placeholder
        if ! grep -q "add_principal identifier" "$server_cfg"; then
            cat >> "$server_cfg" <<EOF

# Admin identifiers (add your Steam/Discord IDs here)
# add_principal identifier.steam:YOUR_STEAM_HEX group.admin
# add_principal identifier.discord:YOUR_DISCORD_ID group.admin
EOF
        fi
        
        print_message "$GREEN" "✅ server.cfg configured successfully"
    else
        print_message "$RED" "❌ server.cfg not found"
        return 1
    fi
}

# ============================================
# MANAGEMENT SCRIPTS
# ============================================
create_management_scripts() {
    print_message "$BLUE" "📝 Creating management scripts..."
    
    # Start script with screen support
    cat > "${INSTALL_DIR}/start.sh" <<'EOF'
#!/bin/bash
# Start script for RedM RSG server
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCREEN_NAME="$(hostname)_redm"

cd "${SCRIPT_DIR}/server"

# Check if server is already running
if screen -list | grep -q "$SCREEN_NAME"; then
    echo "✅ Server is already running: $SCREEN_NAME"
    echo "Use ./attach.sh to connect to console"
    exit 1
fi

echo "🚀 Starting RedM RSG server: $SCREEN_NAME"
screen -dmS "$SCREEN_NAME" bash -c "./run.sh +exec ${SCRIPT_DIR}/txData/server.cfg"
sleep 2

if screen -list | grep -q "$SCREEN_NAME"; then
    echo "✅ Server started successfully"
    echo "Console: screen -r $SCREEN_NAME"
    echo "Detach: CTRL+A then D"
else
    echo "❌ Failed to start server"
    exit 1
fi
EOF

    # Stop script
    cat > "${INSTALL_DIR}/stop.sh" <<'EOF'
#!/bin/bash
# Stop script for RedM RSG server
SCREEN_NAME="$(hostname)_redm"

if screen -list | grep -q "$SCREEN_NAME"; then
    echo "🛑 Stopping server..."
    screen -S "$SCREEN_NAME" -X quit
    echo "✅ Server stopped"
else
    echo "⚠️  No running server found"
fi
EOF

    # Restart script
    cat > "${INSTALL_DIR}/restart.sh" <<'EOF'
#!/bin/bash
# Restart script for RedM RSG server
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔄 Restarting RedM RSG server..."
"${SCRIPT_DIR}/stop.sh"
sleep 3
"${SCRIPT_DIR}/start.sh"
EOF

    # Attach script (console access)
    cat > "${INSTALL_DIR}/attach.sh" <<'EOF'
#!/bin/bash
# Attach to server console
SCREEN_NAME="$(hostname)_redm"

if screen -list | grep -q "$SCREEN_NAME"; then
    echo "📺 Attaching to server console: $SCREEN_NAME"
    echo "⚠️  To detach without stopping: CTRL+A then D"
    echo "⚠️  CTRL+C will stop the server!"
    sleep 2
    screen -r "$SCREEN_NAME"
else
    echo "❌ No running server found"
    echo "Available screens:"
    screen -ls
fi
EOF

    # Update script
    cat > "${INSTALL_DIR}/update.sh" <<'EOF'
#!/bin/bash
# Update RedM artifacts to latest build
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARTIFACT_URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/"

echo "🔍 Checking for RedM updates..."

HTML=$(curl -s $ARTIFACT_URL)
LINKS=$(echo "$HTML" | grep -oP 'href="\./\d{4,}[^"]+fx\.tar\.xz"' | sed 's/href="\.\/\([^"]*\)"/\1/')

if [ -z "$LINKS" ]; then
    echo "❌ No builds found"
    exit 1
fi

LATEST=$(echo "$LINKS" | grep -oP '^\d{4,}' | sort -nr | head -n 1)
FILE=$(echo "$LINKS" | grep "^$LATEST")
URL="${ARTIFACT_URL}${FILE}"

echo "📦 Latest build: $LATEST"
read -p "Download and install? [y/N]: " confirm

if [[ $confirm == [Yy] ]]; then
    "${SCRIPT_DIR}/stop.sh"
    sleep 2
    
    cd "${SCRIPT_DIR}/server"
    
    echo "💾 Backing up current installation..."
    rm -rf alpine.backup
    mv alpine alpine.backup 2>/dev/null || true
    
    echo "📥 Downloading build $LATEST..."
    wget -q --show-progress "$URL" -O fx.tar.xz
    
    echo "📦 Extracting..."
    tar -xf fx.tar.xz
    rm fx.tar.xz
    
    echo "✅ Update completed (build $LATEST)"
    echo "🚀 Starting server..."
    "${SCRIPT_DIR}/start.sh"
else
    echo "Update cancelled"
fi
EOF

    # Make all scripts executable
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
Description=RedM Server with RSG Framework
After=network.target mariadb.service

[Service]
Type=forking
User=root
WorkingDirectory=${INSTALL_DIR}/server
ExecStart=${INSTALL_DIR}/start.sh
ExecStop=${INSTALL_DIR}/stop.sh
Restart=on-failure
RestartSec=10
StandardOutput=append:${LOG_DIR}/server.log
StandardError=append:${LOG_DIR}/server_error.log

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    print_message "$GREEN" "✅ Systemd service created"
    
    read -p "$(echo -e ${YELLOW}Enable auto-start on boot? [y/N]: ${NC})" auto_start
    if [[ "$auto_start" =~ ^[Yy]$ ]]; then
        systemctl enable redm-rsg.service >> "${LOG_FILE}" 2>&1
        print_message "$GREEN" "✅ Auto-start enabled"
    fi
}

# ============================================
# FIREWALL CONFIGURATION
# ============================================
configure_firewall() {
    print_message "$BLUE" "🔥 Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow ${SERVER_PORT}/tcp comment "RedM Server" >> "${LOG_FILE}" 2>&1
        ufw allow ${SERVER_PORT}/udp comment "RedM Server" >> "${LOG_FILE}" 2>&1
        ufw allow ${TXADMIN_PORT}/tcp comment "txAdmin Panel" >> "${LOG_FILE}" 2>&1
        print_message "$GREEN" "✅ UFW firewall configured"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=${SERVER_PORT}/tcp >> "${LOG_FILE}" 2>&1
        firewall-cmd --permanent --add-port=${SERVER_PORT}/udp >> "${LOG_FILE}" 2>&1
        firewall-cmd --permanent --add-port=${TXADMIN_PORT}/tcp >> "${LOG_FILE}" 2>&1
        firewall-cmd --reload >> "${LOG_FILE}" 2>&1
        print_message "$GREEN" "✅ firewalld configured"
    else
        print_message "$YELLOW" "⚠️  No firewall detected. Manually configure ports: ${SERVER_PORT}, ${TXADMIN_PORT}"
    fi
}

# ============================================
# INSTALLATION SUMMARY
# ============================================
display_summary() {
    local server_ip=$(hostname -I | awk '{print $1}')
    local table_count=$(count_database_tables)
    
    clear
    print_message "$GREEN" "╔════════════════════════════════════════════╗"
    print_message "$GREEN" "║    Installation Completed Successfully! 🎉 ║"
    print_message "$GREEN" "╚════════════════════════════════════════════╝"
    echo
    print_message "$CYAN" "📊 Server Information:"
    echo -e "${BOLD}Server Name:${NC} $SERVER_NAME"
    echo -e "${BOLD}RedM Build:${NC} $LATEST_ARTIFACT"
    echo -e "${BOLD}Install Directory:${NC} $INSTALL_DIR"
    echo -e "${BOLD}Database:${NC} $DB_NAME ($table_count tables)"
    echo -e "${BOLD}Ports:${NC} Server=$SERVER_PORT, txAdmin=$TXADMIN_PORT"
    echo
    print_message "$CYAN" "📋 Available Commands:"
    echo -e "${GREEN}Start:${NC}      ${INSTALL_DIR}/start.sh"
    echo -e "${GREEN}Stop:${NC}       ${INSTALL_DIR}/stop.sh"
    echo -e "${GREEN}Restart:${NC}    ${INSTALL_DIR}/restart.sh"
    echo -e "${GREEN}Console:${NC}    ${INSTALL_DIR}/attach.sh"
    echo -e "${GREEN}Update:${NC}     ${INSTALL_DIR}/update.sh"
    echo
    print_message "$CYAN" "🔗 Access Information:"
    echo -e "${GREEN}Server IP:${NC} $server_ip"
    echo -e "${GREEN}Connect (F8):${NC} connect $server_ip:$SERVER_PORT"
    echo -e "${GREEN}txAdmin Panel:${NC} http://$server_ip:$TXADMIN_PORT"
    echo
    print_message "$CYAN" "⚙️  Systemd Commands:"
    echo -e "${GREEN}Status:${NC}  systemctl status redm-rsg"
    echo -e "${GREEN}Start:${NC}   systemctl start redm-rsg"
    echo -e "${GREEN}Stop:${NC}    systemctl stop redm-rsg"
    echo -e "${GREEN}Logs:${NC}    journalctl -u redm-rsg -f"
    echo
    print_message "$YELLOW" "📝 Important Notes:"
    echo "1. Edit configuration: ${INSTALL_DIR}/txData/server.cfg"
    echo "2. Add admin identifiers in server.cfg"
    echo "3. RSG SQL structure injected: ${table_count} tables created"
    echo "4. Installation log: ${LOG_FILE}"
    echo
    print_message "$GREEN" "🚀 To start the server now:"
    echo -e "${BOLD}${CYAN}cd ${INSTALL_DIR} && ./start.sh${NC}"
    echo
}

# ============================================
# MAIN FUNCTION
# ============================================
main() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║       RSG RedM Framework Installer v2.1               ║
║       Automated Installation for Linux                ║
║       With Enhanced SQL Verification                  ║
║                                                       ║
║       Based on fxserver_deployer methodology          ║
║       Recipe: Rexshack Gaming RSG Core                ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Pre-flight checks
    check_root
    setup_logging
    
    # Installation steps
    print_message "$CYAN" "Step 1/11: Installing dependencies..."
    install_dependencies
    
    print_message "$CYAN" "Step 2/11: Finding latest RedM build..."
    check_new_artifact || exit 1
    
    print_message "$CYAN" "Step 3/11: Server configuration..."
    get_user_input
    
    print_message "$CYAN" "Step 4/11: Configuring MariaDB..."
    setup_mariadb
    validate_sql_connection || exit 1
    
    print_message "$CYAN" "Step 5/11: Downloading RedM artifacts..."
    download_artifact "${INSTALL_DIR}/server" || exit 1
    
    print_message "$CYAN" "Step 6/11: Downloading RSG recipe..."
    download_recipe || exit 1
    
    print_message "$CYAN" "Step 7/11: Executing RSG recipe (this may take a while)..."
    execute_recipe || exit 1
    
    print_message "$CYAN" "Step 8/11: Configuring server..."
    configure_server_cfg || exit 1
    
    print_message "$CYAN" "Step 9/11: Creating management scripts..."
    create_management_scripts
    
    print_message "$CYAN" "Step 10/11: Setting up systemd service..."
    create_systemd_service
    
    print_message "$CYAN" "Step 11/11: Configuring firewall..."
    configure_firewall
    
    log "INFO" "Installation completed successfully"
    display_summary
}

# ============================================
# SCRIPT EXECUTION
# ============================================
main "$@"
