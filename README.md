# Containerize a Web Application with Docker

A Flask web application that counts page visits in Redis, containerized step by step:

**Source Code → Dockerfile → Image → Container → Docker Compose → Running Application**

**Author:** Payal Shekhawat

## Project structure
```
.
├── app/
│   ├── app.py              Source code (Flask application)
│   ├── requirements.txt    Python dependencies
│   ├── Dockerfile          Instructions to build the image
│   └── .dockerignore       Files excluded from the build
├── docker-compose.yml      Runs the web app and Redis together
├── .env                    Demo settings (port and message, no secrets)
├── run-manual.sh           Image and container with plain docker commands
├── run-compose.sh          Full run with Docker Compose and verification
└── docs/ubuntu-server-setup.md   Installing Docker on Ubuntu Server (VirtualBox)
```

## Architecture
```
 Browser / curl
       |  http://localhost:5000
       v
 +-------------+   backend network   +-------------------+
 | web (Flask  | ------------------> | redis (redis:7-   |
 |  + gunicorn)|   REDIS_HOST=redis  |  alpine)          |
 +-------------+                     +---------+---------+
                                               |
                                      named volume redis-data
```

## Prerequisites
- Linux with Docker Engine and the Docker Compose plugin. Installation steps for Ubuntu Server, including VirtualBox notes, are in [docs/ubuntu-server-setup.md](docs/ubuntu-server-setup.md).
- `curl` (`sudo apt-get install -y curl`).
- Internet access to pull images from Docker Hub.
- Port 5000 free on the machine running Docker.

Check your setup:
```bash
docker --version
docker compose version
```

## The six stages

### 1. Source code
`app/app.py` is a Flask app with two endpoints:

| URL | Response |
|-----|----------|
| `/` | JSON with a message, the visit counter and the container ID |
| `/health` | `{"status":"ok"}` if Redis is reachable, otherwise HTTP 503 |

It reads its settings from environment variables: `APP_MESSAGE`, `REDIS_HOST`, `REDIS_PORT`. Dependencies are listed in `app/requirements.txt`.

### 2. Dockerfile
`app/Dockerfile` follows common best practices:
- small base image (`python:3.12-slim`)
- dependencies installed before the code is copied, so the layer is cached until `requirements.txt` changes
- `pip install --no-cache-dir` to keep the image small
- runs as a non-root user
- a `HEALTHCHECK` that calls `/health`
- exec-form `CMD` that starts the app with gunicorn

### 3. Image
```bash
docker build -t flask-redis-app:1.0 ./app
docker images flask-redis-app
```

### 4. Container
The app needs Redis, so first create a network and start Redis, then the app:
```bash
docker network create manual-net
docker run -d --name manual-redis --network manual-net redis:7-alpine
docker run -d --name manual-web --network manual-net -p 5000:5000 \
  -e REDIS_HOST=manual-redis flask-redis-app:1.0
curl http://localhost:5000
```
`run-manual.sh` does all of this (including the Redis volume and cleanup) in one go:
```bash
./run-manual.sh
```

### 5. Docker Compose
`docker-compose.yml` describes both services, the network, the volume, the environment variables, the health check and the start-up order in one file, so a single command replaces all the manual steps above.

| Concept | Where in `docker-compose.yml` |
|---------|-------------------------------|
| Build the image from the Dockerfile | `build: ./app` |
| Publish the port | `ports: "${APP_PORT:-5000}:5000"` |
| Environment variables | `environment:` and `.env` |
| Service-name networking | `REDIS_HOST: redis` on the `backend` network |
| Persistent data | `redis-data` volume mounted at `/data` |
| Start Redis first and wait until healthy | `depends_on` with `condition: service_healthy` |
| Restart policy | `restart: unless-stopped` |

### 6. Running application
```bash
./run-compose.sh
```
This script validates the file, builds and starts everything, calls the app three times, checks `/health`, recreates the containers to prove the data persists, shows logs, and finally removes everything including the volume.

Or run the commands yourself:
```bash
docker compose up -d --build     # build and start
curl http://localhost:5000       # use the app
docker compose ps                # status
docker compose logs -f web       # follow logs (Ctrl+C to stop following)
docker compose down              # stop and remove containers and network
docker compose down --volumes    # ... and also delete the Redis volume
```

## Expected output
```
{"container":"<container id>","message":"Hello from Docker Compose!","visits":1}
{"container":"<container id>","message":"Hello from Docker Compose!","visits":2}
```
After `docker compose down` followed by `docker compose up -d`, the counter continues (for example `visits: 4`) because it is stored in the `redis-data` volume.

## Configuration
Edit `.env` and run `docker compose up -d` again:

| Variable | Default | Meaning |
|----------|---------|---------|
| `APP_PORT` | `5000` | Port published on the host |
| `APP_MESSAGE` | `Hello from Docker Compose!` | Greeting returned by `/` |

`.env` contains only demo values. Never commit real passwords or keys.

## Opening the app from your computer when Docker runs in a VirtualBox VM
Use VirtualBox port forwarding (TCP, host port 5000 to guest port 5000) or a bridged adapter. Details are in [docs/ubuntu-server-setup.md](docs/ubuntu-server-setup.md).

## Troubleshooting
| Problem | Fix |
|---------|-----|
| `permission denied ... Docker daemon socket` | Use `sudo`, or add your user to the `docker` group (see the setup guide) |
| `port is already allocated` | Free port 5000, or set another `APP_PORT` in `.env` |
| `./run-compose.sh: Permission denied` | Run `bash run-compose.sh` |
| Counter shows an error 503 right after start | Wait a few seconds for Redis to become healthy and try again |

## Free resources
- Docker documentation - https://docs.docker.com/
- Docker Hub - https://hub.docker.com/
- Docker Compose documentation - https://docs.docker.com/compose/
- Dockerfile reference - https://docs.docker.com/reference/dockerfile/
- Flask documentation - https://flask.palletsprojects.com/
- Redis documentation - https://redis.io/docs/

## License
MIT License. See [LICENSE](LICENSE).
