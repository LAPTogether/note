#!/bin/bash

# Move website files to the parent directory
sudo mv /var/www/html/linuxone/* /var/www/html/

# Modify wp-config.php for IP or domain pointing to IP
read -p "Enter the IP or domain name pointing to this server: " site_url

# Temporary file to store modified wp-config.php content
temp_wp_config=$(mktemp)

# Modify wp-config.php with the correct site and home URLs
sudo sed -e "/^define('DB_COLLATE', '');/a define('WP_HOME', 'http://$site_url');\ndefine('WP_SITEURL', 'http://$site_url');\n" /var/www/html/wp-config.php > "$temp_wp_config"
sudo mv "$temp_wp_config" /var/www/html/wp-config.php

# Restart httpd to apply changes
sudo systemctl restart httpd

# Open port 443 for HTTPS
sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
sudo systemctl restart httpd

# Apply SSL certificate
sudo yum install certbot -y  # 安装 certbot 工具

# Create separate config file for the domain
sudo echo "
<VirtualHost *:80>
    ServerName $site_url
    DocumentRoot /var/www/html
    # Other configurations
</VirtualHost>
" | sudo tee /etc/httpd/conf.d/${site_url}.conf >/dev/null 2>&1  # 创建单独的配置文件

# Request SSL certificate using certbot
sudo certbot --apache -d $site_url  # 使用 certbot 申请证书

# Check if certbot command succeeded
if [ $? -eq 0 ]; then
    # Restart Apache after obtaining SSL certificate
    sudo systemctl restart httpd
    echo "HTTPS setup successful for $site_url."
else
    echo "HTTPS setup failed for $site_url. Please check the error message."
fi
