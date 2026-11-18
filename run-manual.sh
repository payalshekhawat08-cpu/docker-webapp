#!/usr/bin/env bash
# Run the application WITHOUT Compose, using plain docker commands.
# This shows exactly what Compose automates for you.
set -u
cd "$(dirname "$0")"

step() { printf '\n=== %s ===\n' "$1"; }

cleanup() {
  docker rm -f manual-web manual-redis >/dev/null 2>&1
  docker network rm manual-net >/dev/null 2>&1
  docker volume rm manual-redis-data >/dev/null 2>&1
}
cleanup

step "1. Build the image from the Dockerfile"
docker build -t flask-redis-app:1.0 ./app

step "2. Create a network and a volume"
docker network create manual-net
docker volume create manual-redis-data

step "3. Start Redis (data stored in the volume)"
docker run -d --name manual-redis --network manual-net \
  -v manual-redis-data:/data redis:7-alpine redis-server --appendonly yes

step "4. Start the web application (REDIS_HOST points to the Redis container name)"
docker run -d --name manual-web --network manual-net -p 5000:5000 \
  -e REDIS_HOST=manual-redis -e APP_MESSAGE="Hello from plain docker run!" \
  flask-redis-app:1.0

step "5. Test the application"
sleep 4
curl -s http://localhost:5000; echo
curl -s http://localhost:5000; echo

step "6. Clean up"
cleanup
echo "Removed containers, network and volume."
