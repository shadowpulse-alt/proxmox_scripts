#!/bin/bash

# Regex stricte : 10.0.0.x ou 192.168.1.x uniquement
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
            echo "[QEMU] $vmid : tags ajoutés -> $final_tags"
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
            echo "[LXC] $vmid : tags ajoutés -> $final_tags"
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
        echo "[QEMU] $vmid : tags mis à jour -> $final_tags"
    done

    for vmid in $(pct list | awk 'NR>1 {print $1}'); do
        ips=$(get_lxc_ips "$vmid")
        if [[ -n "$ips" ]]; then
            final_tags=$(echo "$ips" | paste -sd';' -)
        else
            final_tags=""
        fi
        pct set "$vmid" --tags "$final_tags"
        echo "[LXC] $vmid : tags mis à jour -> $final_tags"
    done
}

delete_tags() {
    for vmid in $(qm list | awk 'NR>1 {print $1}'); do
        qm set "$vmid" --tags ""
        echo "[QEMU] $vmid : tous les tags supprimés"
    done
    for vmid in $(pct list | awk 'NR>1 {print $1}'); do
        pct set "$vmid" --tags ""
        echo "[LXC] $vmid : tous les tags supprimés"
    done
}

while true; do
    echo ""
    echo "=== Menu gestion des tags IP Proxmox ==="
    echo "1. Ajouter les tags IP (conserve les autres tags)"
    echo "2. Mettre à jour les tags IP (remplace tous les tags par les IP valides)"
    echo "3. Supprimer tous les tags"
    echo "4. Quitter"
    read -rp "Choix : " choix
    case "$choix" in
        1) add_tags ;;
        2) update_tags ;;
        3) delete_tags ;;
        4) exit 0 ;;
        *) echo "Choix invalide." ;;
    esac
done
