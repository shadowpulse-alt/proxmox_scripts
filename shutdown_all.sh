#!/bin/bash
# Script pour un arrêt propre de toutes les VMs (qemu) et des conteneurs (LXC) sur Proxmox
# Exclusions : VMs 107 et 119 (aucune commande ne leur sera envoyée)
# La VM 103 sera arrêtée en dernier

# Liste des VM à exclure totalement
EXCLUDED_VMS=("107" "112" "119")
# VM à traiter en dernier
LAST_VM="103"

is_excluded() {
    # Vérifie si le VMID passé en paramètre est dans la liste des exclusions
    for id in "${EXCLUDED_VMS[@]}"; do
        if [ "$1" -eq "$id" ]; then
            return 0
        fi
    done
    return 1
}

echo "Arrêt des VMs Qemu (exclusion des VMs ${EXCLUDED_VMS[*]} et VM $LAST_VM traitée en dernier)..."
for vmid in $(qm list | awk 'NR>1 {print $1}'); do
    # Exclure les VMs 107 et 119
    if is_excluded "$vmid"; then
        echo "-> VM $vmid est exclue du process."
        continue
    fi
    # La VM 103 sera traitée en dernier
    if [ "$vmid" -eq "$LAST_VM" ]; then
        echo "-> VM $vmid sera arrêtée en dernier."
        continue
    fi

    echo "-> Envoi de la commande d'arrêt pour la VM $vmid"
    qm shutdown "$vmid"
done

# Arrêt propre des conteneurs LXC
echo "Arrêt des conteneurs LXC..."
for ct in $(pct list | awk 'NR>1 {print $1}'); do
    echo "-> Envoi de la commande d'arrêt pour le conteneur $ct"
    pct shutdown "$ct"
done

# Pause pour permettre un arrêt propre
echo "Pause de 30 secondes pour l'arrêt propre..."
sleep 30

# Vérification et forçage de l'arrêt pour les VMs restantes (en excluant 107, 119 et 103)
echo "Vérification des VMs encore actives..."
for vmid in $(qm list | awk 'NR>1 {print $1}'); do
    if is_excluded "$vmid" || [ "$vmid" -eq "$LAST_VM" ]; then
        continue
    fi
    state=$(qm status "$vmid" | awk '{print $2}')
    if [ "$state" != "stopped" ]; then
        echo "-> Forçage de l'arrêt de la VM $vmid"
        qm stop "$vmid"
    fi
done

# Vérification et forçage de l'arrêt pour les conteneurs toujours actifs
echo "Vérification des conteneurs encore actifs..."
for ct in $(pct list | awk 'NR>1 {print $1}'); do
    state=$(pct status "$ct" | awk '{print $2}')
    if [ "$state" != "stopped" ]; then
        echo "-> Forçage de l'arrêt du conteneur $ct"
        pct stop "$ct"
    fi
done

# Arrêt de la VM 103 en dernier
echo "Arrêt de la VM $LAST_VM en dernier..."
qm shutdown "$LAST_VM"
echo "Pause de 30 secondes pour l'arrêt de la VM $LAST_VM..."
sleep 30
state=$(qm status "$LAST_VM" | awk '{print $2}')
if [ "$state" != "stopped" ]; then
    echo "-> Forçage de l'arrêt de la VM $LAST_VM"
    qm stop "$LAST_VM"
fi

echo "Arrêt complet de toutes les VMs et conteneurs (VMs ${EXCLUDED_VMS[*]} exclues, VM $LAST_VM arrêtée en dernier)."
