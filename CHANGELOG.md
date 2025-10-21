# Changelog

All notable changes to this project will be documented in this file.

## [2.0.0] - 2025-10-21

### 🎉 Major Refactor & New Features

#### Added
- ✨ **Command Line Interface**: New `thanhvps` command for easy access
  - `thanhvps` - Open menu from anywhere
  - `thanhvps website add` - Add website via CLI
  - `thanhvps db create` - Create database via CLI
  - `thanhvps info` - Show system status
  - `thanhvps restart` - Restart all services
  - `thanhvps logs [service]` - View logs
  - `thanhvps help` - Full command reference
- ✨ **Redis Support**: Full Redis server installation and configuration
- ✨ **NodeJS Support**: NVM + NodeJS + PM2 installation
- ✨ **Enhanced Logging**: Color-coded logs with debug mode
- ✨ **Database Management**: Complete DB CRUD operations (create, delete, list, export)
- ✨ **Improved Menu System**: Fixed menu navigation and function calls
- ✨ **Better Error Handling**: Comprehensive error checking and recovery
- ✨ **Wait for APT Lock**: Automatic handling of apt lock conflicts
- ✨ **Config Validation**: Better YAML parsing and configuration handling
- ✨ **Quick Reference Guide**: QUICKREF.md for fast command lookup

#### Changed
- 🔧 **Utils.sh**: Complete rewrite with better utilities
  - Enhanced parse_yaml function
  - Added command_exists, service_is_active helpers
  - Improved logging functions (log_info, log_error, log_warn, log_debug)
  - Better password generation with special characters
  - Architecture detection for gum installation

- 🔧 **setup_php.sh**: Major improvements
  - Better PPA handling with error checking
  - More PHP extensions (redis, imagick, soap, intl, bcmath)
  - Optimized PHP.ini configuration
  - Proper service management
  - Support for multiple PHP versions from config

- 🔧 **setup_mysql.sh**: Enhanced database management
  - Improved MySQL installation flow
  - Better password setting mechanism
  - Added create_db, delete_db, list_db, export_db functions
  - UTF8MB4 charset by default
  - Secure installation automation

- 🔧 **setup_nginx.sh**: Complete rewrite
  - Added install_nginx function (was missing)
  - Better virtual host configuration
  - Optimized nginx.conf with modern settings
  - Fixed BASE_DIR conflicts
  - Improved read_config function

- 🔧 **menu.sh**: Fixed critical bugs
  - Fixed function sourcing and BASE_DIR logic
  - Better menu navigation and return flow
  - Added missing menu options
  - Proper error handling
  - Interactive prompts after actions

- 🔧 **install.sh**: Major improvements
  - Better error handling with set -e and trap
  - Modular component loading
  - Optional components (Redis, NodeJS, FileBrowser)
  - Better summary display
  - Interactive menu launch option

- 🔧 **config.yml**: Comprehensive configuration
  - Added Redis settings
  - Added NodeJS settings
  - Added security options
  - Added monitoring options
  - Better structure and comments

#### Fixed
- 🐛 Fixed menu not showing all options
- 🐛 Fixed BASE_DIR conflicts between modules
- 🐛 Fixed PHP-FPM service detection
- 🐛 Fixed MySQL password setting issues
- 🐛 Fixed missing functions (install_nginx, create_db, etc.)
- 🐛 Fixed config.yml parsing issues
- 🐛 Fixed menu loop and navigation
- 🐛 Fixed apt lock conflicts during installation

#### Security
- 🔐 Enhanced password generation
- 🔐 Better MySQL security (remove test DB, anonymous users)
- 🔐 Security headers in Nginx
- 🔐 Redis localhost-only binding

#### Performance
- ⚡ Optimized Nginx configuration (gzip, brotli ready)
- ⚡ PHP OPcache enabled by default
- ⚡ Redis caching for sessions
- ⚡ Better resource limits (memory, execution time)

### Documentation
- 📝 Complete README_NEW.md with detailed instructions
- 📝 Added this CHANGELOG
- 📝 Better inline comments in all scripts
- 📝 Troubleshooting guide

## [1.5.x] - Previous Version

### Features
- Basic Nginx + PHP + MariaDB installation
- Simple website management
- Basic backup functionality
- FileBrowser integration
- Auto-update mechanism

### Known Issues (Fixed in 2.0)
- Menu không hiển thị đầy đủ options
- PHP installation có lỗi với một số extensions
- BASE_DIR conflicts giữa các modules
- Thiếu database management functions
- Không hỗ trợ Redis
- Logging system cơ bản

---

## Migration Guide v1.x → v2.0

### Breaking Changes
- `config.yml` format đã thay đổi (thêm nhiều options mới)
- Một số function names đã đổi để nhất quán hơn
- Menu structure được tổ chức lại

### How to Migrate
1. Backup config.yml cũ của bạn
2. Pull code mới: `git pull origin main`
3. So sánh và merge config.yml
4. Chạy lại: `sudo bash install.sh`

### New Requirements
- Không có yêu cầu mới về OS
- Tương thích ngược với Ubuntu 20.04+

---

## Roadmap

### v2.1 (Planned)
- [ ] Fail2ban integration
- [ ] UFW firewall setup
- [ ] Auto SSL renewal check
- [ ] Website monitoring
- [ ] Email notifications
- [ ] Docker support

### v2.2 (Future)
- [ ] Cloudflare integration
- [ ] S3 backup support
- [ ] Multi-server management
- [ ] Web UI dashboard
- [ ] API endpoints

---

## Contributors

- **ThanhTV** (@duythanh18989) - Initial work & v2.0 refactor

---

[2.0.0]: https://github.com/duythanh18989/thanhvps/compare/v1.5...v2.0
