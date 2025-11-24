# Aerospike DevOps Days

Scaffolding and content for hands-on devops workshops

## To get started

1. Clone the repo
    
    ```bash
    git clone https://github.com/aerospike-examples/devops-workshop.git
    ```

2. Replace the `etc/aerospike/features.conf` file with your `features.conf` (will be provided for workshop).

3. Run Docker compose

    ```bash
    DOCKER_BUILDKIT=1 docker compose up -d
    ```

This will create three containers:

- `aerospike-node-1`
- `aerospike-node-2`
- `aerospike-client`

