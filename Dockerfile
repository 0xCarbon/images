FROM debian:bookworm-slim
# Setup a user with default UID=1000 (debain, ubuntu), add as argument so image can be custom built
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# We use node, clang and ssl defaults from bookworm because that is our base runtime distro
# For development we install same major nodejs (18.x) from nodesource use corepack
RUN apt-get update \
    && apt-get -y install --no-install-recommends curl apt-utils 2>&1 \
    curl --proto '=https' --tlsv1.2 -sSf https://deb.nodesource.com/setup_18.x | sh -s -- -y && \
    && apt-get -y install git procps sudo lsb-release \
    # Create a non-root user to use - see https://aka.ms/vscode-remote/containers/non-root-user.
    && groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    # Install dev env
    && apt install -y \
    lld \
    lldb \
    clang \
    curl \
    make \
    pkg-config \
    libssl-dev \
    git \
    nodejs \
    # Clean up
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
# From now on we go as nonroot user so files created are not root owned on host
USER $USERNAME

# Install Rust, our standard is 1.71 - we will set that in the toolchain for the project
ENV RUSTFLAGS="-C linker=clang -C link-arg=-fuse-ld=lld"
ENV PATH="$HOME/.cargo/bin:$PATH"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain none
RUN rustup toolchain install 1.71 --component rust-analyzer llvm-tools
RUN cargo install sqlx-cli --no-default-features --features native-tls,postgres

# Pin pnpm to 8.6.12 and yarn 3.6.2 to stable 
RUN corepack enable
RUN corepack prepare pnpm@8.6.12 --activate
RUN corepack prepare yarn@3.6.2 --activate
RUN . .bashrc

CMD [ "sleep", "infinity" ]
