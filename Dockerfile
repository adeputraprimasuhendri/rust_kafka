# Stage 1: Build stage
FROM rust:1.80-slim as builder

# Install C/C++ build dependencies required by librdkafka (C library used by rdkafka)
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    build-essential \
    cmake \
    git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy all source files
COPY . .

# Build both publisher and consumer binaries in release mode
RUN cargo build --release --bin publisher && cargo build --release --bin consumer

# Stage 2: Runtime stage
FROM debian:bookworm-slim

# Install runtime SSL dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy release binaries from the builder stage
COPY --from=builder /app/target/release/publisher /app/publisher
COPY --from=builder /app/target/release/consumer /app/consumer

CMD ["/app/publisher"]
