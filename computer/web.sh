#!/bin/bash

# Ask for necessary information at the beginning
read -p "请输入您的 Red Hat 用户名: " username
read -s -p "请输入您的 Red Hat 密码: " password
read -s -p "请输入 WordPress 数据库用户的密码: " db_password

# Run subscription-manager register
sudo subscription-manager register --username="$username" --password="$password"

# Check if the registration was successful
if [ $? -eq 0 ]; then
    echo "注册成功。"

    # Display system information
    sudo subscription-manager identity

    # Update the system immediately after registration
    sudo yum update -y

    # Continue with LAMP stack and WordPress installation

    # Install and start Apache (httpd)
    sudo yum install httpd -y
    sudo systemctl start httpd
    sudo systemctl enable httpd
    sudo systemctl status httpd

    # Open port 80 in the firewall
    sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT

    # Install LAMP stack and other required packages
    sudo yum install php-mysqlnd php-fpm php-json php-gd mariadb-server unzip nano -y

    # Manually install EPEL repository
    wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    sudo yum install epel-release-latest-8.noarch.rpm -y
    sudo yum repolist

    # Install PHP
    sudo yum install php -y

    # Start and enable MariaDB
    sudo systemctl start mariadb
    sudo systemctl enable mariadb

    # Create database user and database for WordPress using the provided password
    sudo mysql -u root <<EOF
    CREATE USER 'wordpress'@'localhost' IDENTIFIED BY '$db_password';
    CREATE DATABASE wordpress;
    GRANT ALL ON wordpress.* TO 'wordpress'@'localhost';
    FLUSH PRIVILEGES;
EOF

    # Download and install WordPress
    wget  https://cn.wordpress.org/latest-zh_CN.zip
    unzip latest-zh_CN.zip
    sudo mv wordpress/ /var/www/html/linuxone
    sudo chown -R apache:apache /var/www/html/linuxone

    # Restart httpd to enable PHP and MariaDB support
    sudo systemctl restart httpd

    # Output the website URL at the end
    echo "网址: http://$(hostname -I | awk '{print $1}')/linuxone"

else
    echo "注册失败。请检查错误信息。"
fi
