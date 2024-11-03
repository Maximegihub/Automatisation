#!/bin/bash

# Variables
DB_NAME=""
DB_USER=""
DB_PASSWORD=""
SERVER_NAME=""
FIVEM_DIR=~/fivem-server
LOG_FILE="/var/log/fivem_startup.log"

# Mettre à jour le système
echo "Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

# Installer les dépendances
echo "Installation des dépendances..."
sudo apt install -y wget curl screen git mariadb-server ufw xz-utils

# Démarrer le service MariaDB
echo "Démarrage du service MariaDB..."
sudo systemctl start mariadb

# Vérifier si MariaDB fonctionne
if ! systemctl is-active --quiet mariadb; then
    echo "Erreur : MariaDB ne fonctionne pas. Veuillez vérifier l'installation."
    exit 1
fi

# Fonction pour créer la base de données et l'utilisateur
create_db_user() {
    echo "Création de la base de données et de l'utilisateur..."

    # Connexion à MariaDB
    sudo mariadb -u root -p <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME;
DROP USER IF EXISTS '$DB_USER'@'localhost';
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

    if [ $? -ne 0 ]; then
        echo "Erreur lors de la création de la base de données ou de l'utilisateur."
        exit 1
    fi
}

# Exécuter la fonction pour créer la base de données et l'utilisateur
create_db_user

# Téléchargement de FXServer
echo "Téléchargement de FXServer..."
mkdir -p "$FIVEM_DIR"
cd "$FIVEM_DIR"

# URL de téléchargement de FXServer
FXSERVER_URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/7290-a654bcc2adfa27c4e020fc915a1a6343c3b4f921/fx.tar.xz"

# Télécharger le fichier
curl -L -o "fx.tar.xz" "$FXSERVER_URL"

# Vérifiez si le téléchargement a réussi
if [ ! -f "fx.tar.xz" ]; then
    echo "Erreur lors du téléchargement de FXServer. Le fichier est manquant."
    exit 1
fi

# Vérification du contenu du fichier téléchargé
echo "Vérification du contenu du fichier téléchargé..."
file "fx.tar.xz"

# Extraction du fichier
echo "Extraction de FXServer..."
tar -xJvf "fx.tar.xz"

# Vérifiez si l'extraction a réussi
if [ $? -ne 0 ]; then
    echo "Erreur lors de l'extraction de FXServer. Vérifiez le fichier téléchargé."
    exit 1
fi

# Rendre le fichier FXServer exécutable
chmod +x FXServer

# Création du fichier de configuration server.cfg
echo "Création du fichier de configuration server.cfg..."
cat <<EOL > "$FIVEM_DIR/server.cfg"
# Nom du serveur
sv_hostname "$SERVER_NAME"

# Configuration de la base de données
set mysql_connection_string "mysql://$DB_USER:$DB_PASSWORD@localhost/$DB_NAME"

# Démarrage des ressources par défaut
start mapmanager
start chat
start spawnmanager
start fivem
start hardcap
EOL

# Créer le script run.sh
echo "Création du script run.sh..."
cat <<EOL > "$FIVEM_DIR/run.sh"
#!/bin/bash
cd "$FIVEM_DIR"
exec ./FXServer +exec server.cfg
EOL

# Rendre le script run.sh exécutable
chmod +x "$FIVEM_DIR/run.sh"

# Vérification des permissions pour le fichier de log
if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE"
    sudo chmod 666 "$LOG_FILE"
fi

# Création du fichier systemd pour FiveM
echo "Création du fichier systemd pour le serveur FiveM..."
sudo bash -c "cat <<EOF > /etc/systemd/system/fivem.service
[Unit]
Description=FiveM Server
After=network.target mariadb.service

[Service]
User=$USER
WorkingDirectory=$FIVEM_DIR
ExecStart=$FIVEM_DIR/run.sh
Restart=on-failure
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE

[Install]
WantedBy=multi-user.target
EOF"

# Recharger systemd pour prendre en compte le nouveau service
echo "Rechargement de systemd et activation du service fivem..."
sudo systemctl daemon-reload
sudo systemctl enable fivem.service

echo "Installation terminée. Utilisez 'sudo systemctl start fivem' pour démarrer le serveur FiveM."
