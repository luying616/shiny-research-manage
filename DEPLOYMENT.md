# ==================== 部署指南 ====================
# 科研项目管理系统部署文档
# ===============================================

## 目录
1. [系统要求](#系统要求)
2. [快速部署](#快速部署)
3. [详细配置](#详细配置)
4. [生产环境部署](#生产环境部署)
5. [安全配置](#安全配置)
6. [维护和监控](#维护和监控)

## 系统要求

### 硬件要求
- CPU: 2核或以上
- 内存: 4GB或以上
- 硬盘: 20GB可用空间

### 软件要求
- 操作系统: Ubuntu 20.04+ / CentOS 7+ / macOS 10.14+
- R: 4.0.0或更高版本
- PostgreSQL: 12.0或更高版本
- （可选）Shiny Server: 最新稳定版

## 快速部署

### 1. 克隆代码

```bash
git clone https://github.com/luying616/shiny-research-manage.git
cd shiny-research-manage
```

### 2. 安装依赖

#### 安装R和PostgreSQL

**Ubuntu/Debian:**
```bash
# 更新包列表
sudo apt-get update

# 安装R
sudo apt-get install -y r-base r-base-dev

# 安装PostgreSQL
sudo apt-get install -y postgresql postgresql-contrib

# 安装其他依赖
sudo apt-get install -y libpq-dev libssl-dev libxml2-dev libcurl4-openssl-dev
```

**CentOS/RHEL:**
```bash
# 安装EPEL源
sudo yum install -y epel-release

# 安装R
sudo yum install -y R

# 安装PostgreSQL
sudo yum install -y postgresql-server postgresql-contrib

# 初始化数据库
sudo postgresql-setup initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### 安装R包

```bash
R -e "install.packages(c('shiny', 'shinydashboard', 'shinyWidgets', 'DT', 'pool', 'RPostgres', 'dplyr', 'logger', 'dotenv', 'jsonlite', 'lubridate', 'openxlsx', 'digest'), repos='https://cloud.r-project.org')"
```

### 3. 配置数据库

```bash
# 切换到postgres用户
sudo -u postgres psql

# 创建数据库和用户
CREATE DATABASE research_db;
CREATE USER research_user WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE research_db TO research_user;
\q

# 初始化数据库表
sudo -u postgres psql -d research_db -f scripts/init_database.sql
```

### 4. 配置环境变量

```bash
# 创建环境变量目录
sudo mkdir -p /data/share/luying/shinyApp

# 创建.env文件
sudo nano /data/share/luying/shinyApp/.env
```

添加以下内容：
```env
DB_NAME=research_db
DB_HOST=localhost
DB_PORT=5432
DB_USER=research_user
DB_PASSWORD=your_secure_password
```

或者，直接在 `global.R` 中修改环境变量文件路径。

### 5. 运行应用

```bash
# 测试运行
R -e "shiny::runApp('app.R', port = 3838, host = '127.0.0.1')"
```

访问 http://localhost:3838

## 详细配置

### 数据库配置优化

编辑 PostgreSQL 配置文件（通常在 `/etc/postgresql/*/main/postgresql.conf`）：

```conf
# 连接配置
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 4MB
maintenance_work_mem = 64MB

# 日志配置
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'mod'
log_min_duration_statement = 1000
```

重启PostgreSQL：
```bash
sudo systemctl restart postgresql
```

### 应用配置

编辑 `global.R` 根据需要调整：

```r
# 调试模式（生产环境设为FALSE）
DEBUG_MODE <- FALSE

# 应用版本
APP_VERSION <- "1.0.0"

# 数据库连接池配置
minSize = 2      # 最小连接数
maxSize = 10     # 最大连接数
idleTimeout = 300000  # 空闲超时（毫秒）

# 日志级别
log_threshold(INFO)  # 可选: DEBUG, INFO, WARN, ERROR
```

## 生产环境部署

### 使用Shiny Server

#### 1. 安装Shiny Server

**Ubuntu/Debian:**
```bash
# 下载并安装
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
sudo gdebi shiny-server-1.5.20.1002-amd64.deb
```

**CentOS/RHEL:**
```bash
wget https://download3.rstudio.org/centos7/x86_64/shiny-server-1.5.20.1002-x86_64.rpm
sudo yum install --nogpgcheck shiny-server-1.5.20.1002-x86_64.rpm
```

#### 2. 配置Shiny Server

编辑 `/etc/shiny-server/shiny-server.conf`：

```conf
# 运行用户
run_as shiny;

# 日志目录
access_log /var/log/shiny-server/access.log;

# 服务器配置
server {
  listen 3838;

  # 应用位置
  location /research-manage {
    site_dir /srv/shiny-server/research-manage;
    log_dir /var/log/shiny-server/research-manage;
    directory_index off;
    
    # 应用超时设置
    app_init_timeout 60;
    app_idle_timeout 600;
  }
}
```

#### 3. 部署应用

```bash
# 复制应用到Shiny Server目录
sudo mkdir -p /srv/shiny-server/research-manage
sudo cp -r * /srv/shiny-server/research-manage/
sudo chown -R shiny:shiny /srv/shiny-server/research-manage

# 创建日志目录
sudo mkdir -p /var/log/shiny-server/research-manage
sudo chown -R shiny:shiny /var/log/shiny-server/research-manage

# 重启Shiny Server
sudo systemctl restart shiny-server
```

访问: http://your-server:3838/research-manage/

### 使用Nginx反向代理

安装Nginx：
```bash
sudo apt-get install nginx
```

配置 `/etc/nginx/sites-available/research-manage`：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # SSL配置（推荐）
    # listen 443 ssl;
    # ssl_certificate /path/to/cert.pem;
    # ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://127.0.0.1:3838/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket支持
        proxy_read_timeout 3600;
        proxy_send_timeout 3600;
    }
}
```

启用配置：
```bash
sudo ln -s /etc/nginx/sites-available/research-manage /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 安全配置

### 1. 修改默认密码

连接数据库并修改默认管理员密码：

```sql
-- 生成新密码的SHA-256哈希
-- 使用R: digest::digest("your_new_password", algo="sha256", serialize=FALSE)

UPDATE auth.users 
SET password_hash = 'new_hash_value'
WHERE username = 'admin';
```

### 2. 配置防火墙

```bash
# UFW (Ubuntu)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 3838/tcp  # 如果直接访问Shiny Server
sudo ufw enable

# FirewallD (CentOS)
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --permanent --add-port=3838/tcp
sudo firewall-cmd --reload
```

### 3. PostgreSQL安全配置

编辑 `/etc/postgresql/*/main/pg_hba.conf`：

```conf
# 只允许本地连接
local   all             all                                     md5
host    all             all             127.0.0.1/32            md5
host    all             all             ::1/128                 md5
```

重启PostgreSQL：
```bash
sudo systemctl restart postgresql
```

### 4. 定期备份

创建备份脚本 `/usr/local/bin/backup-research-db.sh`：

```bash
#!/bin/bash
BACKUP_DIR="/backup/research-db"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

pg_dump -U research_user research_db > $BACKUP_DIR/research_db_$DATE.sql
gzip $BACKUP_DIR/research_db_$DATE.sql

# 保留最近30天的备份
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR/research_db_$DATE.sql.gz"
```

添加到crontab：
```bash
# 每天凌晨2点备份
0 2 * * * /usr/local/bin/backup-research-db.sh >> /var/log/research-db-backup.log 2>&1
```

## 维护和监控

### 1. 日志监控

```bash
# 查看Shiny Server日志
tail -f /var/log/shiny-server/research-manage/shiny-shiny-*.log

# 查看PostgreSQL日志
sudo tail -f /var/log/postgresql/postgresql-*.log
```

### 2. 性能监控

创建监控脚本：

```bash
#!/bin/bash
# 检查应用是否运行
curl -I http://localhost:3838/research-manage/ 2>&1 | grep "200 OK"

# 检查数据库连接
psql -U research_user -d research_db -c "SELECT 1" > /dev/null 2>&1

# 检查磁盘空间
df -h | grep -E "^/dev/"

# 检查内存使用
free -m
```

### 3. 自动重启（如果崩溃）

使用systemd服务（自定义运行）：

创建 `/etc/systemd/system/research-manage.service`：

```ini
[Unit]
Description=Research Management Shiny App
After=network.target postgresql.service

[Service]
Type=simple
User=shiny
WorkingDirectory=/srv/shiny-server/research-manage
ExecStart=/usr/bin/R -e "shiny::runApp(port=3838, host='127.0.0.1')"
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

启用服务：
```bash
sudo systemctl daemon-reload
sudo systemctl enable research-manage
sudo systemctl start research-manage
```

## 故障排查

### 应用无法启动

1. 检查R包是否完整安装
2. 检查环境变量配置
3. 查看日志文件
4. 检查数据库连接

### 性能问题

1. 增加数据库连接池大小
2. 优化PostgreSQL配置
3. 增加服务器资源
4. 使用缓存策略

### 数据库连接超时

1. 检查网络连接
2. 增加连接超时时间
3. 检查防火墙规则

## 更新和升级

```bash
# 备份当前版本
sudo cp -r /srv/shiny-server/research-manage /srv/shiny-server/research-manage.backup

# 拉取新版本
cd /path/to/source
git pull origin main

# 备份数据库
pg_dump -U research_user research_db > backup_before_upgrade.sql

# 执行数据库迁移（如果有）
psql -U research_user -d research_db -f scripts/migrate_vX_to_vY.sql

# 部署新版本
sudo cp -r * /srv/shiny-server/research-manage/

# 重启服务
sudo systemctl restart shiny-server
```

## 支持

如有部署问题，请联系技术支持团队。

---
更新时间：2026-01-15
