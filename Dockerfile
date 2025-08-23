# Stage 1: Download and extract HugeGraph Loader from GitHub Release
FROM debian:bullseye AS custom-atomspace-builder

WORKDIR /build

RUN apt-get update && apt-get install -y curl && \
    curl -L -o loader.tar.gz https://github.com/rejuve-bio/custom-atomspace-builder/releases/download/v1.0.0/apache-hugegraph-loader-incubating-1.5.0.tar.gz && \
    tar --strip-components=2 -xzf loader.tar.gz && \
    rm loader.tar.gz

# Stage 2: Python runtime
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1

ARG API_PORT

RUN apt-get update && apt-get install -y \
    default-jre-headless \
    curl \
    wget \
    bash \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy extracted HugeGraph Loader from previous stage
COPY --from=custom-atomspace-builder /build/apache-hugegraph-loader-incubating-1.5.0 \
    /app/hugegraph-loader/apache-hugegraph-loader-incubating-1.5.0

# Copy your app code
COPY app/ ./app/
COPY config.yaml .
COPY .env .env

RUN mkdir -p output uploads logs && \
    find /app/hugegraph-loader -name "*.sh" -exec chmod +x {} \;

ENV PYTHONPATH=/app
ENV HUGEGRAPH_LOADER_PATH=/app/hugegraph-loader/apache-hugegraph-loader-incubating-1.5.0/bin/hugegraph-loader.sh

RUN echo "Verifying HugeGraph Loader installation..." && \
    ls -la /app/hugegraph-loader/apache-hugegraph-loader-incubating-1.5.0/bin/ && \
    test -f "$HUGEGRAPH_LOADER_PATH"

EXPOSE $API_PORT

CMD ["python", "-m", "app.main"]
