# Configure repository signing key

Edit `docker-compose.yml` to configure `oiorepo` service's volumes in order to
make the right signing keys available to the build process.

# To run as a daemon (a docker stack in a docker swarm)

    docker swarm init
    docker stack deploy -c docker-compose.yml openio-repo-stack

# To stop the stack

    docker stack rm openio-repo-stack
    docker swarm leave --force
