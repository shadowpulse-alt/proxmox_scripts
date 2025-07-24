##Script by edroz
##Don't share without my autorization

#!/usr/bin/env bash

# Lire la valeur actuelle du swap
read -r OLD_SWAP </proc/sys/vm/swappiness
echo -e "L'ancien seuil du swap est de : $OLD_SWAP"

# Modifier la valeur du swap à 1
sysctl vm.swappiness=1 > /dev/null
echo vm.swappiness=1 | tee /etc/sysctl.d/99-swappiness.conf > /dev/null

# Lire la nouvelle valeur du swap
read -r NEW_SWAP </proc/sys/vm/swappiness
echo -e "Le nouveau seuil du swap est de : $NEW_SWAP"

# Vérifier si la valeur dans le fichier est égale à 1
if grep -q "vm.swappiness=1" /etc/sysctl.d/99-swappiness.conf; then
    echo -e "Fichier de configuration modifié avec succès."
else
    echo -e "Erreur dans la modification de le fichier configuration."
fi

swapoff -a
sleep 5
swapon -a

echo -e "Fin du script."