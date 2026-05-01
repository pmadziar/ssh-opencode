#!/bin/sh
set -eu

mkdir -p /run/sshd /etc/ssh/host_keys

if [ ! -s /etc/ssh/host_keys/ssh_host_ed25519_key ]; then
    ssh-keygen -t ed25519 -f /etc/ssh/host_keys/ssh_host_ed25519_key -N ''
fi

if [ ! -s /etc/ssh/host_keys/ssh_host_rsa_key ]; then
    ssh-keygen -t rsa -b 4096 -f /etc/ssh/host_keys/ssh_host_rsa_key -N ''
fi

chmod 600 /etc/ssh/host_keys/ssh_host_*_key
chmod 644 /etc/ssh/host_keys/ssh_host_*_key.pub

mkdir -p /root/.config/.vscode-server
mkdir -p /root/.config/.codex


ln -sfn /root/.config/.bash_history /root/.bash_history
ln -sfn /root/.config/.gitconfig /root/.gitconfig
ln -sfn /root/.config/.vscode-server /root/.vscode-server
ln -sfn /root/.config/.codex/ /root/.codex

exec /usr/sbin/sshd -D -e
