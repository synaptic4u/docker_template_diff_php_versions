# Stop and remove project containers only
sudo docker compose down

# Stop and remove project containers and volumes
sudo docker compose down -v

# Remove all unused volumes
sudo docker volume prune -f

# Remove all unused networks
sudo docker network prune -f

# Optional: remove all dangling images (not currently used)
sudo docker image prune -f

# START project
sudo docker compose up -d

# Stop project
sudo docker compose down

# Stop project and remove volumes
docker compose down -v

# List running containers (to find the container name or ID):
sudo docker ps

# Access the container's shell:
sudo docker exec -it my_container_name /bin/bash

# Connect to MySQL CLI inside container
sudo docker exec -it synaptic_db_webPHP7 mysql -u synaptic_db_webPHP7 -p
sudo docker exec -it synaptic_db_webPHP8 mysql -u synaptic_db_webPHP8 -p
