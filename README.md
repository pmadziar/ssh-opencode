# ssh-opencode

Docker image and Docker Compose setup for a root-based Alpine development container reachable over SSH.

The intended workflow is:

1. Build the image with `buid.ps1` from Windows PowerShell.
2. Run the already-built image with `docker compose`.
3. SSH into the running container as `root` using your copied public key.

## Included Tools

The image includes:

- OpenSSH server
- Bash
- Node.js and npm
- OpenCode CLI
- npm-check-updates (`ncu`)
- .NET 10 SDK
- Git and GitHub CLI
- fastfetch
- oh-my-posh with the `pawel.omp.json` theme
- common CLI tools such as `curl`, `jq`, `fd`, `ripgrep`, and `sqlite3`

## Files

- `buid.ps1` copies your Windows SSH public key, rebuilds the Docker image, tags it as `ssh-opencode:latest`, and prunes build cache.
- `Dockerfile` defines the Alpine-based development image.
- `docker-compose.yml` runs the prebuilt image with SSH port mapping, persistent Docker volumes, and Windows bind mounts.
- `docker-entrypoint.sh` generates persistent SSH host keys on first container start and then launches `sshd`.
- `pawel.omp.json` is the oh-my-posh theme copied into the image.
- `DockerWslDiskMgmt.md` documents optional Docker Desktop WSL disk compaction steps.

## Requirements

Install these on the Windows host:

- Docker Desktop
- Docker Compose plugin (`docker compose`)
- PowerShell
- An SSH key at `C:\Users\<your-user>\.ssh\id_ed25519.pub`

This project is expected to be available at:

```text
C:\code\ssh-opencode
```

The build script copies your public key into this directory as `id_ed25519.pub` before running `docker build`. The `Dockerfile` then copies that file into `/root/.ssh/authorized_keys`.

## Build The Image

Run the build from Windows PowerShell in the project directory:

```powershell
./buid.ps1
```

`buid.ps1` performs these steps:

- Creates a timestamped image tag such as `ssh-opencode:202604261430`.
- Copies `C:\Users\$env:USERNAME\.ssh\id_ed25519.pub` to `C:\code\ssh-opencode\id_ed25519.pub`.
- Removes existing local images matching `ssh-opencode:*`.
- Builds the image with `--build-arg USERNAME=$env:USERNAME`, `--no-cache`, and `--debug`.
- Tags the timestamped image as `ssh-opencode:latest`.
- Runs `docker builder prune -f`.

The Compose file uses `image: ssh-opencode`, which resolves to `ssh-opencode:latest`. Re-run `buid.ps1` whenever you change the image contents or want to refresh the copied SSH public key.

## Start With Docker Compose

Start the container in the background:

```powershell
docker compose up -d
```

The Compose service uses:

- service name: `ssh-opencode`
- container name: `ssh-opencode`
- hostname: `opencode`
- image: `ssh-opencode:latest`
- SSH port mapping: host `2222` -> container `22`
- container user: `root`

If the image does not exist yet, run `./buid.ps1` first. This project does not rely on Compose to build the image.

## SSH Login

The container is configured for SSH public key login as `root`.

```powershell
ssh root@localhost -p 2222
```

Password login is disabled in `sshd_config`:

- `PermitRootLogin prohibit-password`
- `PubkeyAuthentication yes`
- `PasswordAuthentication no`
- `KbdInteractiveAuthentication no`

If SSH authentication fails, confirm that `C:\Users\<your-user>\.ssh\id_ed25519.pub` exists and rebuild the image with `./buid.ps1`.

## Stop The Container

Stop and remove the container while keeping volumes:

```powershell
docker compose down
```

Stop and remove the container plus named volumes:

```powershell
docker compose down -v
```

Removing volumes deletes persisted OpenCode/config data, `/root/code`, and SSH host keys.

## Rebuild Workflow

After changing `Dockerfile`, `docker-entrypoint.sh`, `pawel.omp.json`, or your host SSH public key, rebuild and recreate the container:

```powershell
docker compose down
./buid.ps1
docker compose up -d
```

If Docker cannot remove an old `ssh-opencode` image because a container is still using it, stop the container with `docker compose down` and run `./buid.ps1` again.

## Volumes And Mounts

The Compose file mounts:

- named volume `local` -> `/root/.local`
- named volume `config` -> `/root/.config`
- named volume `sshhostkeys` -> `/etc/ssh/host_keys`
- named volume `code` -> `/root/code`
- host path `C:\` -> `/mnt/c` read-only
- host path `C:\temp` -> `/root/temp`

Docker Compose prefixes named volume names with the project name unless configured otherwise. For this directory, Docker usually creates names such as `ssh-opencode_local`, `ssh-opencode_config`, `ssh-opencode_sshhostkeys`, and `ssh-opencode_code`.

## SSH Host Keys

SSH host keys are generated on first container start by `docker-entrypoint.sh` and stored in the `sshhostkeys` volume at `/etc/ssh/host_keys`.

Rebuilding the image does not change the server fingerprint as long as that volume is kept. Running `docker compose down -v` removes the host key volume, so the next start generates a new SSH server fingerprint.

## Run Commands Inside The Container

Open a shell inside the running container:

```powershell
docker exec -it ssh-opencode bash
```

Verify key tools:

```powershell
docker exec -it ssh-opencode bash -lc "node --version && npm --version && opencode --version && ncu --version && dotnet --version && git --version && gh --version"
```

## Logs

Show logs:

```powershell
docker compose logs
```

Follow logs live:

```powershell
docker compose logs -f
```

## Default Shell Environment

On login, the image configures root to use Bash and loads `/root/.bashrc` through `/root/.bash_profile`.

The shell sets:

- `LANG=en_GB.UTF-8`
- `LANGUAGE=en_GB:en`
- `LC_ALL=en_GB.UTF-8`
- `TERM=xterm-truecolor`
- `ASPNETCORE_Kestrel__Certificates__Default__Path=/root/.aspnet/https/aspnetapp.pfx`
- `ASPNETCORE_Kestrel__Certificates__Default__Password=pawel`

The login shell also runs:

- `fastfetch`
- `oh-my-posh`
- `opencode models --refresh`
- `ncu -g`

## ASP.NET Development Certificate

The image creates a self-signed certificate during build and stores it at:

```text
/root/.aspnet/https/aspnetapp.pfx
```

The password is `pawel`, and the related ASP.NET Core environment variables are preconfigured in the image and shell startup.

## Common Workflow

```powershell
cd C:\code\ssh-opencode
./buid.ps1
docker compose up -d
ssh root@localhost -p 2222
```

When finished:

```powershell
docker compose down
```

## Notes

- The script name is currently `buid.ps1`.
- The image runs `sshd` as the main container process.
- `/etc/motd` is emptied during image build.
- `docker-entrypoint.sh` links `/root/.bash_history` to `/root/.config/.bash_history`.
