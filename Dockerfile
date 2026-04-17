FROM node:20-bookworm-slim AS upstream-build

ARG UPSTREAM_REPO=https://github.com/zanllp/infinite-image-browsing.git
ARG IIB_REF=main

RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN git clone "$UPSTREAM_REPO" . && \
    git checkout "$IIB_REF" && \
    git rev-parse HEAD > /tmp/iib-commit && \
    (git describe --tags --abbrev=0 || true) > /tmp/iib-tag && \
    corepack enable && \
    cd vue && \
    yarn install --frozen-lockfile && \
    yarn build

FROM python:3.11-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        pkg-config \
        build-essential \
        libavformat-dev \
        libavcodec-dev \
        libavdevice-dev \
        libavutil-dev \
        libswscale-dev \
        libswresample-dev \
        libavfilter-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=upstream-build /src /app
COPY --from=upstream-build /tmp/iib-commit /app/.iib-commit
COPY --from=upstream-build /tmp/iib-tag /app/.iib-tag

RUN sed -i 's/av>=14,<15/av>=12,<13/' requirements.txt

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY entry.sh /usr/local/bin/entry.sh
COPY config.json /config.json
COPY favicon.svg /app/default-favicon.svg

RUN sed -i 's/\r$//' /usr/local/bin/entry.sh && \
    chmod +x /usr/local/bin/entry.sh && \
    mkdir -p /app/custom

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entry.sh"]
