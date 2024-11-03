#!/bin/bash

# Variables
DB_USER="zabbix"
DB_PASSWORD="Azzrod1993="
DB_NAME="zabbix"
ZBX_SERVER_CONF="/etc/zabbix/zabbix_server.conf"
ZBX_AGENT_CONF="/etc/zabbix/zabbix_agent2.conf"
ZBX_LOG="/var/log/zabbix/zabbix_server.log"
APACHE_CONF="/etc/apache2/sites-available/zabbix.conf"
IP_ADDRESS="192.168.1.217"

# Vérifier si l'utilisateur est root
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root."
  exit 1
fi

# Fonction de vérification de service
check_service() {
    local service="$1"
    if systemctl is-active --quiet "$service"; then
        echo "$service est actif."
    else
        echo "$service a échoué. Voici les logs :"
        journalctl -u "$service" --no-pager -n 50
    fi
}

# Mise à jour et installation des paquets
echo "Mise à jour du système..."
apt update && apt upgrade -y && apt dist-upgrade -y

echo "Installation de MariaDB, Apache, PHP et autres dépendances..."
apt install -y mariadb-server mariadb-client apache2 php php-mbstring php-gd php-xml php-bcmath php-ldap php-mysql php-zip php-curl libldap-common

# Ajouter le repository Zabbix et installer les paquets Zabbix
echo "Ajout du repository et installation de Zabbix..."
#wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4+debian12_all.deb
#dpkg -i zabbix-release_6.0-4+debian12_all.deb
#apt update
#apt install -y zabbix-server-mysql zabbix-agent zabbix-frontend-php
sudo apt install -y build-essential libmariadb-dev libmariadb-dev-compat libxml2-dev libcurl4-openssl-dev libldap2-dev sudo apt install libxml2-dev libcurl4-openssl-dev libldap2-dev
wget https://cdn.zabbix.com/zabbix/sources/stable/6.0/zabbix-6.0.0.tar.gz
tar -xzf zabbix-6.0.0.tar.gz
cd zabbix-6.0.0
./configure --enable-server --enable-agent --with-mariadb --with-net-snmp --with-libcurl --with-ldap
make install
# Vérification de l'installation des paquets Zabbix
if ! dpkg -l | grep -q zabbix-server-mysql; then
  echo "L'installation de Zabbix Server a échoué."
  exit 1
fi

# Configuration de MariaDB
echo "Configuration de MariaDB..."
systemctl start mariadb
mysql -uroot -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
mysql -uroot -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
mysql -uroot -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -uroot -e "FLUSH PRIVILEGES;"

# Import des schémas Zabbix dans la base de données
echo "Importation des schémas Zabbix..."
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME}

# Configuration de Zabbix Server
echo "Configuration de Zabbix Server..."
if [ -f "$ZBX_SERVER_CONF" ]; then
    sed -i "s/# DBPassword=/DBPassword=${DB_PASSWORD}/" $ZBX_SERVER_CONF
    sed -i "s/DBHost=localhost/DBHost=localhost/" $ZBX_SERVER_CONF
    sed -i "s/DBName=zabbix/DBName=${DB_NAME}/" $ZBX_SERVER_CONF
    sed -i "s/DBUser=zabbix/DBUser=${DB_USER}/" $ZBX_SERVER_CONF
else
    echo "$ZBX_SERVER_CONF n'existe pas. Vérifiez l'installation de Zabbix Server."
    exit 1
fi

# Configuration de Zabbix Agent
if [ -f "$ZBX_AGENT_CONF" ]; then
    echo "Activation des logs étendus pour Zabbix Agent..."
    sed -i "s/# DebugLevel=3/DebugLevel=4/" $ZBX_AGENT_CONF
    touch /var/log/zabbix/zabbix_agent2.log
    chown zabbix:zabbix /var/log/zabbix/zabbix_agent2.log
else
    echo "$ZBX_AGENT_CONF n'existe pas. Vérifiez l'installation de Zabbix Agent."
    exit 1
fi

# Configuration PHP pour Zabbix
echo "Configuration de PHP pour Zabbix..."
PHP_INI_PATH=$(php --ini | grep "Loaded Configuration File" | cut -d:
root@PI4:~/zabbix# ^C
root@PI4:~/zabbix# mysql
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 46
Server version: 10.11.6-MariaDB-0+deb12u1-log Debian 12

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
| zabbix             |
+--------------------+
5 rows in set (0,003 sec)

MariaDB [(none)]> DROPT DATABASE zabbix;
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MariaDB server version for the right syntax to use near 'DROPT DATABASE zabbix' at line 1
MariaDB [(none)]> DROP DATABASE zabbix;
Query OK, 0 rows affected (0,017 sec)

MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
4 rows in set (0,001 sec)

MariaDB [(none)]> DROP DATABASE mysql;
Query OK, 31 rows affected (0,584 sec)

MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| performance_schema |
| sys                |
+--------------------+
3 rows in set (0,001 sec)

MariaDB [(none)]> exit;
Bye
root@PI4:~/zabbix# ^C
root@PI4:~/zabbix# ^C
root@PI4:~/zabbix# ls
install.sh  install_zabbix_v4.sh  zabbix-6.0.0  zabbix-6.0.0.tar.gz  zabbix-6.0.0.tar.gz.1  zabbix-6.0.0.tar.gz.2
root@PI4:~/zabbix# ^C
root@PI4:~/zabbix# rm zabbix-6.0.0  zabbix-6.0.0.tar.gz  zabbix-6.0.0.tar.gz.1  zabbix-6.0.0.tar.gz.2
rm: impossible de supprimer 'zabbix-6.0.0': est un dossier
root@PI4:~/zabbix# rm -rf zabbix-6.0.0  zabbix-6.0.0.tar.gz  zabbix-6.0.0.tar.gz.1  zabbix-6.0.0.tar.gz.2
root@PI4:~/zabbix# lms
-bash: lms : commande introuvable
root@PI4:~/zabbix# ls
install.sh  install_zabbix_v4.sh
root@PI4:~/zabbix# cat install_zabbix_v4.sh 
#!/bin/bash

# Variables
DB_USER="zabbix"
DB_PASSWORD="Azzrod1993="
DB_NAME="zabbix"
ZBX_SERVER_CONF="/etc/zabbix/zabbix_server.conf"
ZBX_AGENT_CONF="/etc/zabbix/zabbix_agent2.conf"
ZBX_LOG="/var/log/zabbix/zabbix_server.log"
APACHE_CONF="/etc/apache2/sites-available/zabbix.conf"
IP_ADDRESS="192.168.1.217"

# Vérifier si l'utilisateur est root
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté en tant que root."
  exit 1
fi

# Fonction de vérification de service
check_service() {
    local service="$1"
    if systemctl is-active --quiet "$service"; then
        echo "$service est actif."
    else
        echo "$service a échoué. Voici les logs :"
        journalctl -u "$service" --no-pager -n 50
    fi
}

# Mise à jour et installation des paquets
echo "Mise à jour du système..."
apt update && apt upgrade -y && apt dist-upgrade -y

echo "Installation de MariaDB, Apache, PHP et autres dépendances..."
apt install -y mariadb-server mariadb-client apache2 php php-mbstring php-gd php-xml php-bcmath php-ldap php-mysql php-zip php-curl libldap-common

# Ajouter le repository Zabbix et installer les paquets Zabbix
echo "Ajout du repository et installation de Zabbix..."
#wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4+debian12_all.deb
#dpkg -i zabbix-release_6.0-4+debian12_all.deb
#apt update
#apt install -y zabbix-server-mysql zabbix-agent zabbix-frontend-php
sudo apt install -y build-essential libmariadb-dev libmariadb-dev-compat libxml2-dev libcurl4-openssl-dev libldap2-dev sudo apt install libxml2-dev libcurl4-openssl-dev libldap2-dev
wget https://cdn.zabbix.com/zabbix/sources/stable/6.0/zabbix-6.0.0.tar.gz
tar -xzf zabbix-6.0.0.tar.gz
cd zabbix-6.0.0
./configure --enable-server --enable-agent --with-mariadb --with-net-snmp --with-libcurl --with-ldap
make install
# Vérification de l'installation des paquets Zabbix
if ! dpkg -l | grep -q zabbix-server-mysql; then
  echo "L'installation de Zabbix Server a échoué."
  exit 1
fi

# Configuration de MariaDB
echo "Configuration de MariaDB..."
systemctl start mariadb
mysql -uroot -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
mysql -uroot -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
mysql -uroot -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -uroot -e "FLUSH PRIVILEGES;"

# Import des schémas Zabbix dans la base de données
echo "Importation des schémas Zabbix..."
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u${DB_USER} -p${DB_PASSWORD} ${DB_NAME}

# Configuration de Zabbix Server
echo "Configuration de Zabbix Server..."
if [ -f "$ZBX_SERVER_CONF" ]; then
    sed -i "s/# DBPassword=/DBPassword=${DB_PASSWORD}/" $ZBX_SERVER_CONF
    sed -i "s/DBHost=localhost/DBHost=localhost/" $ZBX_SERVER_CONF
    sed -i "s/DBName=zabbix/DBName=${DB_NAME}/" $ZBX_SERVER_CONF
    sed -i "s/DBUser=zabbix/DBUser=${DB_USER}/" $ZBX_SERVER_CONF
else
    echo "$ZBX_SERVER_CONF n'existe pas. Vérifiez l'installation de Zabbix Server."
    exit 1
fi

# Configuration de Zabbix Agent
if [ -f "$ZBX_AGENT_CONF" ]; then
    echo "Activation des logs étendus pour Zabbix Agent..."
    sed -i "s/# DebugLevel=3/DebugLevel=4/" $ZBX_AGENT_CONF
    touch /var/log/zabbix/zabbix_agent2.log
    chown zabbix:zabbix /var/log/zabbix/zabbix_agent2.log
else
    echo "$ZBX_AGENT_CONF n'existe pas. Vérifiez l'installation de Zabbix Agent."
    exit 1
fi

# Configuration PHP pour Zabbix
echo "Configuration de PHP pour Zabbix..."
PHP_INI_PATH=$(php --ini | grep "Loaded Configuration File" | cut -d: