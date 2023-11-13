#!/bin/bash

# Define variables for your site and MySQL
site_name="mylocal.site"
mysql_root_password="your_mysql_root_password"
db_name="mylocaldb"
db_user="dbuser"
db_password="dbpassword"

# Function to create a virtual host
create_vhost() {
    # Create a directory for the site
    mkdir -p /var/www/${site_name}
    
    # Create a virtual host configuration
    cat <<EOL > /etc/apache2/sites-available/${site_name}.conf
<VirtualHost *:80>
    ServerAdmin webmaster@${site_name}
    ServerName ${site_name}
    DocumentRoot /var/www/${site_name}
    ErrorLog \${APACHE_LOG_DIR}/${site_name}_error.log
    CustomLog \${APACHE_LOG_DIR}/${site_name}_access.log combined
</VirtualHost>
EOL

    # Enable the virtual host
    a2ensite ${site_name}
    
    # Restart Apache
    systemctl restart apache2
}

# Install MySQL and create a database
install_mysql() {
    # Install MySQL Server
    apt-get update
    apt-get install -y mysql-server
    
    # Secure MySQL installation (set root password and remove anonymous user)
    mysql_secure_installation <<EOF
${mysql_root_password}
${mysql_root_password}
n
n
n
n
EOF
    
    # Create a database and user
    mysql -u root -p"${mysql_root_password}" -e "CREATE DATABASE ${db_name};"
    mysql -u root -p"${mysql_root_password}" -e "CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_password}';"
    mysql -u root -p"${mysql_root_password}" -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'localhost';"
    mysql -u root -p"${mysql_root_password}" -e "FLUSH PRIVILEGES;"
}

# Install Node.js, PHP, and unzip
install_nodejs_php_unzip() {
    # Install Node.js and npm
    curl -sL https://deb.nodesource.com/setup_14.x | bash -
    apt-get install -y nodejs
    
    # Install PHP and required extensions
    apt-get install -y php php-mysql php-curl php-gd php-mbstring php-xml
    
    # Install unzip
    apt-get install -y unzip
}

# Download and extract WordPress
download_extract_wordpress() {
    # Change to the site directory
    cd /var/www/${site_name}
    
    # Download and unzip WordPress
    wget https://wordpress.org/latest.tar.gz
    tar -xzvf latest.tar.gz
    mv wordpress/* .
    rm -rf wordpress latest.tar.gz
    
    # Set permissions
    chown -R www-data:www-data /var/www/${site_name}
}

# Main execution
create_vhost
install_mysql
install_nodejs_php_unzip
download_extract_wordpress

echo "Setup complete! You can access your site at http://${site_name}"
