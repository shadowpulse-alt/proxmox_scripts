#!/bin/bash

# ──────────────── CONFIGURATION ────────────────

BACKUP_DIR="/root/proxmox-config-backup"
DATE=$(date +'%F %H:%M:%S')
GITHUB_REMOTE="git@github.com:TON_USER/TON_REPO.git"

# ──────────────── RÉINITIALISATION DU DÉPÔT ────────────────

rm -rf "$BACKUP_DIR"
mkdir "$BACKUP_DIR"
cd "$BACKUP_DIR" || exit 1

git init
git config user.name "Proxmox Reset"
git config user.email "reset@local"
git remote add origin "$GITHUB_REMOTE"

git commit --allow-empty -m "Réinitialisation vide"
git push origin master --force

# ──────────────── SAUVEGARDE DES CONFIGS ────────────────

mkdir -p "$BACKUP_DIR/qemu" "$BACKUP_DIR/lxc" "$BACKUP_DIR/network" "$BACKUP_DIR/firewall"

cp -r /etc/pve/qemu-server/*       "$BACKUP_DIR/qemu/" 2>/dev/null
cp -r /etc/pve/lxc/*               "$BACKUP_DIR/lxc/" 2>/dev/null
cp /etc/network/interfaces         "$BACKUP_DIR/network/interfaces" 2>/dev/null
cp -r /etc/pve/firewall/*          "$BACKUP_DIR/firewall/" 2>/dev/null
cp /etc/pve/storage.cfg            "$BACKUP_DIR/storage.cfg" 2>/dev/null
cp /etc/pve/datacenter.cfg         "$BACKUP_DIR/datacenter.cfg" 2>/dev/null
cp /etc/pve/cluster.cfg            "$BACKUP_DIR/cluster.cfg" 2>/dev/null

# ──────────────── COMMIT ET PUSH NOUVEAU CONTENU ────────────────

git add .
git commit -m "Backup Proxmox du $DATE"
git push origin master --force