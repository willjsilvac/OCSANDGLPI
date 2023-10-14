#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or with sudo."
  exit 1
fi

#Install files Manipulations
apt install -y xz-utils bzip2 unzip curl

#Dependences
apt install -y apache2 libapache2-mod-php php-soap php-cas php php-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,redis,bz2}

# Update the package repository and install required packages
apt update
apt install -y apache2 php php-mysql php-gd php-xml php-mbstring php-curl php-json php-ldap mysql-server mysql-client phpmyadmin wget unzip

#Liberando Firewall e Portas
sudo ufw enable 
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 3000
sudo ufw allow 3306
sudo ufw reload
sudo ufw status

#Instalacao segura do MySQL
sudo mysql_secure_installation

# Set up the MySQL database for GLPI and ocsinventory
echo "Creating GLPI database and user..."
mysql -e "CREATE DATABASE glpi;"
mysql -e "CREATE DATABASE ocsweb;"
mysql -e "CREATE USER 'glpi'@'localhost' IDENTIFIED BY 'sondosp';"
mysql -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';"
mysql -e "GRANT ALL PRIVILEGES ON ocsweb.* TO 'glpi'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

#instalar extensões PHP e Pacotes necessarios do OCS
sudo apt install -y git curl wget make cmake gcc make php-mbstring php-xml php-mysql php-zip php-pclzip php-gd php-soap php-curl php-json libapache2-mod-perl2 libapache-dbi-perl libapache-db-perl libapache2-mod-php libarchive-zip-perl mariadb-client
sudo apt install -y perl libxml-simple-perl libcompress-zlib-perl libdbi-perl libdbd-mysql-perl libnet-ip-perl libsoap-lite-perl libio-compress-perl libapache-dbi-perl libapache2-mod-perl2 libapache2-mod-perl2-dev
sudo perl -MCPAN -e 'install Apache2::SOAP'

sudo perl -MCPAN -e 'install XML::Entities'

sudo perl -MCPAN -e 'install Net::IP'

sudo perl -MCPAN -e 'install Apache::DBI'

sudo perl -MCPAN -e 'install Mojolicious'

sudo perl -MCPAN -e 'install Switch'

sudo perl -MCPAN -e 'install Plack::Handler'




# Download and install OCS Inventory Server
echo "Downloading OCS Inventory Server..."
wget -O /tmp/ocsinventory.tar.gz https://github.com/OCSInventory-NG/OCSInventory-ocsreports/releases/download/2.12.1/OCSNG_UNIX_SERVER-2.12.1.tar.gz
tar -xzvf /tmp/OCSNG_UNIX_SERVER-2.12.1.tar.gz -C /opt
mv /opt/OCSNG_UNIX_SERVER-2.12.1 /opt/ocsinventory
cd /opt/ocsinventory
wget -O /opt/ocsinventory https://github.com/willjsilvac/OCSANDGLPI/blob/main/setup.sh
./setup.sh -y

#Configuracao OCS server
sudo ln -s /etc/apache2/conf-available/ocsinventory-reports.conf /etc/apache2/conf-enabled/ocsinventory-reports.conf

sudo ln -s /etc/apache2/conf-available/z-ocsinventory-server.conf /etc/apache2/conf-enabled/z-ocsinventory-server.conf

sudo ln -s /etc/apache2/conf-available/zz-ocsinventory-restapi.conf /etc/apache2/conf-enabled/zz-ocsinventory-restapi.conf

cd /etc/apache2/conf-enabled/

sudo nano z-ocsinventory-server.conf

sudo nano zz-ocsinventory-restapi.conf


# Set permissions for GLPI
chown -R www-data:www-data /var/www/html/
chmod -R 755 /var/www/html/
sudo systemctl restart apache2

cd /usr/share/ocsinventory-reports/ocsreport

ls

sudo mv install.php install.php.bak

sudo systemctl restart apache2

# Configure Apache for GLPI
echo "Configuring Apache for GLPI..."
cat > /etc/apache2/conf-available/glpi.conf << EOF
<Directory "/var/www/glpi/glpi/public/">
    AllowOverride All
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^(.*)$ index.php [QSA,L]
    Options -Indexes
    Options -Includes -ExecCGI
    Require all granted
 
    <IfModule mod_php7.c>
        php_value max_execution_time 600
        php_value always_populate_raw_post_data -1
    </IfModule>
 
    <IfModule mod_php8.c>
        php_value max_execution_time 600
        php_value always_populate_raw_post_data -1
    </IfModule>
 
</Directory>
EOF

a2ensite glpi.conf
a2enmod rewrite

# Restart Apache
systemctl restart apache2

# Criar diretório onde o GLPi será instalado
mkdir /var/www/glpi
 
 # Install GLPI
echo "Downloading GLPI..."
wget -O- https://github.com/glpi-project/glpi/releases/download/10.0.7/glpi-10.0.7.tgz | tar -zxv -C /var/www/glpi/
 
# Movendo diretórios "files" e "config" para fora do GLPi 
mv /var/www/glpi/glpi/files /var/www/glpi/
mv /var/www/glpi/glpi/config /var/www/glpi/
rm -r /var/www/html/glpi-install
 
 # Criando link simbólico para o sistema GLPi dentro do diretório defalt do apache
ln -s /var/www/verdanadesk/glpi /var/www/html/glpi
 
# Ajustando código do GLPi para o novo local dos diretórios
sed -i 's/\/config/\/..\/config/g' /var/www/glpi/glpi/inc/based_config.php
sed -i 's/\/files/\/..\/files/g' /var/www/glpi/glpi/inc/based_config.php


# Clean up temporary files
rm /tmp/ocsinventory.tar.gz
rm /tmp/glpi.tar.gz

echo "OCS Inventory and GLPI installation complete."
echo "Please open a web browser and access your GLPI instance to complete the setup."







