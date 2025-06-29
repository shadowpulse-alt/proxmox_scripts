# Bash script by ShadowPulse
# Discord: _._shadowpulse_._
# Don't copy and share this script without my permission.

#!/bin/bash

# Ajustez les variables suivantes en fonction de votre environnement :
# Nom du serveur de sauvegarde
BACKUP_SERVER_NAME=NOM_DU_SERVEUR
# Adresse IP du serveur de sauvegarde
BACKUP_SERVER_IP=IP_DU_SERVEUR
# Adresse MAC du serveur de sauvegarde
BACKUP_SERVER_MAC=ADDRESSE_MAC_DU_SERVEUR
# Délai pour laisser le serveur de sauvegarde démarrer
BACKUP_SERVER_DELAY=130 # en secondes
# Nom du datastore de sauvegarde sur le PVE local (pvesm status)
PVE_BACKUP_DATASTORE=NOM_DU_DATASTORE

# Ceci est uniquement pour vérifier si le script est exécuté
echo "Reveil du serveur de sauvegarde : ${BACKUP_SERVER_NAME}"
wakeonlan ${BACKUP_SERVER_MAC}
echo "Attente de ${BACKUP_SERVER_DELAY} secondes pour laisser le serveur de backup s'initialiser"
sleep ${BACKUP_SERVER_DELAY}
echo "Statut du datastore : $(/usr/sbin/pvesm status 2> /dev/null |grep ${PVE_BACKUP_DATASTORE} | awk '{print $3}')"

exit 0
