# RSG Server Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)]()
[![RedM](https://img.shields.io/badge/RedM-Compatible-red)]()
[![RSG Framework](https://img.shields.io/badge/RSG-Framework-blue)]()

Automated installation script for **RSG Framework** on Linux servers with full automation, SQL injection verification, and management tools.

## ✨ Features

- 🚀 **One-line installation** from GitHub
- 📦 **Automated RSG recipe execution** with all resources
- 🗄️ **MariaDB auto-configuration** with SQL verification
- 🔍 **Latest RedM artifact detection** and download
- 🛠️ **Management scripts** (start, stop, restart, attach, update)
- 🔧 **Systemd service** for auto-start on boot
- 🔥 **Firewall auto-configuration** (UFW/firewalld)
- 📊 **Database verification** with table count
- 📝 **Detailed logging** for troubleshooting
- 🐧 **Ubuntu/Debian support** (tested on Ubuntu 20.04/22.04/24.04)

## 🚀 Quick Install

### One-liner (recommended)

```
curl -fsSL https://raw.githubusercontent.com/suu-yoshida/suu-rsg-linux-installer/refs/heads/main/deploy-rsg.sh | sudo bash
```

or with wget:

```
wget -qO- https://raw.githubusercontent.com/suu-yoshida/suu-rsg-linux-installer/refs/heads/main/deploy-rsg.sh | sudo bash
```

### Manual Installation

```
# Download the script
wget https://raw.githubusercontent.com/suu-yoshida/suu-rsg-linux-installer/refs/heads/main/deploy-rsg.sh

# Make it executable
chmod +x deploy-rsg.sh

# Run the installer
sudo ./deploy-rsg.sh
```

## 📋 Prerequisites

- **OS**: Ubuntu 20.04+ or Debian 10+
- **RAM**: Minimum 4GB (8GB recommended)
- **Disk**: Minimum 20GB free space
- **Network**: Active internet connection
- **Access**: Root or sudo privileges
- **CFX License**: Valid license key from [Cfx.re Keymaster](https://keymaster.fivem.net)

## 📖 What the Script Does

1. ✅ Installs system dependencies (wget, curl, git, MariaDB, etc.)
2. 🔍 Finds and downloads the latest RedM build
3. ⚙️ Configures MariaDB with custom database
4. 📥 Downloads official RSG recipe from GitHub
5. 🎯 Executes recipe (downloads 30+ resources)
6. 💾 Injects SQL data (players, characters, horses, etc.)
7. 🔧 Configures server.cfg with your settings
8. 📝 Creates management scripts
9. 🚀 Sets up systemd service
10. 🔥 Configures firewall rules

## 🎮 Usage

### Starting the Server

```
cd /home/RedM  # or your install directory
./start.sh
```

or with systemd:

```
sudo systemctl start redm-rsg
```

### Stopping the Server

```
./stop.sh
```

or:

```
sudo systemctl stop redm-rsg
```

### Accessing Console

```
./attach.sh
```

Press `CTRL+A` then `D` to detach without stopping the server.

### Updating RedM Build

```
./update.sh
```

### Server Management

```
./restart.sh           # Restart server
systemctl status redm-rsg  # Check status
journalctl -u redm-rsg -f  # View logs
```

## 📁 Installation Structure

```
/home/RedM/
├── server/                # RedM server files
│   ├── run.sh            # Server executable
│   └── alpine/           # Server binaries
├── txData/               # Server data
│   ├── server.cfg        # Server configuration
│   ├── resources/        # All resources
│   │   ├── [framework]/  # RSG core resources
│   │   ├── [standalone]/ # Standalone resources
│   │   └── [cfx-default]/# Default CFX resources
├── recipe/               # Recipe files
├── start.sh             # Start script
├── stop.sh              # Stop script
├── restart.sh           # Restart script
├── attach.sh            # Console access
└── update.sh            # Update script
```

## ⚙️ Configuration

### Default Ports

- **Server**: 30120 (TCP/UDP)
- **txAdmin**: 40120 (TCP)
- **Database**: 3306 (TCP)

All ports are configurable during installation.

### Database

- **Database Name**: `rsg_db`
- **Database User**: `rsg_user`
- **Charset**: utf8mb4

### Editing Configuration

```
nano /home/RedM/txData/server.cfg
```

After editing, restart the server:

```
./restart.sh
```

## 🔒 Security Recommendations

1. **Change default passwords** in server.cfg
2. **Add your Steam/Discord IDs** as admin
3. **Configure firewall** properly
4. **Regular backups** of database and server files
5. **Keep RedM updated** using `./update.sh`

## 🐛 Troubleshooting

### Check Logs

```
# Installation logs
cat /var/log/redm/latest.log

# Server logs
journalctl -u redm-rsg -f

# Server console
./attach.sh
```

### Common Issues

**Script fails during download:**
- Check internet connection
- Verify GitHub is accessible
- Try manual installation method

**Database connection errors:**
- Verify MariaDB is running: `systemctl status mariadb`
- Check credentials in server.cfg
- Test connection: `mysql -u rsg_user -p`

**Server won't start:**
- Check license key in server.cfg
- Verify all resources loaded: check console output
- Review logs: `journalctl -u redm-rsg -n 50`

**Port already in use:**
- Check if another server is running: `netstat -tulpn | grep 30120`
- Stop conflicting service or change port in server.cfg

## 📊 What Gets Installed

### Core Resources (from RSG Recipe)

- rsg-core (Framework core)
- rsg-multicharacter (Character selection)
- rsg-appearance (Character customization)
- rsg-inventory (Inventory system)
- rsg-banking (Banking system)
- rsg-horses (Horse system)
- rsg-weapons (Weapon system)
- rsg-shops (Shop system)
- And 20+ more resources...

### Database Tables

The installer creates 30+ tables including:
- `players` - Player data
- `characters` - Character information
- `player_horses` - Horse ownership
- `player_weapons` - Weapon storage
- `bank_accounts` - Banking data
- And many more...

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

- **RSG Framework** by [Rexshack Gaming](https://github.com/Rexshack-RedM)
- **RedM** by [Cfx.re](https://redm.net)
- Inspired by [fxserver_deployer](https://github.com/solareon/fxserver_deployer)

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/YOUR-USERNAME/rsg-server-installer/issues)

## ⭐ Star History

If this project helped you, please consider giving it a ⭐!

---

**Made with ❤️ by Suu for the RSG community**
```

Avec ce README, les utilisateurs pourront installer ton script **en une seule commande** directement depuis GitHub![2][4][1][3]
