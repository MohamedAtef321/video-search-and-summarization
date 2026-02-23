# Local Linux Deployment Guide

> Full stack: **UI + Backend + Databases**, using local **Ollama** models (no NVIDIA cloud APIs required).

---

## Prerequisites

| Requirement | Notes |
|---|---|
| Docker + Docker Compose v2 | `docker compose version` ≥ 2.0 |
| NVIDIA GPU | Driver ≥ 525, `nvidia-smi` working |
| NVIDIA Container Toolkit | For `runtime: nvidia` in Docker |
| Ollama | Installed and running on the host (`ollama serve`) |
| Ollama models pulled | See below |

### Pull Required Ollama Models

```bash
ollama pull llama3.1:8b
ollama pull qwen3-embedding:4b
ollama pull qwen3-vl:8b
ollama pull dengcao/Qwen3-Reranker-8B:Q8_0
```

---

## 1 — Install NVIDIA Container Toolkit (if not already done)

```bash
# Add NVIDIA repo
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

---

## 2 — Clone & Navigate

```bash
git clone https://github.com/MohamedAtef321/video-search-and-summarization
cd video-search-and-summarization/deploy/docker/local_deployment
```

---

## 3 — Configure Environment

The `.env` file is already pre-configured for Ollama. Verify or adjust these key values:

```bash
# .env — key settings (already configured for Ollama)
export FRONTEND_PORT=9100          # UI access port
export BACKEND_PORT=8100           # API access port

export VLM_MODEL_TO_USE=openai-compat
export VIA_VLM_ENDPOINT="http://host.docker.internal:11434/v1"
export VIA_VLM_API_KEY="ollama"
export VIA_VLM_OPENAI_MODEL_DEPLOYMENT_NAME="qwen3-vl:8b"

export GRAPH_DB_USERNAME=neo4j
export GRAPH_DB_PASSWORD=password       # Change this for production
```

> **Note:** `host.docker.internal` resolves to the host machine's IP from inside Docker containers.  
> This is already configured in `compose.yaml` via `extra_hosts: host.docker.internal: host-gateway`.

---

## 4 — Create Docker Network

The compose file declares the network as `external: true`, so you must create it manually **once** before the first run.

Since you're running as **root**, `$USER` = `root`, so the network name is `via-engine-root`:

```bash
docker network create via-engine-root
```

> If you ever switch to a different user, run `docker network create via-engine-${USER}` accordingly.

---

## 5 — Start Ollama (if not already running)

```bash
# Run as a background service
ollama serve &

# Verify it's reachable
curl http://localhost:11434/api/tags
```

---

## 6 — Start the Stack

```bash
# Load env and start all services
source .env
docker compose up -d
```

This starts:
| Service | Description | Default Port |
|---|---|---|
| `via-server` | Main backend + frontend UI | `8100` (API), `9100` (UI) |
| `graph-db` | Neo4j graph database | `7474` (HTTP), `7687` (Bolt) |
| `arango-db` | ArangoDB | `8529` |
| `milvus-standalone` | Vector database | `19530` |
| `minio` | Object storage | `9000` |
| `elasticsearch` | Search engine | `9200` |

---

## 7 — Verify Services

```bash
# Check all containers are running
docker compose ps

# Watch logs (follow mode)
docker compose logs -f via-server

# Check Milvus is healthy (stack waits for this)
curl http://localhost:9091/healthz
```

---

## 8 — Access the UI

Once `via-server` is running and healthy, open your browser:

```
http://<your-server-ip>:9100
```

The backend API is available at:
```
http://<your-server-ip>:8100
```

---

## Stopping the Stack

```bash
source .env
docker compose down
```

To also remove all stored data (databases, model caches):
```bash
docker compose down -v
```

---

## Troubleshooting

### Containers can't reach Ollama
Verify `host.docker.internal` resolves correctly from inside a container:
```bash
docker run --rm --add-host=host.docker.internal:host-gateway alpine \
  wget -qO- http://host.docker.internal:11434/api/tags
```
If it fails, restart Docker: `sudo systemctl restart docker`.

### Milvus takes too long to start
The stack waits up to ~90s for Milvus to become healthy. If it fails, run:
```bash
docker compose logs milvus-standalone
```

### Check GPU is visible inside container
```bash
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

### View all logs
```bash
docker compose logs --tail=100 via-server
```
