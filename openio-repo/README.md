# To run as a daemon (a docker stack in a docker swarm)

    docker swarm init
    docker stack deploy -c docker-compose.yml openio-repo-stack

# To stop the stack

    docker stack rm openio-repo-stack
    docker swarm leave --force
