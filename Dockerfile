FROM debian:bookworm-slim

# We use node, clang and ssl defaults from bookworm because that is our base runtime distro
# For development we install same major nodejs (18.x) from nodesource use corepack
RUN curl --proto '=https' --tlsv1.2 -sSf https://deb.nodesource.com/setup_18.x | sh -s -- -y && \
    export DEBIAN_FRONTEND=noninteractive \
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
    && apt autoremove -y \
    && apt clean -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Rust, our standard is 1.71 - we will set that in the toolchain for the project
ENV RUSTFLAGS="-C linker=clang -C link-arg=-fuse-ld=lld"
ENV PATH="/root/.cargo/bin:$PATH"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain none
RUN rustup toolchain install 1.71 --component rust-analyzer llvm-tools
RUN cargo install sqlx-cli --no-default-features --features native-tls,postgres

# Pin pnpm to 8.6.12 and yarn 3.6.2 to stable 
RUN corepack enable
RUN corepack prepare pnpm@8.6.12 --activate
RUN corepack prepare yarn@3.6.2 --activate
RUN . /root/.bashrc

CMD [ "sleep", "infinity" ]
