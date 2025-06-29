#!/bin/bash

# Couleurs
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

regex='^10\.0\.0\.[0-9]{1,3}$|^192\.168\.1\.[0-9]{1,3}$'

get_vm_ips() {
    local vmid="$1"
    qm guest cmd "$vmid" network-get-interfaces 2>/dev/null | \
        jq -r '.[] | .["ip-addresses"][]? | ."ip-address"' | grep -E "$regex"
}

get_lxc_ips() {
    local vmid="$1"
    pct exec "$vmid" -- ip -4 -o addr show 2>/dev/null | \
        awk '{print $4}' | cut -d/ -f1 | grep -E "$regex"
}

add_tags() {
    for vmid in $(qm list | awk 'NR>1 {print $1}'); do
        ips=$(get_vm_ips "$vmid")
        [ -z "$ips" ] && continue

        tags=$(qm config "$vmid" | grep '^tags:' | cut -d' ' -f2- | tr -d ' ')
        IFS=';' read -ra current_tags <<< "$tags"
        declare -A tag_hash
        for t in "${current_tags[@]}"; do tag_hash["$t"]=1; done

        changed=0
        for ip in $ips; do
            if [[ -z "${tag_hash["$ip"]}" ]]; then
                tag_hash["$ip"]=1
                changed=1
            fi
        done

        final_tags=""
        for tag in "${!tag_hash[@]}"; do
            [[ -z "$final_tags" ]] && final_tags="$tag" || final_tags="$final_tags;$tag"
        done

        if [[ $changed -eq 1 ]]; then
            qm set "$vmid" --tags "$final_tags"
            echo -e "${GREEN}[QEMU] $vmid : tags ajoutés -> $final_tags${RESET}"
        fi
        unset tag_hash
    done

    for vmid in $(pct list | awk 'NR>1 {print $1}'); do
        ips=$(get_lxc_ips "$vmid")
        [ -z "$ips" ] && continue

        tags=$(pct config "$vmid" | grep '^tags:' | cut -d' ' -f2- | tr -d ' ')
        IFS=';' read -ra current_tags <<< "$tags"
        declare -A tag_hash
        for t in "${current_tags[@]}"; do tag_hash["$t"]=1; done

        changed=0
        for ip in $ips; do
            if [[ -z "${tag_hash["$ip"]}" ]]; then
                tag_hash["$ip"]=1
                changed=1
            fi
        done

        final_tags=""
        for tag in "${!tag_hash[@]}"; do
            [[ -z "$final_tags" ]] && final_tags="$tag" || final_tags="$final_tags;$tag"
        done

        if [[ $changed -eq 1 ]]; then
            pct set "$vmid" --tags "$final_tags"
            echo -e "${GREEN}[LXC] $vmid : tags ajoutés -> $final_tags${RESET}"
        fi
        unset tag_hash
    done
}

update_tags() {
    for vmid in $(qm list | awk 'NR>1 {print $1}'); do
        ips=$(get_vm_ips "$vmid")
        if [[ -n "$ips" ]]; then
            final_tags=$(echo "$ips" | paste -sd';' -)
        else
            final_tags=""
        fi
        qm set "$vmid" --tags "$final_tags"
        echo -e "${CYAN}[QEMU] $vmid : tags mis à jour -> $final_tags${RESET}"
    done

    for vmid in $(pct list | awk 'NR>1 {print $1}'); do
        ips=$(get_lxc_ips "$vmid")
        if [[ -n "$ips" ]]; then
            final_tags=$(echo "$ips" | paste -sd';' -)
        else
            final_tags=""
        fi
        pct set "$vmid" --tags "$final_tags"
        echo -e "${CYAN}[LXC] $vmid : tags mis à jour -> $final_tags${RESET}"
    done
}

delete_tags() {
    for vmid in $(qm list | awk 'NR>1 {print $1}'); do
        qm set "$vmid" --tags ""
        echo -e "${YELLOW}[QEMU] $vmid : tous les tags supprimés${RESET}"
    done
    for vmid in $(pct list | awk 'NR>1 {print $1}'); do
        pct set "$vmid" --tags ""
        echo -e "${YELLOW}[LXC] $vmid : tous les tags supprimés${RESET}"
    done
}

manual_tag() {
    read -rp "ID de la VM ou du LXC : " mid
    if qm config "$mid" &>/dev/null; then
        kind="QEMU"
        tags=$(qm config "$mid" | grep '^tags:' | cut -d' ' -f2- | tr -d ' ')
        setcmd="qm set"
    elif pct config "$mid" &>/dev/null; then
        kind="LXC"
        tags=$(pct config "$mid" | grep '^tags:' | cut -d' ' -f2- | tr -d ' ')
        setcmd="pct set"
    else
        echo -e "${RED}Aucune VM ou CT avec l'ID $mid${RESET}"
        return
    fi

    read -rp "Tag à ajouter : " newtag
    IFS=';' read -ra current_tags <<< "$tags"
    declare -A tag_hash
    for t in "${current_tags[@]}"; do tag_hash["$t"]=1; done
    if [[ -z "${tag_hash["$newtag"]}" ]]; then
        tag_hash["$newtag"]=1
    else
        echo -e "${YELLOW}Le tag '$newtag' existe déjà sur $kind $mid${RESET}"
        unset tag_hash
        return
    fi

    final_tags=""
    for tag in "${!tag_hash[@]}"; do
        [[ -z "$final_tags" ]] && final_tags="$tag" || final_tags="$final_tags;$tag"
    done

    $setcmd "$mid" --tags "$final_tags"
    echo -e "${GREEN}[$kind] $mid : tag '$newtag' ajouté. Tags actuels : $final_tags${RESET}"
    unset tag_hash
}

while true; do
    echo ""
    echo -e "${CYAN}=== Menu gestion des tags IP Proxmox ===${RESET}"
    echo "1. Ajouter les tags IP (conserve les autres tags)"
    echo "2. Mettre à jour les tags IP (remplace tous les tags par les IP valides)"
    echo "3. Supprimer tous les tags"
    echo "4. Ajouter un tag manuellement à une VM/LXC"
    echo "5. Quitter"
    
    read -rp "Choix : " choix
    case "$choix" in
        1) add_tags ;;
        2) update_tags ;;
        3) delete_tags ;;
        4) manual_tag ;;
        5) exit 0 ;;        
        *) echo -e "${RED}Choix invalide.${RESET}" ;;
    esac
done
