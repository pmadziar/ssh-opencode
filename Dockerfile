FROM alpine:latest

ARG USERNAME

ENV USERNAME=${USERNAME}

RUN apk add --no-cache \
    bash \
    ca-certificates \
    curl \
    docker-cli \
    docker-cli-compose \
    dotnet10-sdk \
    fd \
    fastfetch \
    git \
    github-cli \
    jq \
    musl-locales \
    nodejs \
    npm \
    openssl \
    openssh \
    ripgrep \
    sqlite \
    shadow \
    unzip \
    bubblewrap \
    bash-completion \
    bat \
    fzf \
 && update-ca-certificates

RUN set -eux; \
    arch="$(apk --print-arch)"; \
    case "$arch" in \
      x86_64) opencode_arch='x64' ;; \
      aarch64) opencode_arch='arm64' ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    npm install -g npm-check-updates @openai/codex opencode-ai "opencode-linux-${opencode_arch}-musl" context-mode; \
    npm_root="$(npm root -g)"; \
    install -m 755 "${npm_root}/opencode-linux-${opencode_arch}-musl/bin/opencode" "${npm_root}/opencode-ai/bin/.opencode"

RUN set -eux; \
    curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin

COPY pawel.omp.json /root/.poshthemes/pawel.omp.json
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN install -d -m 700 /root/.ssh
COPY authorized_keys /root/.ssh/authorized_keys

RUN set -eux; \
     dotnet tool install --global dotnet-xscgen; \
     dotnet tool install amazon.lambda.tools --global

RUN set -eux; \
    chsh -s /bin/bash root; \
    mkdir -p /run/sshd /root/.ssh /etc/ssh/host_keys; \
    chmod 700 /root/.ssh; \
    touch /root/.ssh/authorized_keys; \
    chmod 600 /root/.ssh/authorized_keys; \
    : > /etc/motd; \
    printf '%s\n' \
      'HostKey /etc/ssh/host_keys/ssh_host_rsa_key' \
      'HostKey /etc/ssh/host_keys/ssh_host_ed25519_key' \
      'PermitRootLogin prohibit-password' \
      'PubkeyAuthentication yes' \
      'AuthorizedKeysFile .ssh/authorized_keys' \
      'PasswordAuthentication no' \
      'KbdInteractiveAuthentication no' \
      'ChallengeResponseAuthentication no' \
      'UseDNS no' \
      'Subsystem sftp /usr/lib/ssh/sftp-server' \
      > /etc/ssh/sshd_config; \
    printf '%s\n' \
      'if [ -f ~/.bashrc ]; then' \
      '  . ~/.bashrc' \
      'fi' \
      > /root/.bash_profile; \
    printf '%s\n' \
        'export LANG=en_GB.UTF-8' \
        'export LANGUAGE=en_GB:en' \
        'export LC_ALL=en_GB.UTF-8' \
        'export TERM=xterm-256color' \
        'export COLORTERM=truecolor' \
        'if [ -f /usr/share/bash-completion/bash_completion ]; then' \
        '  . /usr/share/bash-completion/bash_completion' \
        'fi' \
        'eval "$(fzf --bash)"' \
        'fastfetch' \
        'eval "$(oh-my-posh init bash --config /root/.poshthemes/pawel.omp.json)"' \
        'opencode models --refresh > /dev/null 2>&1' \
        'ncu -g' \
      >> /root/.bashrc

RUN chmod 755 /usr/local/bin/docker-entrypoint.sh

EXPOSE 22

CMD ["/usr/local/bin/docker-entrypoint.sh"]
