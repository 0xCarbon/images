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
    ca-certificates locales \
    procps sudo lsb-release apt-utils \
    # Clean up
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /var/lib/apt/lists/* \
    # Install our default compiler, db client and node version
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

# Configure default locale for code dev
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8 \
    LANGUAGE en_US:en \
    LC_ALL en_US.UTF-8

# Create a non-root user to use - see https://aka.ms/vscode-remote/containers/non-root-user.
RUN groupadd --gid $USER_GID $USERNAME && \
    useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME -d /home/dev && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Change to nonroot user so files created are not root owned on host
USER $USERNAME

# Install Rust, our standard is 1.71 - you must pin it in the toolchain for the project
ENV RUSTFLAGS="-C linker=clang -C link-arg=-fuse-ld=lld" \
    CARGO_HOME="/home/dev/.cargo" \
    RUSTUP_HOME="/home/dev/.rustup" \
    PNPM_HOME="/home/dev/.local/share/pnpm" \
    PATH="/home/dev/.cargo/bin:/home/dev/.local/share/pnpm:$PATH" \
    SHELL="/bin/bash"
    
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain none && \
    rustup toolchain install 1.71 --component rust-analyzer llvm-tools

# Install our detault cargo tools on 0xCarbon
RUN cargo install cargo-audit cargo-expand cargo-tarpaulin cargo-deny cargo-fuzz && \
    cargo install sqlx-cli --no-default-features --features native-tls,postgres

# Pin pnpm to 8.6.12 and yarn 3.6.2 to stable 
RUN sudo corepack enable && \
    corepack prepare pnpm@8.6.12 --activate && \
    corepack prepare yarn@3.6.2 --activate && \
    pnpm setup && \
    pnpm install -g redis-cli@2.1.2

RUN . /home/dev/.bashrc
WORKDIR /workspaces

CMD [ "sleep", "infinity" ]