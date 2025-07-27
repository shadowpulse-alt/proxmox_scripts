#!/bin/bash

# Ajoutez une reference à ce script dans /etc/vzdump.conf si ce n'est pas dejà fait
#if ! grep -q "script: /root/pbs_up-down.sh" /etc/vzdump.conf; then
#  echo 'script: /root/pbs_up-down.sh' >> /etc/vzdump.conf
#fi
#
# Ce script suppose que l'authentification par cle SSH est configuree entre root@pve et root@backup_server
#
# Ajustez les variables suivantes en fonction de votre environnement :
# Nom du serveur de sauvegarde
BACKUP_SERVER_NAME=pbs
# Adresse IP du serveur de sauvegarde
BACKUP_SERVER_IP=10.0.0.83
# Adresse MAC du serveur de sauvegarde
BACKUP_SERVER_MAC=84:2B:2B:60:B7:8D
# Delai pour laisser le serveur de sauvegarde demarrer
BACKUP_SERVER_DELAY=130
# Nom du datastore de sauvegarde sur le PVE local (pvesm status)
PVE_BACKUP_DATASTORE=pbs

# Mode des messages Discord ("main" ou "dev")
DISCORD_MESSAGES="main"

# Définition de l'URL du webhook Discord en fonction du mode choisi
if [ "$DISCORD_MESSAGES" == "main" ]; then
    DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1346191992538796083/C7fsJf2-XTT5B7vgRfV3U8E55eOO9uw8pibvXhD4bDLTDN-kJWt72qzn9quZSX3MOcQm"
elif [ "$DISCORD_MESSAGES" == "dev" ]; then
    DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1348472410235736196/TutocDn9Peq4oVUB_CcldG14JtuKLDufTQEMPBAc6MTMvCRqqtq6IoggyNg8H8Ysmufl"
else
    echo "Valeur de DISCORD_MESSAGES non reconnue. Utilisation de l'URL par défaut."
fi

# Ceci est uniquement pour verifier si le script est execute
touch /tmp/backup_server_up-down

check_pbs_port() {
  # Verifie la disponibilite du port 8007 sur le serveur de backup
  nc -zv -w 10 "${BACKUP_SERVER_IP}" 8007 > /dev/null 2>&1
  return $?
}

if [ "$1" == "job-init" ]; then
  echo "== DEBUT JOB-INIT =="

  # Recuperation de la date et l'heure de debut
  START_TIME=$(date "+%d/%m/%Y %H:%M:%S")
  echo "La sauvegarde debute à : $START_TIME"

  # Test si le port 8007 du serveur PBS est dejà accessible
  if check_pbs_port; then
    echo "Le serveur de backup (${BACKUP_SERVER_NAME}) est operationnel."
  else
    echo "Le serveur de backup (${BACKUP_SERVER_NAME}) n'est pas disponible."
    echo "Envoi de Wake-on-LAN..."
    wakeonlan "${BACKUP_SERVER_MAC}"
    echo "Attente de ${BACKUP_SERVER_DELAY} secondes pour laisser le serveur demarrer..."
    sleep "${BACKUP_SERVER_DELAY}"
  fi

  # (Optionnel) Verification du statut du datastore
  echo "Statut du datastore : $(/usr/sbin/pvesm status 2> /dev/null | grep "${PVE_BACKUP_DATASTORE}" | awk '{print $3}')"

  # Notification Discord : Debut de la sauvegarde (incluant l'heure si souhaite)
  echo "Notification sur Discord : debut de la sauvegarde..."
  curl -H "Content-Type: application/json" \
     -X POST \
     -d '{
           "embeds": [{
             "title": "Démarrage de la backup",
             "description": ":rocket: La backup du VPS LifeParisRP va démarrer !",
             "color": 15258703,
             "fields": [
               {"name": "Serveur", "value": "Proxmox Node01", "inline": true},
               {"name": "Heure", "value": "'"$START_TIME"'", "inline": true}
             ],
             "footer": {"text": "Backup System"}
           }]
         }' \
     "${DISCORD_WEBHOOK_URL}"

  echo "== FIN JOB-INIT =="
fi

if [ "$1" == "job-end" ]; then
  echo "== DEBUT JOB-END =="

  # Recuperation de la date et l'heure de fin
  END_TIME=$(date "+%d/%m/%Y %H:%M:%S")
  echo "La sauvegarde s'est terminee à : $END_TIME"

  # Notification Discord : Fin de la sauvegarde (incluant l'heure si souhaite)
  echo "Notification sur Discord : fin de la backup..."
  curl -H "Content-Type: application/json" \
     -X POST \
     -d '{
           "embeds": [{
             "title": "Fin de la sauvegarde",
             "description": ":white_check_mark: La backup du VPS LifeParisRP est terminée !",
             "color": 3066993,
             "fields": [
               {"name": "Serveur", "value": "Proxmox Node01", "inline": true},
               {"name": "Heure", "value": "'"$END_TIME"'", "inline": true}
             ],
             "footer": {"text": "Backup System"}
           }]
         }' \
     "${DISCORD_WEBHOOK_URL}"

  echo "Extinction du serveur de backup : ${BACKUP_SERVER_NAME}"
  ssh root@"${BACKUP_SERVER_IP}" 'init 0'

  echo "== FIN JOB-END =="
fi

exit 0
