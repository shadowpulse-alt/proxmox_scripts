# Bash script by ShadowPulse
# Discord: _._shadowpulse_._
# Don't copy and share this script without my permission.

#!/bin/bash

echo "=== Installation de sshpass ==="
apt install sshpass -y

# Demander les informations nécessaires à l'utilisateur
echo "=== Script pour générer ou ajouter une clé SSH ED25519 à un hôte distant ==="

read -p "Entrez l'utilisateur SSH (par défaut 'root') : " USER
USER=${USER:-root}  # Si aucune entrée, 'root' sera utilisé

read -sp "Entrez le mot de passe pour $USER : " PASSWORD
echo ""

read -p "Entrez l'adresse IP de l'hôte distant : " IP_HOST

read -p "Entrez le chemin pour stocker la clé privée (par défaut ~/.ssh/id_ed25519) : " SSH_KEY_PATH
SSH_KEY_PATH=${SSH_KEY_PATH:-~/.ssh/id_ed25519}  # Par défaut, on utilise ~/.ssh/id_ed25519

read -p "Entrez le chemin pour stocker la clé publique (par défaut ~/.ssh/id_ed25519.pub) : " SSH_KEY_PUB_PATH
SSH_KEY_PUB_PATH=${SSH_KEY_PUB_PATH:-~/.ssh/id_ed25519.pub}  # Par défaut, on utilise ~/.ssh/id_ed25519.pub

read -p "Entrez le commentaire à associer à la clé (par défaut 'Generated on tartanpion proxmox node') : " KEY_COMMENT
KEY_COMMENT=${KEY_COMMENT:-"Generated on tartanpion proxmox node"}  # Si aucune entrée, utiliser le commentaire par défaut

# Vérifier si la clé privée existe déjà
if [[ -f $SSH_KEY_PATH ]]; then
    echo "La clé privée existe déjà à $SSH_KEY_PATH."
    read -p "Voulez-vous écraser la clé existante (o/n) ? : " OVERWRITE
    if [[ $OVERWRITE =~ ^[Oo]$ ]]; then
        echo "La clé existante va être écrasée."
        rm -f "$SSH_KEY_PATH" "$SSH_KEY_PUB_PATH"  # Supprimer les anciennes clés
        ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -C "$KEY_COMMENT"
    else
        echo "Une nouvelle clé sera générée à un autre endroit."
        read -p "Entrez le nouveau chemin pour la clé privée (par défaut ~/.ssh/id_ed25519_new) : " NEW_SSH_KEY_PATH
        NEW_SSH_KEY_PATH=${NEW_SSH_KEY_PATH:-~/.ssh/id_ed25519_new}  # Par défaut, nouvelle clé avec un suffixe '_new'
        NEW_SSH_KEY_PUB_PATH="${NEW_SSH_KEY_PATH}.pub"
        ssh-keygen -t ed25519 -f "$NEW_SSH_KEY_PATH" -C "$KEY_COMMENT"
        SSH_KEY_PATH=$NEW_SSH_KEY_PATH
        SSH_KEY_PUB_PATH=$NEW_SSH_KEY_PUB_PATH
    fi
else
    echo "Aucune clé existante trouvée. Génération de la clé SSH ED25519..."
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -C "$KEY_COMMENT"
fi

# Ajouter l'hôte distant à la liste des hôtes connus
echo "Ajout de l'hôte $IP_HOST à la liste des hôtes connus..."
ssh-keyscan -H $IP_HOST >> ~/.ssh/known_hosts

# Configurer les variables d'exportation
export USER
export PASSWORD
export IP_HOST
export SSH_KEY_PUB_PATH

# Créer le répertoire .ssh et appliquer les bonnes permissions sur la machine distante
echo "Création du répertoire ~/.ssh et configuration des permissions sur l'hôte distant $IP_HOST..."
sshpass -p "$PASSWORD" ssh "$USER@$IP_HOST" "mkdir -p ~/.ssh && chmod 700 ~/.ssh"

# Ajouter la clé publique à authorized_keys sur la machine distante
echo "Ajout de la clé publique à ~/.ssh/authorized_keys sur $IP_HOST..."
cat "$SSH_KEY_PUB_PATH" | sshpass -p "$PASSWORD" ssh "$USER@$IP_HOST" "tee -a ~/.ssh/authorized_keys > /dev/null && chmod 600 ~/.ssh/authorized_keys"

# Finaliser
echo "La clé publique a été ajoutée avec succès à l'hôte distant $IP_HOST."
echo "Vous pouvez maintenant vous connecter sans mot de passe via SSH."

# Tester la connexion SSH sans mot de passe
echo "Test de la connexion SSH sans mot de passe..."
ssh "$USER@$IP_HOST" "echo Connexion réussie !"
