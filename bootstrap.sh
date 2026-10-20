#!/usr/bin/env bash
set -euo pipefail

# Installa Git e GitHub CLI
sudo apt-get update
sudo apt-get install -y git curl gh

# Autenticazione GitHub
if ! gh auth status >/dev/null 2>&1; then
    gh auth login --hostname github.com --git-protocol ssh --web
fi

# Crea la directory SSH
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Genera la chiave SSH se non esiste
if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
    ssh-keygen -t ed25519 \
        -f "$HOME/.ssh/id_ed25519" \
        -N ""
fi

# Imposta i permessi
chmod 600 "$HOME/.ssh/id_ed25519"

# Ricava la chiave pubblica
ssh-keygen -y -f "$HOME/.ssh/id_ed25519" \
    > "$HOME/.ssh/id_ed25519.pub"

chmod 644 "$HOME/.ssh/id_ed25519.pub"

# Controlla se la chiave è già su GitHub
PUBLIC_KEY=$(awk '{print $1 " " $2}' "$HOME/.ssh/id_ed25519.pub")

if ! gh ssh-key list --json key \
    --jq '.[].key' | grep -Fxq "$PUBLIC_KEY"; then

    gh ssh-key add "$HOME/.ssh/id_ed25519.pub" \
        --title "Ubuntu $(hostname)" \
        --type authentication
fi

# Configura GitHub CLI
gh config set git_protocol ssh --host github.com
gh auth setup-git

# Verifica la connessione SSH
ssh -o StrictHostKeyChecking=accept-new \
    -T git@github.com || test "$?" -eq 1

echo "Configurazione GitHub completata."
