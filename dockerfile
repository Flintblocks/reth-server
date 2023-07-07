# Build Stage
FROM rust:1.55 as builder

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
COPY --from=builder /usr/src/myapp/target/release/main .

CMD ["./main"]
