$dat = [datetime]::Now.ToString("yyyyMMddHHmm")
$tag = "ssh-opencode:$dat"
Write-Host 'Pulling base image'
docker pull alpine:latest
Write-Host "Copying ssh public key..."
Copy-Item -Path "C:\Users\$env:USERNAME\.ssh\id_ed25519.pub" -Destination "C:\code\ssh-opencode\id_ed25519.pub" -Force
Write-Host "Removing old images with tag ssh-opencode:*"
docker image ls --format '{{.Repository}}:{{.Tag}}'|?{$_ -match '^ssh-opencode:'}|%{ docker image rm $_}
Write-Host "Building image with tag $tag"
docker build -t $tag --build-arg USERNAME=$env:USERNAME .  --no-cache --debug
Write-Host "Tagging image as ssh-opencode:latest"
docker tag $tag ssh-opencode:latest
docker builder prune -f
