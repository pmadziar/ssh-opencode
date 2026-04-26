# ssh-opencode

Docker image and Docker Compose setup for a root-based Alpine development container with:

- OpenSSH server
- Bash
- Node.js and npm
- OpenCode CLI
- npm-check-updates (`ncu`)
- .NET 10 SDK
- Git and GitHub CLI
- fastfetch
- oh-my-posh with the `pawel.omp.json` theme

## Files

- `Dockerfile` builds the image named `ssh-opencode`
- `docker-compose.yml` runs the container with persistent volumes and bind mounts
- `docker-entrypoint.sh` generates persistent SSH host keys on first container start and then launches `sshd`
- `pawel.omp.json` is the oh-my-posh theme copied into the image

## Requirements

Make sure the following are installed on the host machine:

- Docker
- Docker Compose plugin (`docker compose`)

You should also build and run from this directory:

```bash
/mnt/c/code/opencode
```

## Build The Image

Build the image manually with:

```bash
docker build -t ssh-opencode /mnt/c/code/opencode
```

If you are already in the project directory, you can also run:

```bash
docker build -t ssh-opencode .
```

## Start With Docker Compose

The Compose file starts one container:

- service name: `ssh-opencode`
- container name: `ssh-opencode`
- hostname: `opencode`
- SSH port mapping: host `2222` -> container `22`

Start the container in the background:

```bash
docker compose up -d
```

Or with an explicit file path:

```bash
docker compose -f /mnt/c/code/opencode/docker-compose.yml up -d
```

## Stop The Container

```bash
docker compose down
```

## Rebuild After Dockerfile Changes

If you change the `Dockerfile`, rebuild the image and recreate the container:

```bash
docker build -t ssh-opencode .
docker compose up -d --force-recreate
```

If you want Compose to rebuild first, run:

```bash
docker compose up -d --build
```

## SSH Login

The container is configured to allow SSH login for the `root` user.

- username: `root`
- password: `pawel`
- SSH port on host: `2222`

Connect with:

```bash
ssh root@localhost -p 2222
```

## SSH Host Keys

SSH host keys are no longer baked into the image during `docker build`.

- They are generated on first container start by `docker-entrypoint.sh`
- They are stored in the named volume `opencodesshhostkeys`
- Rebuilding the image does not change the server fingerprint as long as that volume is kept

This means you should only need to accept the host key once unless you remove volumes.

If you remove volumes with `docker compose down -v`, the SSH host keys are deleted and your next start will generate a new fingerprint.

## Run Commands Inside The Container

Open a shell inside the running container:

```bash
docker exec -it ssh-opencode bash
```

## Mounted Volumes And Paths

The Compose file mounts the following locations:

- named volume `opencodelocal` -> `/root/.local`
- named volume `opencodeconfig` -> `/root/.config/opencode`
- named volume `opencodesshhostkeys` -> `/etc/ssh/host_keys`
- host path `c:\code` -> `/root/code`
- host path `c:\` -> `/mnt/c` (read-only)

This means:

- OpenCode local storage under `/root/.local` is persistent
- OpenCode config under `/root/.config/opencode` is persistent
- SSH host keys under `/etc/ssh/host_keys` are persistent
- your host code directory is available in `/root/code`
- the full Windows `C:` drive is available in `/mnt/c` as read-only

## Default Shell Environment

On login, the image configures root to use Bash and loads `/root/.bashrc` through `/root/.bash_profile`.

The shell also sets:

- `LANG=en_GB.UTF-8`
- `LANGUAGE=en_GB:en`
- `LC_ALL=en_GB.UTF-8`
- `TERM=xterm-truecolor`

The login shell also runs:

- `fastfetch`
- `oh-my-posh`
- `ncu -g`

## Installed Tools

The image includes:

- `bash`
- `curl`
- `git`
- `gh`
- `node`
- `npm`
- `opencode`
- `ncu`
- `.NET 10 SDK`
- `python3`
- `pip`
- `jq`
- `fd`
- `ripgrep`
- `make`
- `gcc`
- `g++`
- `sqlite3`
- `fastfetch`
- `oh-my-posh`

## Verify The Container Setup

After the container starts, you can verify the main tools:

```bash
docker exec -it ssh-opencode bash -lc 'node --version && npm --version && opencode --version && ncu --version && dotnet --version && git --version && gh --version'
```

## Logs

Show container logs:

```bash
docker compose logs
```

Follow logs live:

```bash
docker compose logs -f
```

## Remove Container And Volumes

Stop and remove the container:

```bash
docker compose down
```

Stop and remove the container and named volumes:

```bash
docker compose down -v
```

This removes:

- `opencodelocal`
- `opencodeconfig`
- `opencodesshhostkeys`

## Common Workflow

1. Build the image:

```bash
docker build -t ssh-opencode .
```

2. Start the container:

```bash
docker compose up -d
```

3. SSH into it:

```bash
ssh root@localhost -p 2222
```

4. Or open a shell directly:

```bash
docker exec -it ssh-opencode bash
```

5. Stop it when finished:

```bash
docker compose down
```

## Notes

- The image runs `sshd` as the main container process.
- `docker-entrypoint.sh` generates missing SSH host keys before starting `sshd`.
- The container runs as `root`.
- `/etc/motd` is emptied during image build.
- ASP.NET certificate environment variables are preconfigured in the image.
