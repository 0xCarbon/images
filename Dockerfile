FROM debian:bookworm-slim
# Setup a user with default UID=1000 (debain, ubuntu), add as argument so image can be custom built
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# We use clang and ssl defaults from bookworm because that is our base runtime distro
# For development we install same major nodejs version (18.x) from nodesource to use corepack
# First install basic tools and create dev user
RUN apt update && export DEBIAN_FRONTEND=noninteractive \
    && apt -y install --no-install-recommends \
    curl \
    ca-certificates \
    procps sudo lsb-release apt-utils \
    # Clean up
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /var/lib/apt/lists/* \
    && curl --proto '=https' --tlsv1.2 -sSf https://deb.nodesource.com/setup_18.x | sh -s -- -y \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt install -y --no-install-recommends \
    lld \
    lldb \
    clang \
    curl \
    make \
    pkg-config \
    libssl-dev \
    git \
    nodejs \
    postgresql-client-15 \
    # Clean up
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /var/lib/apt/lists/*

# Create a non-root user to use - see https://aka.ms/vscode-remote/containers/non-root-user.
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME -d /home/dev \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

# Change to nonroot user so files created are not root owned on host
USER $USERNAME

# Install Rust, our standard is 1.71 - we will set that in the toolchain for the project
ENV RUSTFLAGS="-C linker=clang -C link-arg=-fuse-ld=lld" \
    CARGO_HOME="/home/dev/.cargo" \
    RUSTUP_HOME="/home/dev/.rustup" \
    PATH="/home/dev/.cargo/bin:$PATH"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain none \
    && rustup toolchain install 1.71 --component rust-analyzer llvm-tools \
    && cargo install sqlx-cli --no-default-features --features native-tls,postgres

# Pin pnpm to 8.6.12 and yarn 3.6.2 to stable 
RUN sudo corepack enable \
    && corepack prepare pnpm@8.6.12 --activate \
    && corepack prepare yarn@3.6.2 --activate \
    && pnpm setup \
    && . /home/dev/.bashrc \
    && pnpm install -g redis-cli

WORKDIR /app

CMD [ "sleep", "infinity" ]
