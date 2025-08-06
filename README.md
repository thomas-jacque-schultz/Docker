# Docker

execute the following command to build the docker image
```bash
# build the docker image : Admin, Gaming, Host
docker-compose up -d 

# build the docker image : Pterodactyl Panel
docker-compose exec panel php artisan p:user:make
```