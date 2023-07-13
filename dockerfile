# Build Stage
FROM rust:latest as builder
RUN apt-get update && apt-get install -y clang
WORKDIR /usr/src/myapp

# Copy over your source code
COPY Cargo.toml .
COPY src src

# Build the binary with release profile
RUN cargo build --release

# Final Stage
FROM archlinux:latest

WORKDIR /root

# Copy the binary from builder stage
RUN pacman -Syu --noconfirm clang
COPY --from=builder /usr/src/myapp/target/release/reth-server .
EXPOSE 8545
EXPOSE 8546
CMD ["./reth-server"]
