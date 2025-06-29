#!/bin/bash

# ──────────────── CONFIGURATION ────────────────

BACKUP_DIR="/root/proxmox-config-backup"
DATE=$(date +'%F %H:%M:%S')
GITHUB_REMOTE="git@github.com:EdR0Z/proxmox-configs.git"

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

mkdir -p "$BACKUP_DIR/etc"

cp -r /etc/*       "$BACKUP_DIR/etc/" 2>/dev/null

# ──────────────── COMMIT ET PUSH NOUVEAU CONTENU ────────────────

git add .
git commit -m "Backup Proxmox du $DATE"
git push origin master --force
