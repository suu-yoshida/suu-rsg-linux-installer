# RSG RedM Framework - LINUX Automated Installer
# DEV VERSION - TESTED ON UBUNTU SERVER 20.04+ / DEBIAN 11+

<p align="center">
  <img src="https://img.shields.io/badge/Version-1.3-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/License-Custom_NC-yellow.svg" alt="License">
  <img src="https://img.shields.io/badge/Platform-Linux-orange.svg" alt="Platform">
  <img src="https://img.shields.io/badge/RedM-Compatible-red.svg" alt="RedM">
</p>

No more hassle installing RedM on Linux - finally a simple, exclusive version for RSG! A comprehensive, interactive bash script for automated deployment of RSG Framework RedM servers on Linux. Features one-click installation with txAdmin or standalone modes, real-time progress tracking, PhpMyAdmin integration, advanced database security, and complete server management tools.

## ✨ Features

### 🚀 Automated Installation
- **Interactive Setup**: Guided configuration with validation
- **Dual Modes**: Choose between txAdmin (web interface) or Standalone (console)
- **Smart Artifact Selection**: Automatically fetches latest RedM build
- **Recipe Execution**: Real-time visual progress with 60+ installation tasks
- **OneSync Auto-Config**: Automatic configuration for ox_lib compatibility

### 🎯 Server Management
- **Management Scripts**: `start.sh`, `stop.sh`, `restart.sh`, `attach.sh`, `update.sh`
- **txAdmin PIN Display**: Automatic PIN extraction and display on startup
- **Screen Integration**: Persistent server sessions with easy console access
- **Update System**: One-command artifact updates with backup
- **Complete Uninstaller**: Clean removal of all components including PhpMyAdmin

### 🗄️ Database & Security
- **MariaDB Integration**: Automated database creation and user setup
- **Password Confirmation**: Double-entry validation for security
- **Custom Ports**: Support for non-standard database ports
- **SQL Injection**: Automatic execution of RSG framework tables
- **4 Access Modes**:
  - **Local Only** (127.0.0.1) - Recommended & Secure
  - **Bind to Specific IP** - For VPN/Private Networks
  - **SSH Tunnel** - Secure remote access with automatic guide generation
  - **Public Access** - With explicit warnings and confirmation
- **Database Management Scripts**:
  - `db-open.sh` - Temporarily open database port (with security warnings)
  - `db-close.sh` - Close database port and secure
  - `db-status.sh` - Check current database security status

### 🌐 PhpMyAdmin Integration
- **Automated Installation**: Optional PhpMyAdmin setup with Apache2 & PHP
- **Pre-configured**: Ready-to-use database management interface
- **Security Features**: Built-in recommendations and easy disable/enable
- **Access Documentation**: Automatic generation of access information
- **Customizable URL**: Instructions for changing default /phpmyadmin path

### 🔧 Advanced Features
- **Resource Symlink**: Proper path resolution for RedM resources
- **Firewall Configuration**: Automatic UFW/firewalld rules for all services
- **Systemd Service**: Optional auto-start on boot
- **Comprehensive Logging**: Detailed installation and recipe logs
- **Verbose Mode**: Debug output for troubleshooting
- **SSH Tunnel Guide**: Auto-generated configuration for secure remote access

## 📋 Prerequisites

- **OS**: Ubuntu 20.04+ / Debian 11+ (tested)
- **Privileges**: Root/sudo access
- **Network**: Internet connection for downloads
- **Disk Space**: ~7GB free space (includes PhpMyAdmin if selected)
- **License**: CFX.re license key ([Get one here](https://keymaster.fivem.net))

## 🚀 Quick Start

### Installation

Download the installer:
```bash
wget https://raw.githubusercontent.com/suu-yoshida/suu-rsg-linux-installer/refs/heads/main/deploy-rsg.sh
```

Make it executable:
```bash
chmod +x deploy-rsg.sh
```

Run the installer:
```bash
sudo ./deploy-rsg.sh
```

### What to Expect

1. **Server Mode Selection**: Choose txAdmin or Standalone
2. **Configuration Input**: Enter server name, license, database credentials
3. **Database Access Mode**: Choose security level (Local/Bind IP/SSH Tunnel/Public)
4. **PhpMyAdmin Option**: Choose whether to install database web interface
5. **Automated Setup**: Sit back while the script:
   - Installs dependencies (MariaDB, Python, Git, Apache2, PHP, etc.)
   - Downloads latest RedM build
   - Executes RSG recipe (60+ tasks with real-time display)
   - Configures server.cfg with OneSync
   - Sets up PhpMyAdmin (if selected)
   - Configures database security
   - Creates all management scripts
6. **Completion**: Server ready to start with full documentation!

### Starting Your Server

#### txAdmin Mode
```bash
cd /home/RedM
./start.sh
```
Output will display:

```
🚀 Starting txAdmin...
⏳ Waiting for txAdmin to start...

✅ txAdmin started!

╔═══════════════════════════════════════╗
║          🔐 TXADMIN PIN CODE         ║
╠═══════════════════════════════════════╣
║                                       ║
║            📌   1234                 ║
║                                       ║
╚═══════════════════════════════════════╝
```

🌐 Access: `http://YOUR_IP:40120`

#### Standalone Mode
```bash
cd /home/RedM
./start.sh
```
Output: ✅ Started successfully - Console: `screen -r hostname_redm` (CTRL+A then D to detach)

## 📖 Usage

### Management Commands
```bash
cd /home/RedM

./start.sh          # Start server (displays txAdmin PIN if applicable)
./stop.sh           # Stop server
./restart.sh        # Restart server
./attach.sh         # Attach to server console
./update.sh         # Update RedM artifact
./db-open.sh        # ⚠️  Open database port (temporary, with warnings)
./db-close.sh       # 🔒 Close database port (secure)
./db-status.sh      # 📊 Check database security status
./uninstall.sh      # ⚠️  Complete uninstall (including PhpMyAdmin)
```

### Database Port Management

**Opening Database Port** (Use with caution):
```bash
./db-open.sh
# Type 'OPEN' to confirm
# WARNING: This exposes your database to the internet!
# Use SSH tunnel or VPN instead when possible
```

**Closing Database Port** (Secure):
```bash
./db-close.sh
# Immediately secures your database
```

**Checking Status**:
```bash
./db-status.sh
# Shows: Bind address, listening status, firewall rules
```

### PhpMyAdmin Access

If you installed PhpMyAdmin:
- URL: `http://YOUR_IP/phpmyadmin`
- Username: `rsg_user` (or root)
- Password: [your database password]

**Security Tips**:
- Change the default URL (see PHPMYADMIN_ACCESS.txt)
- Add .htaccess authentication
- Disable when not in use: `sudo a2disconf phpmyadmin && sudo systemctl reload apache2`
- Use SSH tunnel for remote access

### SSH Tunnel Usage

If you selected SSH Tunnel mode, a guide is generated at: `/home/RedM/SSH_TUNNEL_GUIDE.txt`

**Basic usage from your local machine**:
```bash
# Forward database port
ssh -L 3306:localhost:3306 root@YOUR_SERVER_IP

# Forward both database and PhpMyAdmin
ssh -L 3306:localhost:3306 -L 8080:localhost:80 root@YOUR_SERVER_IP
```

Then connect to `localhost:3306` or `localhost:8080/phpmyadmin`

### Console Access

Attach to server console:
```bash
screen -r $(hostname)_redm        # For standalone
screen -r $(hostname)_redm_txadmin # For txAdmin
```

Detach from console: `CTRL+A` then `D`

### Logs

- **Installation Log**: `/var/log/redm/redm_rsg_install_TIMESTAMP.log`
- **Recipe Log**: `/var/log/redm/recipe_TIMESTAMP.log`
- **Latest Log**: `/var/log/redm/latest.log`

### Verbose Mode

For detailed output during installation:
```bash
sudo ./deploy-rsg.sh --verbose
```

## 🔧 Configuration

### Default Installation Paths

| Component | Path |
|-----------|------|
| Server Files | /home/RedM/server/ |
| Data Directory | /home/RedM/txData/ |
| Resources | /home/RedM/txData/resources/ |
| Server Config | /home/RedM/txData/server.cfg |
| Logs | /var/log/redm/ |
| PhpMyAdmin | /usr/share/phpmyadmin |
| Access Info | /home/RedM/PHPMYADMIN_ACCESS.txt |
| SSH Guide | /home/RedM/SSH_TUNNEL_GUIDE.txt |

### Default Ports

| Service | Port | Customizable |
|---------|------|--------------|
| Game Server | 30120 | ✅ Yes |
| txAdmin | 40120 | ✅ Yes |
| MariaDB | 3306 | ✅ Yes |
| PhpMyAdmin (HTTP) | 80 | ⚠️ System default |

All ports can be customized during installation.

### Database Access Modes

#### 1. Local Only (Recommended)
- **Bind IP**: 127.0.0.1
- **Security**: 🔒 Maximum
- **Use Case**: Server-only access
- **Access Method**: Direct on server or SSH tunnel

#### 2. Bind to Specific IP
- **Bind IP**: Your private IP (e.g., 10.0.0.5)
- **Security**: 🔒 High
- **Use Case**: VPN or private network
- **Access Method**: From specified IP only

#### 3. SSH Tunnel (Recommended for remote)
- **Bind IP**: 127.0.0.1
- **Security**: 🔒 Maximum
- **Use Case**: Secure remote access
- **Access Method**: SSH port forwarding
- **Bonus**: Auto-generated configuration guide

#### 4. Public Access
- **Bind IP**: 0.0.0.0
- **Security**: ⚠️ Low (not recommended)
- **Use Case**: Direct remote access (emergency only)
- **Access Method**: Any IP can connect
- **Warning**: Requires typing 'DANGEROUS' to confirm

### Server Configuration

Edit server.cfg:
```bash
nano /home/RedM/txData/server.cfg
```

Key settings:
- **OneSync**: Pre-configured and enabled
- **Database**: Auto-configured connection string
- **Endpoints**: TCP/UDP on configured port
- **Resources**: Organized in categories ([standalone], [framework], [mapmods])

## 🗑️ Uninstallation

Complete removal of all components:
```bash
cd /home/RedM
sudo ./uninstall.sh
```

Type DELETE (uppercase) to confirm. This will remove:
- ✅ Server files and directories
- ✅ Database and user
- ✅ Systemd service
- ✅ Firewall rules
- ✅ All logs
- ✅ PhpMyAdmin (if installed)
- ✅ Apache2/PHP (optional)

Optional: Remove MariaDB when prompted.

## 🐛 Troubleshooting

### Server Won't Start

Check logs:
```bash
tail -f /var/log/redm/latest.log
```

Attach to console to see errors:
```bash
cd /home/RedM
./attach.sh
```

### Resources Not Found

Verify symlink:
```bash
ls -la /home/RedM/server/resources
# Should point to: ../txData/resources
```

Recreate if needed:
```bash
cd /home/RedM/server
rm -f resources
ln -s ../txData/resources ./resources
```

### Database Connection Failed

Test database:
```bash
mysql -u rsg_user -p -D rsg_db
```

Check connection string in server.cfg:
```bash
grep mysql_connection_string /home/RedM/txData/server.cfg
```

Check database status:
```bash
cd /home/RedM
./db-status.sh
```

### PhpMyAdmin Not Accessible

Check Apache status:
```bash
systemctl status apache2
```

Verify configuration:
```bash
apache2ctl -t
```

Check if enabled:
```bash
a2query -c phpmyadmin
```

Re-enable if needed:
```bash
sudo a2enconf phpmyadmin
sudo systemctl reload apache2
```

### Database Port Issues

If you can't connect remotely:

1. Check bind address:
```bash
grep bind-address /etc/mysql/mariadb.conf.d/50-server.cnf
```

2. Check firewall:
```bash
sudo ufw status | grep 3306
```

3. Check database status:
```bash
./db-status.sh
```

4. If needed, use SSH tunnel instead:
```bash
cat /home/RedM/SSH_TUNNEL_GUIDE.txt
```

### txAdmin PIN Not Displaying

Manually check console:
```bash
screen -r $(hostname)_redm_txadmin
# Look for: TX_PIN: XXXX
```

## 📦 What Gets Installed

### System Packages
- mariadb-server - Database server
- python3, python3-pip - Python runtime
- git - Version control
- screen - Terminal multiplexer
- wget, curl - Download tools
- tar, xz-utils - Archive tools
- unzip, jq - Utilities
- net-tools - Network utilities
- apache2 - Web server (if PhpMyAdmin selected)
- php, php-mysql, php-mbstring - PHP runtime (if PhpMyAdmin selected)
- phpmyadmin - Database web interface (optional)

### Python Packages
- pyyaml - YAML parser for recipe execution

### RedM Components
- Latest RedM server build
- RSG Framework (60+ resources)
- ox_lib, oxmysql, ox_target
- All RSG core resources
- Map mods and standalone resources

## 🏗️ Architecture

```
/home/RedM/
├── server/                    # RedM server binaries
│   ├── run.sh                # Server executable
│   ├── alpine/               # Server runtime
│   └── resources/            # Symlink to txData/resources
├── txData/                   # Server data
│   ├── server.cfg           # Server configuration
│   ├── resources/           # All game resources
│   │   ├── [cfx-default]/
│   │   ├── [standalone]/
│   │   ├── [framework]/
│   │   └── [mapmods]/
│   └── myLogo.png
├── recipe/
│   └── rsgcore.yaml         # Installation recipe
├── start.sh                 # Start script (with PIN display)
├── stop.sh                  # Stop script
├── restart.sh               # Restart script
├── attach.sh                # Console attach
├── update.sh                # Update script
├── db-open.sh               # 🔓 Open database port (temporary)
├── db-close.sh              # 🔒 Close database port (secure)
├── db-status.sh             # 📊 Database status checker
├── uninstall.sh             # Uninstaller
├── PHPMYADMIN_ACCESS.txt    # PhpMyAdmin info (if installed)
└── SSH_TUNNEL_GUIDE.txt     # SSH tunnel guide (if SSH mode)
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 🔄 Changelog

### Version 1.3 (Current - October 2025)
- ✨ **PhpMyAdmin Integration** - Optional web-based database management
- ✨ **4 Database Access Modes** - Local/Bind IP/SSH Tunnel/Public
- ✨ **Database Management Scripts** - db-open.sh, db-close.sh, db-status.sh
- ✨ **SSH Tunnel Guide** - Auto-generated secure access documentation
- ✨ **Enhanced Security** - Explicit warnings for dangerous configurations
- ✨ **Apache2 Integration** - Web server setup for PhpMyAdmin
- 🐛 **Improved Firewall** - HTTP port management for web services
- 🐛 **Enhanced Uninstaller** - Removes PhpMyAdmin and Apache2 (optional)

### Version 1.2
- ✨ Added txAdmin PIN auto-display
- ✨ Real-time recipe execution progress
- ✨ Password confirmation for database
- ✨ Complete uninstall script
- 🐛 Fixed OneSync configuration
- 🐛 Fixed resource path symlink
- 🐛 Fixed txAdmin Linux compatibility

### Version 1.1
- ✨ txAdmin/Standalone mode selection
- 🐛 Fixed FXServer execution on Linux

### Version 1.0
- 🎉 Initial public release
- ✨ Automated RSG Framework deployment
- ✨ Interactive configuration
- ✨ Database setup

## 📝 License

This project is licensed under a Custom Non-Commercial License - see the [LICENSE](LICENSE) file for details.

**Summary:**
- ✅ Free to use and modify for personal/non-commercial purposes
- ✅ Must credit the original author (suu-yoshida)
- ✅ Modified versions must use the same license
- ❌ Cannot be sold or used commercially without permission

## 🙏 Credits

### Frameworks & Inspiration
- **[RSG Framework](https://github.com/Rexshack-RedM)** - RedM framework foundation
- **[txAdmin](https://github.com/tabarra/txAdmin)** - Server management interface
- **[CFX.re](https://fivem.net/)** - FiveM/RedM platform

### Tools & Resources
- **[Dolyyyy/cfx_bash_updater_and_restarter](https://github.com/Dolyyyy/cfx_bash_updater_and_restarter)** - Inspiration for artifact update system and screen management
- **[solareon/fxserver_deployer](https://github.com/solareon/fxserver_deployer)** - Reference for recipe-based deployment architecture

### Special Thanks
- **Overextended** - ox_lib, oxmysql, ox_target
- **RSG Community** - Resources and support
- **PhpMyAdmin Team** - Database management interface
- All contributors to the RSG Framework ecosystem

## 🔐 Security Best Practices

### Database Security
1. **Always start with Local Only mode** - Use SSH tunnel for remote access
2. **Never use Public mode** unless absolutely necessary and temporarily
3. **Use db-close.sh immediately** after opening ports
4. **Monitor with db-status.sh** regularly
5. **Use strong passwords** - Minimum 16 characters, mixed case, numbers, symbols

### PhpMyAdmin Security
1. **Change the default URL** - /phpmyadmin → /your-secret-path
2. **Add .htaccess authentication** - Extra layer of security
3. **Disable when not in use** - sudo a2disconf phpmyadmin
4. **Access via SSH tunnel** - Never expose directly to internet
5. **Keep updated** - sudo apt update && sudo apt upgrade phpmyadmin

### Server Security
1. **Use SSH keys** instead of passwords
2. **Change default SSH port** from 22
3. **Enable UFW firewall** - Only open necessary ports
4. **Regular updates** - Keep system packages up to date
5. **Monitor logs** - Check /var/log/redm/ regularly

---

<p align="center">Made with ❤️ for the RedM community</p>
<p align="center">⭐ Star this repository if you find it useful!</p>

## ⚠️ Attribution Requirements

If you use or modify this installer, you **MUST**:

1. ✅ Credit **suu-yoshida** as the original author
2. ✅ Link to this repository: https://github.com/suu-yoshida/suu-rsg-linux-installer
3. ✅ Keep the entire **Credits section** intact in your documentation
4. ✅ Credit all referenced authors:
   - **Rexshack-RedM** (RSG Framework)
   - **tabarra** (txAdmin)
   - **Dolyyyy** (cfx_bash_updater_and_restarter)
   - **solareon** (fxserver_deployer)
   - **CFX.re** (RedM platform)
   - **PhpMyAdmin Team** (Database management)
5. ✅ Indicate what changes you made (if any)

**Example attribution:**

Based on RSG RedM Framework Linux Installer by suu-yoshida
Original: https://github.com/suu-yoshida/suu-rsg-linux-installer
Modified by [Your Name] - [Description of changes]

Credits to all referenced projects:
- RSG Framework by Rexshack-RedM
- Update system inspired by Dolyyyy's cfx_bash_updater_and_restarter
- Deployment architecture inspired by solareon's fxserver_deployer
- PhpMyAdmin for database management

❌ **Removing credits or claiming this work as entirely your own violates the license.**

**Need Help?** Join the RSG Discord: https://discord.gg/eW3ADkf4Af
