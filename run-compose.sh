#!/usr/bin/env bash
# Run the full application with Docker Compose and verify it, including data persistence.
set -u
cd "$(dirname "$0")"

step() { printf '\n=== %s ===\n' "$1"; }

step "1. Validate the Compose file"
docker compose config --quiet && echo "docker-compose.yml is valid."

step "2. Build the image and start all services in the background"
docker compose up -d --build

step "3. Show the running services (wait for them to become healthy)"
sleep 8
docker compose ps

step "4. Call the application three times (the visit counter increases)"
curl -s http://localhost:5000; echo
curl -s http://localhost:5000; echo
curl -s http://localhost:5000; echo

step "5. Health endpoint"
curl -s http://localhost:5000/health; echo

step "6. Persistence test: recreate the containers, keep the volume"
docker compose down
docker compose up -d
sleep 8
echo "The counter continues from where it stopped:"
curl -s http://localhost:5000; echo

step "7. Logs of the web service (last lines)"
docker compose logs --tail 5 web

step "8. Stop and remove everything, including the volume"
docker compose down --volumes
echo "Done."
