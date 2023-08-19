FROM debian:bookworm-slim

# We use node, clang and ssl defaults from bookworm because that is our base runtime distro
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt install -y \
    lld \
    clang \
    curl \
    pkg-config \
    libssl-dev \
    git \
    nodejs \
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Rust, our standard is 1.71 - we will set that in the toolchain for the project
ENV RUSTFLAGS "-C link-arg=-fuse-ld=lld"
ENV PATH="/root/.cargo/bin:$PATH"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain none
RUN rustup toolchain install 1.71 --component rust-analyzer llvm-tools
RUN cargo install sqlx-cli --no-default-features --features native-tls,postgres

# Pin pnpm to 8.6 and nodejs to 18.x (from bookworm default)
ENV PNPM_VERSION 8.6.12
ENV SHELL bash
RUN curl --proto '=https' --tlsv1.2 -sSf https://get.pnpm.io/install.sh | sh -s -- -g pnpm
RUN . /root/.bashrc

CMD [ "sleep", "infinity" ]
