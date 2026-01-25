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

All environment variables are passed through to IIB. Docker sets sensible defaults for containerized usage.

### Docker Defaults

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `EXTRA_PATHS` | `/outputs` | Paths to browse (comma-separated) |
| `EXTRA_OPTIONS` | | Additional CLI args |
| `IIB_DB_PATH` | `/cache/iib.db` | Database location |
| `IIB_CACHE_DIR` | `/cache` | Cache/thumbnails directory |
| `IIB_ACCESS_CONTROL` | `enable` | Filesystem access control |
| `IIB_DB_FILE_BACKUP_MAX` | `0` | Max DB backups (0 = disabled) |

### Common IIB Variables

| Variable | Description |
|----------|-------------|
| `IIB_SECRET_KEY` | Authentication key (if set, users must enter to access) |
| `IIB_SERVER_LANG` | Server language: `en`, `zh`, `auto` |
| `OPENAI_API_KEY` | OpenAI API key for AI features |
| `OPENAI_BASE_URL` | OpenAI-compatible API URL |
| `EMBEDDING_MODEL` | Embedding model for clustering |
| `AI_MODEL` | Chat model for AI features |

For full list, see [IIB's .env.example](https://github.com/zanllp/sd-webui-infinite-image-browsing/blob/main/.env.example).

### Example: Custom Database Path

```bash
docker run -d \
  -p 8080:8080 \
  -v /path/to/images:/outputs:ro \
  -v /path/to/data:/data \
  -e IIB_DB_PATH=/data/iib.db \
  -e IIB_CACHE_DIR=/data/cache \
  ghcr.io/pbanddev/infinite-image-browser-docker:latest
```

## Migrating from Local Installation

If you have an existing IIB database with likes/tags:

1. Copy your `iib.db` to a mounted volume
2. Set `IIB_DB_PATH` to point to it
3. Run path migration (Windows paths → container paths):
   ```bash
   docker exec <container> python migrate.py \
     --db_path /data/iib.db \
     --old_dir "C:\Your\Local\Output\Path" \
     --new_dir "/outputs"
   ```

## Build Locally

```bash
git clone https://github.com/PBandDev/infinite-image-browser-docker
cd infinite-image-browser-docker
docker compose up --build
```

## License

AGPL-3.0
