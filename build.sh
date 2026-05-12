#!/usr/bin/env bash
set -eo pipefail

USER="${USER:-$(whoami)}"

dat=$(date +%Y%m%d%H%M)
tag="ssh-opencode:$dat"

echo "Pulling base image"
docker pull ubuntu:latest

echo "Removing old images with tag ssh-opencode:*"
docker images --format '{{.Repository}}:{{.Tag}}' | grep '^ssh-opencode:' | xargs -r docker rmi

echo "Building image with tag $tag (USER=$USER)"
docker build -t "$tag" --build-arg "USERNAME=$USER" . --no-cache

echo "Tagging image as ssh-opencode:latest"
docker tag "$tag" ssh-opencode:latest

docker builder prune -f
