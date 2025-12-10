# Aerospike DevOps Workshop

A Docker-based environment for hands-on Aerospike installation and operations workshops.

## Editions

| Edition | License | Build Command |
|---------|---------|---------------|
| **Community** (default) | Free | `docker-compose up -d --build` |
| Enterprise | Required | `AEROSPIKE_EDITION=enterprise docker-compose up -d --build` |

## Quick Start (Community Edition)

```bash
# Clone the repo
git clone https://github.com/aerospike-examples/devops-workshop.git
cd devops-workshop

# Build and start (downloads Community Edition automatically)
docker-compose up -d --build
```

This creates 4 VM-like containers:

| Container | Purpose | Tools |
|-----------|---------|-------|
| `aerospike-node-1` | Database server | Aerospike package (not installed) |
| `aerospike-node-2` | Database server | Aerospike package (not installed) |
| `aerospike-node-3` | Database server | Aerospike package (not installed) |
| `aerospike-client` | Client/tools | asadm, asinfo, aql, asbench |

## Access Containers

```bash
# Access a database node
docker exec -it aerospike-node-1 bash

# Access the client node
docker exec -it aerospike-client bash
```

## Full Documentation

📖 **See [WORKSHOP.md](WORKSHOP.md) for complete documentation** including:

- Architecture overview and diagrams
- Step-by-step installation instructions
- Managing Aerospike with systemctl
- Using Aerospike tools (asadm, asinfo, aql)
- Running benchmarks with asbench
- Customization guide (adding ports, folders, nodes)
- Switching between Community and Enterprise Edition
- Troubleshooting guide

## Enterprise Edition

To use Enterprise Edition:

1. Place your package in `package/enterprise/`
2. Place your `features.conf` in `etc/aerospike/`
3. Build with: `AEROSPIKE_EDITION=enterprise docker-compose up -d --build`

See [WORKSHOP.md](WORKSHOP.md#switching-between-community-and-enterprise-edition) for details.

## Requirements

- Docker with Docker Compose (or Podman with podman-compose)
- 8GB RAM minimum
- 10GB disk space
- Internet connection (to download Community Edition)
