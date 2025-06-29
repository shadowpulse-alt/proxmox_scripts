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

update_tags() {
    local vmtype="$1"
    local vmid="$2"
    local new_ips="$3"
    local set_cmd="$4"

    if [[ -n "$new_ips" ]]; then
        final_tags=$(echo "$new_ips" | paste -sd';' -)
    else
        final_tags=""
    fi

    $set_cmd "$vmid" --tags "$final_tags"
    echo "[$vmtype] $vmid : tags mis à jour -> $final_tags"
}

# Pour toutes les VM QEMU/KVM
for vmid in $(qm list | awk 'NR>1 {print $1}'); do
    ips=$(get_vm_ips "$vmid")
    update_tags "QEMU" "$vmid" "$ips" "qm set"
done

# Pour tous les conteneurs LXC
for vmid in $(pct list | awk 'NR>1 {print $1}'); do
    ips=$(get_lxc_ips "$vmid")
    update_tags "LXC" "$vmid" "$ips" "pct set"
done
