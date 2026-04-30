# Compact Docker Desktop WSL Disk On Windows 11

These steps reclaim space from Docker Desktop's WSL virtual disk (`ext4.vhdx`) after unused Docker data has been removed.

## Default VHDX Location

Docker Desktop usually stores its WSL disk here:

```text
C:\Users\<your-user>\AppData\Local\Docker\wsl\data\ext4.vhdx
```

If you changed Docker Desktop's disk image location in Settings, use that path instead.

## Before You Start

- Close any shells using Docker or WSL.
- Quit Docker Desktop completely from the system tray.
- Run PowerShell as Administrator for the compaction step.
- Decide whether you want to keep Docker volumes before running prune commands. For this project, volumes can contain `/root/code`, shell history, Git config, Codex/OpenCode data, VS Code server files, and SSH host keys.

## Step 1: Remove Unused Docker Data

Check current Docker disk usage:

```powershell
docker system df
```

Remove unused data, including volumes:

```powershell
docker system prune -a --volumes
```

This deletes unused images, stopped containers, unused networks, and unused volumes. Skip `--volumes` if you want to keep named volumes such as `ssh-opencode_local`, `ssh-opencode_config`, `ssh-opencode_sshhostkeys`, and `ssh-opencode_code`.

To prune without deleting volumes:

```powershell
docker system prune -a
```

To inspect this project's volumes before pruning:

```powershell
docker volume ls --filter name=ssh-opencode
```

## Step 2: Shut Down WSL

Run:

```powershell
wsl --shutdown
```

This releases the VHDX so Windows can compact it.

## Step 3: Compact The Docker WSL Disk With DiskPart

Open PowerShell or Command Prompt as Administrator and run:

```text
diskpart
select vdisk file="%LOCALAPPDATA%\Docker\wsl\data\ext4.vhdx"
attach vdisk readonly
compact vdisk
detach vdisk
exit
```

If the VHDX is in a different location, replace the file path in the `select vdisk` command.

## Optional: Use Optimize-VHD Instead

If the Hyper-V PowerShell module is available, you can use:

```powershell
Optimize-VHD -Path "$env:LOCALAPPDATA\Docker\wsl\data\ext4.vhdx" -Mode Full
```

This also requires Docker Desktop to be closed and WSL to be shut down.

## One-Shot PowerShell Example

Run this in an elevated PowerShell window:

```powershell
$vhd = "$env:LOCALAPPDATA\Docker\wsl\data\ext4.vhdx"
wsl --shutdown
$script = @"
select vdisk file=\"$vhd\"
attach vdisk readonly
compact vdisk
detach vdisk
exit
"@
$script | diskpart
```

## Notes

- Compaction only reclaims space that was already freed inside the Linux filesystem.
- If `compact vdisk` reports the file is in use, make sure Docker Desktop is fully exited and run `wsl --shutdown` again.
- You can reopen Docker Desktop normally after the compaction finishes.
- Docker Desktop may recreate or grow the VHDX again as images, containers, and volumes are used.
