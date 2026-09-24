# Stage 1: Build stage
FROM rust:1.80-slim as builder

# Install libssl-dev, pkg-config, and cmake required by rdkafka / librdkafka
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    build-essential \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependency definition
COPY Cargo.toml ./

# Create dummy source files for all expected targets to pre-compile dependencies
RUN mkdir -p src/bin && \
    echo "fn main() {}" > src/main.rs && \
    echo "fn main() {}" > src/bin/publisher.rs && \
    echo "fn main() {}" > src/bin/consumer.rs && \
    cargo build --release && \
    rm -rf src

# Copy actual source code and Cargo.lock if present
COPY . .

# Touch the source files so Cargo knows to re-compile the actual code (not the dummy binaries)
RUN touch src/bin/publisher.rs src/bin/consumer.rs

# Build both binaries in release mode
RUN cargo build --release --bin publisher && cargo build --release --bin consumer

# Stage 2: Runtime stage
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy binaries from builder stage
COPY --from=builder /app/target/release/publisher /app/publisher
COPY --from=builder /app/target/release/consumer /app/consumer

CMD ["/app/publisher"]
