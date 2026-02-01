FROM python:3.11-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime deps + build tools for PyAV
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
        libavfilter-dev \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone --depth 1 https://github.com/zanllp/sd-webui-infinite-image-browsing.git .

# Patch requirements.txt: use av 12.x (compatible with ffmpeg 5.x in bookworm)
RUN sed -i 's/av>=14,<15/av>=12,<13/' requirements.txt

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

COPY entry.sh /usr/local/bin/entry.sh
RUN chmod +x /usr/local/bin/entry.sh

COPY config.json /config.json

# Copy default favicon (can be overridden by mounting /app/custom/favicon.svg)
COPY favicon.svg /app/default-favicon.svg
RUN mkdir -p /app/custom

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/entry.sh"]
