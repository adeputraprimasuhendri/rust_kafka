# Stage 1: Build stage
FROM rust:1.80-slim as builder

# Install libssl-dev and pkg-config required by rdkafka / librdkafka
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy dependency files first to cache dependencies
COPY Cargo.toml Cargo.lock ./
RUN mkdir src && echo "fn main() {}" > src/main.rs && cargo build --release && rm -rf src

# Copy actual source code
COPY . .

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
