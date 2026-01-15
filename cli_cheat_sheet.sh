

# Stop and remove all containers
sudo docker stop $(sudo docker ps -q)
sudo docker rm $(sudo docker ps -aq)

# Remove all unused volumes
sudo docker volume prune -f

# Remove all unused networks
sudo docker network prune -f

# Optional: remove all dangling images (not currently used)
sudo docker image prune -f

# START
sudo docker compose up -d 

docker compose down -v

# List running containers (to find the container name or ID):
sudo docker ps

# Access the container's shell:
sudo docker exec -it my_container_name /bin/bash

# Connect using MariaDB CLI inside container
docker-compose exec mariadb mariadb -u testuser -p -h localhost testdb
