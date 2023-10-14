#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

# Update the package repository and install required packages
apt update
apt install -y apache2 php php-mysql php-gd php-xml php-mbstring php-curl php-json php-ldap mysql-server mysql-client phpmyadmin wget unzip

# Set up the MySQL database for GLPI
echo "Creating GLPI database and user..."
mysql -e "CREATE DATABASE glpi;"
mysql -e "CREATE USER 'glpi'@'localhost' IDENTIFIED BY 'sondosp';"
mysql -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Download and install OCS Inventory Server
echo "Downloading OCS Inventory Server..."
wget -O /tmp/ocsinventory.tar.gz https://github.com/OCSInventory-NG/OCSInventory-Server/archive/2.8.tar.gz
tar -xzvf /tmp/ocsinventory.tar.gz -C /opt
mv /opt/OCSInventory-Server-2.8 /opt/ocsinventory
cd /opt/ocsinventory
./setup.sh

# Install GLPI
echo "Downloading GLPI..."
wget -O /tmp/glpi.tar.gz https://github.com/glpi-project/glpi/releases/download/9.6.4/glpi-9.6.4.tgz
tar -xzvf /tmp/glpi.tar.gz -C /var/www/html/
mv /var/www/html/glpi /var/www/html/glpi-install
mv /var/www/html/glpi-install/* /var/www/html/
rm -r /var/www/html/glpi-install

# Set permissions for GLPI
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/

# Configure Apache for GLPI
echo "Configuring Apache for GLPI..."
cat <<EOL > /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html
    ServerName 10.11.2.10
    <Directory /var/www/html>
        Options FollowSymlinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOL

a2ensite glpi.conf
a2enmod rewrite

# Restart Apache
systemctl restart apache2

# Clean up temporary files
rm /tmp/ocsinventory.tar.gz
rm /tmp/glpi.tar.gz

echo "OCS Inventory and GLPI installation complete."
echo "Please open a web browser and access your GLPI instance to complete the setup."