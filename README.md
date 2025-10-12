# RSG RedM Framework - LINUX Automated Installer

<p align="center">
  <img src="https://img.shields.io/badge/Version-5.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/Platform-Linux-orange.svg" alt="Platform">
  <img src="https://img.shields.io/badge/RedM-Compatible-red.svg" alt="RedM">
</p>

A comprehensive, interactive bash script for automated deployment of RSG Framework RedM servers on Linux. Features one-click installation with txAdmin or standalone modes, real-time progress tracking, and complete server management tools.

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
- **Complete Uninstaller**: Clean removal of all components

### 🗄️ Database
- **MariaDB Integration**: Automated database creation and user setup
- **Password Confirmation**: Double-entry validation for security
- **Custom Ports**: Support for non-standard database ports
- **SQL Injection**: Automatic execution of RSG framework tables

### 🔧 Advanced Features
- **Resource Symlink**: Proper path resolution for RedM resources
- **Firewall Configuration**: Automatic UFW/firewalld rules
- **Systemd Service**: Optional auto-start on boot
- **Comprehensive Logging**: Detailed installation and recipe logs
- **Verbose Mode**: Debug output for troubleshooting

## 📋 Prerequisites

- **OS**: Ubuntu 20.04+ / Debian 11+ (tested)
- **Privileges**: Root/sudo access
- **Network**: Internet connection for downloads
- **Disk Space**: ~5GB free space
- **License**: CFX.re license key ([Get one here](https://keymaster.fivem.net))

## 🚀 Quick Start

### Installation

Download the installer  
```bash
wget https://raw.githubusercontent.com/suu-yoshida/suu-rsg-linux-installer/refs/heads/main/deploy-rsg.sh
```

Make it executable  
```bash
chmod +x deploy-rsg.sh
```

Run the installer  
```bash
sudo ./deploy-rsg.sh
```

### What to Expect

1. **Server Mode Selection**: Choose txAdmin or Standalone  
2. **Configuration Input**: Enter server name, license, database credentials  
3. **Automated Setup**: Sit back while the script:  
   - Installs dependencies (MariaDB, Python, Git, etc.)  
   - Downloads latest RedM build  
   - Executes RSG recipe (60+ tasks with real-time display)  
   - Configures server.cfg with OneSync  
   - Sets up management scripts  
4. **Completion**: Server ready to start!

### Starting Your Server

#### txAdmin Mode
```bash
cd /home/RedM
./start.sh
```
Output will display:  
🚀 Starting txAdmin...  
⏳ Waiting for txAdmin to start...  
✅ txAdmin started!  

╔═══════════════════════════════════════╗  
  🔐       TXADMIN PIN CODE               
╠═══════════════════════════════════════╣  
                  1234                     
╚═══════════════════════════════════════╝  
🌐 Access: http://YOUR_IP:40120

#### Standalone Mode
```bash
cd /home/RedM
./start.sh
```
✅ Started successfully  
Console: `screen -r hostname_redm` (CTRL+A then D to detach)

## 📖 Usage

### Management Commands

```bash
cd /home/RedM
./start.sh
./stop.sh
./restart.sh
./attach.sh
./update.sh
./uninstall.sh
```

### Console Access

Attach to server console:  
```bash
screen -r $(hostname)_redm      # For standalone
screen -r $(hostname)_redm_txadmin  # For txAdmin
```
Detach: `CTRL+A` then `D`

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
| Server Files | `/home/RedM/server/` |
| Data Directory | `/home/RedM/txData/` |
| Resources | `/home/RedM/txData/resources/` |
| Server Config | `/home/RedM/txData/server.cfg` |
| Logs | `/var/log/redm/` |

### Default Ports

| Service | Port |
|---------|------|
| Game Server | 30120 |
| txAdmin | 40120 |
| MariaDB | 3306 |

All ports can be customized during installation.

### Server Configuration

Edit `server.cfg`:  
```bash
nano /home/RedM/txData/server.cfg
```

Key settings:  
- **OneSync**: Pre-configured and enabled  
- **Database**: Auto-configured connection string  
- **Endpoints**: TCP/UDP on configured port  
- **Resources**: Organized in categories (`[standalone]`, `[framework]`, `[mapmods]`)

## 🗑️ Uninstallation

Complete removal of all components:  
```bash
cd /home/RedM
sudo ./uninstall.sh
```

Type `DELETE` (uppercase) to confirm. This will remove:  
- ✅ Server files and directories  
- ✅ Database and user  
- ✅ Systemd service  
- ✅ Firewall rules  
- ✅ All logs  

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
```
Should point to: `../txData/resources`

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

Check connection string in `server.cfg`:  
```bash
grep mysql_connection_string /home/RedM/txData/server.cfg
```

### txAdmin PIN Not Displaying

Manually check console:  
```bash
screen -r $(hostname)_redm_txadmin
```

Look for: `TX_PIN: XXXX`

## 📦 What Gets Installed

### System Packages
- `mariadb-server` - Database server
- `python3`, `python3-pip` - Python runtime
- `git` - Version control
- `screen` - Terminal multiplexer
- `wget`, `curl` - Download tools
- `tar`, `xz-utils` - Archive tools
- `unzip`, `jq` - Utilities

### Python Packages
- `pyyaml` - YAML parser for recipe execution

### RedM Components
- Latest RedM server build
- RSG Framework (60+ resources)
- ox_lib, oxmysql, ox_target
- All RSG core resources
- Map mods and standalone resources

## 🏗️ Architecture

```
/home/RedM/
├── server/ # RedM server binaries
│ ├── run.sh # Server executable
│ ├── alpine/ # Server runtime
│ └── resources/ # Symlink to txData/resources
├── txData/ # Server data
│ ├── server.cfg # Server configuration
│ ├── resources/ # All game resources
│ │ ├── [cfx-default]/
│ │ ├── [standalone]/
│ │ ├── [framework]/
│ │ └── [mapmods]/
│ └── myLogo.png
├── recipe/
│ └── rsgcore.yaml # Installation recipe
├── start.sh # Start script
├── stop.sh # Stop script
├── restart.sh # Restart script
├── attach.sh # Console attach
├── update.sh # Update script
└── uninstall.sh # Uninstaller
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository  
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)  
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)  
4. Push to the branch (`git push origin feature/AmazingFeature`)  
5. Open a Pull Request  

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

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
- **RSG** - Resources and support  
- All contributors to the RSG Framework ecosystem  


## 🔄 Changelog

### Version 1.2 (Current)
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
- 🎉 Initial release  
- ✨ Automated RSG Framework deployment  
- ✨ Interactive configuration  
- ✨ Database setup  

---

<p align="center">Made with ❤️ for the RedM community</p>
<p align="center">⭐ Star this repository if you find it useful!</p>
