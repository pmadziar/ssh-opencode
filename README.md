# ssh-opencode

Docker setup for a root-based Alpine development container reachable over SSH.

The container is designed for Windows + Docker Desktop workflows where you want a disposable Linux tool environment with persisted user data, SSH access, OpenCode, Codex, Node.js, .NET, GitHub CLI, and access to the host Docker daemon.

## What This Project Provides

- An Alpine-based development image defined in `Dockerfile`.
- A Docker Compose service named `ssh-opencode`.
- SSH public-key login as `root` on host port `2222`.
- Persistent Docker volumes for `/root/.local`, `/root/.config`, `/root/code`, and SSH host keys.
- Read-only access to the Windows `C:\` drive at `/mnt/c`.
- Read-write access to `C:\temp` at `/root/temp`.
- Access to the host Docker daemon through `/var/run/docker.sock`.

## Included Tools

The image installs:

- OpenSSH server
- Bash and bash completion
- Node.js and npm
- OpenCode CLI
- OpenAI Codex CLI (`codex`)
- npm-check-updates (`ncu`)
- .NET 10 SDK
- Docker CLI and Docker Compose CLI plugin
- Git and GitHub CLI
- fastfetch
- oh-my-posh with the `pawel.omp.json` theme
- bubblewrap
- common CLI tools such as `curl`, `jq`, `fd`, `ripgrep`, `sqlite3`, `unzip`, and `openssl`

## Repository Files

- `Dockerfile` defines the Alpine development image and SSH configuration.
- `docker-compose.yml` builds and runs the `ssh-opencode` service.
- `docker-entrypoint.sh` generates persistent SSH host keys, links persisted config files, and starts `sshd`.
- `buid.ps1` is the Windows PowerShell build helper.
- `pawel.omp.json` is the oh-my-posh theme copied into the image.
- `DockerWslDiskMgmt.md` documents optional Docker Desktop WSL disk compaction steps.

## Requirements

Install these on the Windows host:

- Docker Desktop
- Docker Compose plugin, available as `docker compose`
- PowerShell
- An SSH public key at `C:\Users\<your-user>\.ssh\id_ed25519.pub`

The PowerShell helper assumes this repository is located at:

```text
C:\code\ssh-opencode
```

During a manual Compose build, `Dockerfile` expects `id_ed25519.pub` to already exist in the repository root. The `buid.ps1` helper copies it there for you from your Windows user profile. The copied key file is ignored by Git.

## Quick Start

From Windows PowerShell:

```powershell
cd C:\code\ssh-opencode
./buid.ps1
docker compose up -d
ssh root@localhost -p 2222
```

`docker compose up -d` can also build the image because `docker-compose.yml` includes `build: .`, but `buid.ps1` performs the full intended rebuild workflow: it pulls the latest Alpine base image, copies your SSH public key, removes older local `ssh-opencode:*` images, builds without cache, tags the result as `ssh-opencode:latest`, and prunes the build cache.

## Build Options

### Recommended PowerShell Build

Run:

```powershell
./buid.ps1
```

The script:

- Creates a timestamped image tag such as `ssh-opencode:202604302330`.
- Runs `docker pull alpine:latest`.
- Copies `C:\Users\$env:USERNAME\.ssh\id_ed25519.pub` to `C:\code\ssh-opencode\id_ed25519.pub`.
- Removes local images matching `ssh-opencode:*`.
- Builds the image with `--build-arg USERNAME=$env:USERNAME`, `--no-cache`, and `--debug`.
- Tags the timestamped image as `ssh-opencode:latest`.
- Runs `docker builder prune -f`.

Because the script removes local `ssh-opencode:*` images first, stop any running container that still uses the image if Docker reports that the image is in use:

```powershell
docker compose down
./buid.ps1
```

### Compose Build

Compose can build the image directly:

```powershell
docker compose build
docker compose up -d
```

Before using this route, make sure `id_ed25519.pub` exists in the repository root:

```powershell
Copy-Item -Path "C:\Users\$env:USERNAME\.ssh\id_ed25519.pub" -Destination ".\id_ed25519.pub" -Force
```

## Start And Connect

Start the service:

```powershell
docker compose up -d
```

Connect over SSH:

```powershell
ssh root@localhost -p 2222
```

The Compose service uses:

- service name: `ssh-opencode`
- container name: `ssh-opencode`
- hostname: `opencode`
- image name: `ssh-opencode`
- SSH port mapping: host `2222` to container `22`
- container user: `root`
- `DOCKER_HOST=unix:///var/run/docker.sock`

## SSH Authentication

The image configures `/root/.ssh/authorized_keys` from the copied `id_ed25519.pub` file. SSH password login is disabled:

- `PermitRootLogin prohibit-password`
- `PubkeyAuthentication yes`
- `PasswordAuthentication no`
- `KbdInteractiveAuthentication no`
- `ChallengeResponseAuthentication no`

If authentication fails, confirm that your Windows public key exists, copy it into the repository root or rerun `./buid.ps1`, then rebuild the image.

## Volumes And Mounts

`docker-compose.yml` mounts:

- named volume `local` to `/root/.local`
- named volume `config` to `/root/.config`
- named volume `sshhostkeys` to `/etc/ssh/host_keys`
- named volume `code` to `/root/code`
- host Docker socket `/var/run/docker.sock` to `/var/run/docker.sock`
- host path `C:\` to `/mnt/c` as read-only
- host path `C:\temp` to `/root/temp`

Docker Compose prefixes named volume names with the project name unless configured otherwise. In this repository, Docker typically creates volumes named `ssh-opencode_local`, `ssh-opencode_config`, `ssh-opencode_sshhostkeys`, and `ssh-opencode_code`.

On startup, `docker-entrypoint.sh` links persisted files and directories into root's home directory:

- `/root/.config/.bash_history` to `/root/.bash_history`
- `/root/.config/.gitconfig` to `/root/.gitconfig`
- `/root/.config/.vscode-server` to `/root/.vscode-server`
- `/root/.local/share/codex/` to `/root/.codex`

## SSH Host Keys

SSH host keys are generated on first container start and stored in the `sshhostkeys` volume at `/etc/ssh/host_keys`.

Rebuilding the image does not change the SSH server fingerprint as long as that volume is kept. Running `docker compose down -v` removes the host key volume, so the next start generates a new SSH server fingerprint.

## Shell Environment

Root uses Bash as the login shell. `/root/.bash_profile` loads `/root/.bashrc`.

The shell exports:

- `LANG=en_GB.UTF-8`
- `LANGUAGE=en_GB:en`
- `LC_ALL=en_GB.UTF-8`
- `TERM=xterm-truecolor`

Interactive shell startup also loads bash completion, runs `fastfetch`, initializes `oh-my-posh`, refreshes OpenCode models in the background, and runs `ncu -g`.

## Docker Access From The Container

The service mounts the host Docker socket and sets `DOCKER_HOST`, so commands such as these run against Docker Desktop on the host:

```bash
docker ps
docker compose version
```

This is convenient for development, but it gives the container high control over the host Docker daemon. Treat SSH access to this container as privileged access.

## Useful Commands

Open a shell without SSH:

```powershell
docker exec -it ssh-opencode bash
```

Verify common tools:

```powershell
docker exec -it ssh-opencode bash -lc "node --version && npm --version && opencode --version && codex --version && ncu --version && dotnet --version && docker --version && docker compose version && git --version && gh --version"
```

Show logs:

```powershell
docker compose logs
```

Follow logs:

```powershell
docker compose logs -f
```

Stop and remove the container while keeping volumes:

```powershell
docker compose down
```

Stop and remove the container plus named volumes:

```powershell
docker compose down -v
```

Removing volumes deletes persisted OpenCode/Codex data, Git config, shell history, VS Code server data, `/root/code`, and SSH host keys.

## Rebuild Workflow

After changing `Dockerfile`, `docker-entrypoint.sh`, `pawel.omp.json`, or your host SSH public key:

```powershell
docker compose down
./buid.ps1
docker compose up -d
```
