#!/bin/bash
#
# Ajustez les variables suivantes en fonction de votre environnement :
# Nom du serveur de sauvegarde
BACKUP_SERVER_NAME=pbs
# Adresse IP du serveur de sauvegarde
BACKUP_SERVER_IP=10.0.0.83
# Adresse MAC du serveur de sauvegarde
BACKUP_SERVER_MAC=84:2B:2B:60:B7:8D
# Délai pour laisser le serveur de sauvegarde démarrer
BACKUP_SERVER_DELAY=130
# Nom du datastore de sauvegarde sur le PVE local (pvesm status)
PVE_BACKUP_DATASTORE=pbs

# Ceci est uniquement pour vérifier si le script est exécuté
echo "Reveil du serveur de sauvegarde : ${BACKUP_SERVER_NAME}"
wakeonlan ${BACKUP_SERVER_MAC}
echo "Attente de ${BACKUP_SERVER_DELAY} secondes pour laisser le serveur de backup s'initialiser"
sleep ${BACKUP_SERVER_DELAY}
echo "Statut du datastore : $(/usr/sbin/pvesm status 2> /dev/null |grep ${PVE_BACKUP_DATASTORE} | awk '{print $3}')"

exit 0
