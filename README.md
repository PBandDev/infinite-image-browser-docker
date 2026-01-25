# Infinite Image Browser Docker

Docker container for [sd-webui-infinite-image-browsing](https://github.com/zanllp/sd-webui-infinite-image-browsing) standalone mode.

## Quick Start

```bash
docker run -d \
  -p 8080:8080 \
  -v /path/to/your/images:/outputs:ro \
  -v iib-cache:/cache \
  ghcr.io/pbanddev/infinite-image-browser-docker:latest
```

Open http://localhost:8080

## Image Tags

| Tag | Description | Update Frequency |
|-----|-------------|------------------|
| `latest` | Follows upstream `main` branch | Weekly (Sundays) |
| `vX.X.X` | Pinned to upstream release version | On new release |

Use a version tag for stability:
```bash
docker pull ghcr.io/pbanddev/infinite-image-browser-docker:v1.2.3
```

## Docker Compose

```yaml
services:
  iib:
    image: ghcr.io/pbanddev/infinite-image-browser-docker:latest
    ports:
      - "8080:8080"
    volumes:
      - /path/to/images:/outputs:ro
      - iib-cache:/cache
    restart: unless-stopped

volumes:
  iib-cache:
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | 8080 | Server port |
| `EXTRA_PATHS` | /outputs | Paths to browse (comma-separated) |
| `EXTRA_OPTIONS` | | Additional CLI args |

## Build Locally

```bash
git clone https://github.com/PBandDev/infinite-image-browser-docker
cd infinite-image-browser-docker
docker compose up --build
```

## License

AGPL-3.0
