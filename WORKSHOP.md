# Aerospike DevOps Workshop

This repository provides a Docker-based environment to learn how to install, configure, and operate an Aerospike database cluster from scratch.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Understanding the Environment](#understanding-the-environment)
5. [Accessing the Nodes](#accessing-the-nodes)
6. [Installing Aerospike](#installing-aerospike)
7. [Managing Aerospike](#managing-aerospike)
8. [Using Aerospike Tools](#using-aerospike-tools)
9. [Running Benchmarks](#running-benchmarks)
10. [Customization Guide](#customization-guide)
11. [Troubleshooting](#troubleshooting)
12. [Cleanup](#cleanup)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Docker Network: devops-net                           │
│                         Subnet: 172.120.0.0/16                              │
│                                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐              │
│  │ aerospike-node-1│  │ aerospike-node-2│  │ aerospike-node-3│              │
│  │   172.120.0.11  │  │   172.120.0.12  │  │   172.120.0.13  │              │
│  │                 │  │                 │  │                 │              │
│  │  Ubuntu 24.04   │  │  Ubuntu 24.04   │  │  Ubuntu 24.04   │              │
│  │  + systemd      │  │  + systemd      │  │  + systemd      │              │
│  │  + Aerospike    │  │  + Aerospike    │  │  + Aerospike    │              │
│  │    Server pkg   │  │    Server pkg   │  │    Server pkg   │              │
│  │    (not run)    │  │    (not run)    │  │    (not run)    │              │
│  │                 │  │                 │  │                 │              │
│  │ Ports:          │  │ Ports:          │  │ Ports:          │              │
│  │  3000 (service) │  │  3000 (service) │  │  3000 (service) │              │
│  │  3001 (fabric)  │  │  3001 (fabric)  │  │  3001 (fabric)  │              │
│  │  3002 (mesh)    │  │  3002 (mesh)    │  │  3002 (mesh)    │              │
│  │  3003 (admin)   │  │  3003 (admin)   │  │  3003 (admin)   │              │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘              │
│           │                    │                    │                       │
│           └────────────────────┼────────────────────┘                       │
│                                │                                            │
│                    ┌───────────┴───────────┐                                │
│                    │   aerospike-client    │                                │
│                    │     172.120.0.20      │                                │
│                    │                       │                                │
│                    │     Ubuntu 24.04      │                                │
│                    │     + systemd         │                                │
│                    │     + Aerospike Tools │                                │
│                    │     + asbench         │                                │
│                    └───────────────────────┘                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Component Summary

| Node | Hostname | IP Address  | Purpose |
|------|----------|-------------|---------|
| Database 1 | aerospike-node-1 | 172.120.0.11 | Aerospike server (cluster member) |
| Database 2 | aerospike-node-2 | 172.120.0.12 | Aerospike server (cluster member) |
| Database 3 | aerospike-node-3 | 172.120.0.13 | Aerospike server (cluster member) |
| Client | aerospike-client | 172.120.0.20 | Tools, benchmarking, client operations |

### Port Reference

| Port | Protocol | Purpose |
|------|----------|---------|
| 3000 | TCP | Client service port (queries) |
| 3001 | TCP | Fabric port (intra-cluster) |
| 3002 | TCP | Heartbeat/Mesh port (cluster discovery) |
| 3003 | TCP | admin port (management) |

---

## Prerequisites

Before starting, ensure you have:

1. **Docker** installed and running
   - [Install Docker Desktop](https://www.docker.com/products/docker-desktop/) (Mac/Windows)
   - Or [Docker Engine](https://docs.docker.com/engine/install/) (Linux)

2. **Docker Compose** (included with Docker Desktop, or install separately on Linux)

3. **At least 8GB RAM** available for Docker

4. **10GB disk space** for images and data

### Verify Docker Installation

```bash
# Check Docker version
docker --version

# Check Docker Compose version
docker-compose version

# Ensure Docker is running
docker ps
```

---

## Quick Start

### Choose Your Edition

This workshop supports both **Community Edition** (free, no license required) and **Enterprise Edition** (requires license).

| Edition | License | Default | Features |
|---------|---------|---------|----------|
| Community | Free | ✅ Yes | Core database features |
| Enterprise | Required | No | Advanced features (encryption, LDAP, etc.) |

### 1. Build and Start All Containers
Optional: Place Aerospike package in package/ (aerospike-server-*_ubuntu24.04_*.tgz) to avoid downloading it during build

**For Community Edition (default):**

```bash
# Navigate to the workshop directory
cd /path/to/devops-workshop

# Build and start (downloads Community Edition automatically if not in package/ directory)
docker-compose up -d --build
```

**For Enterprise Edition:**

```bash
# Navigate to the workshop directory
cd /path/to/devops-workshop

export AEROSPIKE_EDITION=enterprise
# Build and start (downloads Enterprise Edition automatically if not in package/ directory)
docker-compose up -d --build
```

This command:
- Builds the base image first (shared by database and client nodes)
- Builds the database node image (reused by all 3 database containers)
- Builds the client node image
- Creates the network
- Starts all 4 containers in the background

**Note:** The build process is optimized - the base image containing common packages (systemd, utilities) is built once and shared by both database and client nodes, reducing build time and image size.

### 2. Verify Containers Are Running

```bash
docker-compose ps
```

Expected output:
```
NAME                STATUS    PORTS
aerospike-client    running   
aerospike-node-1    running   
aerospike-node-2    running   
aerospike-node-3    running   
```

### 3. Access a Container

```bash
# Access database node 1
docker exec -it aerospike-node-1 bash

# Access the client
docker exec -it aerospike-client bash
```

---

## Understanding the Environment

### What's in Each Container?

**Database Nodes (aerospike-node-1, 2, 3):**
- Ubuntu 24.04 with systemd
- Aerospike Enterprise Server package (in `/home/aero_devops/`)
- Pre-configured `/etc/aerospike/aerospike.conf`
- Common utilities (vim, nano, curl, wget, etc.)
- User: `aero_devops` with sudo access
- Aerospike downloaded package (not installed)

**Client Node (aerospike-client):**
- Ubuntu 24.04 with systemd
- Aerospike Tools (asadm, asinfo, aql)
- Aerospike Benchmark (asbench)
- Pre-configured asbench workloads
- User: `aero_devops` with sudo access

### Directory Structure

```
devops-workshop/
├── compose.yaml           # Docker Compose configuration
├── base.Dockerfile        # Shared base image (systemd, common packages)
├── database.Dockerfile    # Database node image definition
├── client.Dockerfile      # Client node image definition
├── README.md              # Quick start guide
├── WORKSHOP.md            # This documentation
├── etc/
│   └── aerospike/
│       ├── aerospike.conf      # Aerospike configuration
│       └── features.conf       # License key (Enterprise Edition, optional)
├── asbench-configs/
│   ├── README.md              # Benchmark configuration documentation
│   ├── insert-1m-records.yaml  # Insert 1M records workload
│   ├── insert-1m-records.sh   # Script to run insert workload
│   ├── read-write-workload.yaml # Mixed read/write workload
│   └── read-write-workload.sh  # Script to run read/write workload
├── package/
│   └── enterprise/            # Enterprise Edition packages (if using Enterprise)
│       └── aerospike-server-enterprise_*.tgz
└── shared/                     # Shared folder across all containers
```

### Shared Folders

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `./shared/` | `/home/aero_devops/shared/` | Share files between containers and host |
| `./etc/aerospike/` | `/home/aero_devops/aerospike-config/` | Staged config files (copy to `/etc/aerospike/` after install) |
| `./asbench-configs/` | `/home/aero_devops/asbench-configs/` | Benchmark configs (client only) |

---

## Accessing the Nodes

### Interactive Shell Access

```bash
# Database nodes
docker exec -it aerospike-node-1 bash
docker exec -it aerospike-node-2 bash
docker exec -it aerospike-node-3 bash

# Client node
docker exec -it aerospike-client bash
```

### Run a Single Command

```bash
# Check hostname
docker exec aerospike-node-1 hostname

# Check IP address
docker exec aerospike-node-1 hostname -I

# Test connectivity between nodes
docker exec aerospike-client ping -c 3 aerospike-node-1
```

### Access as Root

```bash
docker exec -it -u root aerospike-node-1 bash
```

### The Shell Persists

When you exit a shell (`exit` or Ctrl+D), the container keeps running. Only the shell session ends. You can reconnect anytime with `docker exec`.

---

## Installing Aerospike

The Aerospike server package is pre-loaded but **not installed**. Follow these steps on each database node.

### Step 1: Connect to a Database Node

```bash
docker exec -it aerospike-node-1 bash
```

### Step 2: Extract and Install

```bash
# Navigate to home directory
cd ~

# List the package
ls -la aerospike-*.tgz

# Extract the package
tar -xzf aerospike-*.tgz

# Enter the extracted directory
cd aerospike-server-*/

# Run the installation script
sudo ./asinstall
```

### Step 3: Copy the Configuration Files

The pre-configured config files are staged in `~/aerospike-config/`. Copy them after installation:

**For Community Edition:**
```bash
# Copy the workshop configuration
sudo cp ~/aerospike-config/aerospike.conf /etc/aerospike/
```

**For Enterprise Edition:**
```bash
# Copy the workshop configuration
sudo cp ~/aerospike-config/aerospike.conf /etc/aerospike/

# Copy your feature key file
sudo cp ~/aerospike-config/features.conf /etc/aerospike/

# Enable the feature key in the config
sudo sed -i 's/# feature-key-file/feature-key-file/' /etc/aerospike/aerospike.conf
```

### Step 4: Verify Installation

```bash
# Check Aerospike version
asd --version

# Check if the service is registered (should show "inactive")
systemctl status aerospike

# Verify config file is in place
cat /etc/aerospike/aerospike.conf
```

### Step 5: Start Aerospike

```bash
# Check if Aerospike is already running
systemctl is-active aerospike

# Start Aerospike
sudo systemctl start aerospike

# Verify it's running
systemctl status aerospike
```

You should see `Active: active (running)` in the output.

### Step 6: Repeat on Other Nodes

Repeat steps 1-5 on `aerospike-node-2` and `aerospike-node-3`.

---

## Managing Aerospike

### Start Aerospike

```bash
# On each database node
sudo systemctl start aerospike
```

### Stop Aerospike

```bash
sudo systemctl stop aerospike
```

### Check Status

```bash
sudo systemctl status aerospike
```

### View Logs

```bash
# Via systemd journal
sudo journalctl -u aerospike -f

# Or the log file
tail -f /var/log/aerospike/aerospike.log
```

### Enable Auto-Start (Optional)

```bash
sudo systemctl enable aerospike
```

---

## Using Aerospike Tools

The client node has all Aerospike tools pre-installed.

### Connect to the Client

```bash
docker exec -it aerospike-client bash
```

### asadm (Admin Tool)

```bash
# Connect to the cluster
asadm -h aerospike-node-1:3000

# Inside asadm, try these commands:
# info                    # Cluster overview
# info namespace          # Namespace details
# info network            # Network info
# show distribution       # Data distribution
# exit                    # Exit asadm
```

### asinfo (Info Tool)

```bash
# Get cluster information
asinfo -h aerospike-node-1:3000 -v "status"

# Get build version
asinfo -h aerospike-node-1:3000 -v "build"

# Get namespace info
asinfo -h aerospike-node-1:3000 -v "namespaces"
```

### aql (Query Interface)

```bash
# Connect to cluster
aql -h aerospike-node-1:3000

# Inside aql:
# SELECT * FROM devops.workshop_data
# INSERT INTO devops.test (PK, name, value) VALUES ('key1', 'test', 123)
# exit
```

---

## Running Benchmarks

### Pre-configured Workloads

Two asbench configurations are included:

1. **insert-1m-records.yaml** - Inserts 1,000,000 records with 20 fields
2. **read-write-workload.yaml** - 80% reads, 20% updates

### Load Initial Data

```bash
# On the client node
docker exec -it aerospike-client bash

# Run the insert workload
asbench-configs/insert-1m-records.sh
```

### Run Mixed Workload

```bash
# On the client node
docker exec -it aerospike-client bash

asbench-configs/read-write-workload.sh
```

## Customization Guide

### Switching Between Community and Enterprise Edition

#### Building with Enterprise Edition

If you have an Enterprise Edition license and want to use it:

1. **Place your Enterprise package in the package directory:**

   ```bash
   # Download from Aerospike and place in package/enterprise/
   ls package/enterprise/
   # Should show: aerospike-server-enterprise_*_ubuntu24.04_*.tgz
   ```

2. **Place your feature key file:**

   ```bash
   cp /path/to/your/features.conf etc/aerospike/features.conf
   ```

3. **Rebuild with Enterprise Edition:**

   ```bash
   # Stop existing containers
   docker-compose down

   # Build with Enterprise Edition
   export AEROSPIKE_EDITION=enterprise
   docker-compose up -d --build
   ```

4. **After installation inside containers, enable the feature key:**

   ```bash
   # On each database node after running asinstall:
   sudo sed -i 's/# feature-key-file/feature-key-file/' /etc/aerospike/aerospike.conf
   ```

#### Switching Back to Community Edition

```bash
# Stop containers
docker-compose down

# Unset the environment variable (or set to community)
unset AEROSPIKE_EDITION
# Or: export AEROSPIKE_EDITION=community

# Rebuild
docker-compose up -d --build
```

#### Checking Which Edition You're Running

```bash
# Inside a container after installation:
asd --version
# Shows: "Aerospike Community Edition" or "Aerospike Enterprise Edition"
```

### Editing aerospike.conf

You can edit the configuration file either on the host or inside the container.

**Option A: Edit on host, then copy to containers**

1. Edit on the host:
   ```bash
   nano etc/aerospike/aerospike.conf
   ```

2. Copy to each container:
   ```bash
   docker exec aerospike-node-1 sudo cp ~/aerospike-config/aerospike.conf /etc/aerospike/
   docker exec aerospike-node-2 sudo cp ~/aerospike-config/aerospike.conf /etc/aerospike/
   docker exec aerospike-node-3 sudo cp ~/aerospike-config/aerospike.conf /etc/aerospike/
   ```

3. Restart Aerospike on each node:
   ```bash
   docker exec aerospike-node-1 sudo systemctl restart aerospike
   docker exec aerospike-node-2 sudo systemctl restart aerospike
   docker exec aerospike-node-3 sudo systemctl restart aerospike
   ```

**Option B: Edit directly inside a container**

1. Edit inside the container:
   ```bash
   docker exec -it aerospike-node-1 bash
   sudo nano /etc/aerospike/aerospike.conf
   sudo systemctl restart aerospike
   ```

   Note: Changes made this way are local to that container only.

### Adding/Exposing Ports

#### To expose ports to the host machine:

1. **Edit `compose.yaml`:**

   Find the service you want to modify and uncomment/add the ports section:

   ```yaml
   aerospike-node-1:
     # ... other settings ...
     ports:
       - "3000:3000"   # Map host port 3000 to container port 3000
       - "3003:3003"   # Map host port 3003 to container port 3003
   ```

2. **Recreate the containers:**

   ```bash
   docker-compose down
   docker-compose up -d
   ```

#### Port mapping format: `"HOST_PORT:CONTAINER_PORT"`

Examples:
```yaml
ports:
  - "8080:80"      # Host 8080 → Container 80
  - "3000-3003:3000-3003"  # Port range
```

### Adding Additional Host Folders

1. **Edit `compose.yaml`:**

   Add a new volume under the service:

   ```yaml
   aerospike-node-1:
     volumes:
       # Existing volumes...
       - ./my-scripts:/home/aero_devops/scripts  # Add this line
   ```

2. **Create the folder on host:**

   ```bash
   mkdir -p my-scripts
   ```

3. **Recreate containers:**

   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Rebuilding After Dockerfile Changes

If you modify a Dockerfile, you must rebuild:

```bash
# Rebuild all images (base image will be rebuilt first automatically)
docker compose build

# Or rebuild specific image
docker compose build aerospike-node-1

# Then restart
docker compose down
docker compose up -d
```

**Build Order:**
- `base-image` is built first (shared base with systemd and common packages)
- `aerospike-node-1` builds next (uses base-image, creates shared database image)
- `aerospike-node-2` and `aerospike-node-3` reuse the database image (no rebuild needed)
- `aerospike-client` builds last (uses base-image)

**Note:** If you modify `base.Dockerfile`, all dependent images will be rebuilt automatically.

### Adding More Database Nodes

1. **Copy an existing node definition in `compose.yaml`:**

   ```yaml
   aerospike-node-4:
     image: devops-workshop-aerospike-node:latest  # Reuses the shared database image
     pull_policy: never
     container_name: aerospike-node-4
     hostname: aerospike-node-4
     privileged: true
     stdin_open: true
     tty: true
     cgroup_parent: ""
     tmpfs:
       - /run
       - /run/lock
       - /tmp
     volumes:
       - /sys/fs/cgroup:/sys/fs/cgroup:rw
       - ./shared:/home/aero_devops/shared
       - ./etc/aerospike:/home/aero_devops/aerospike-config:ro
       - node4-data:/opt/aerospike/data
     stop_signal: SIGRTMIN+3
     networks:
       devops-net:
         ipv4_address: 172.120.0.14
   ```

2. **Add the volume:**

   ```yaml
   volumes:
     # Existing volumes...
     node4-data:
       name: aerospike-node4-data
   ```

3. **Update `aerospike.conf`** to include the new mesh seed:

   ```
   mesh-seed-address-port aerospike-node-4 3002
   ```

4. **Rebuild and restart:**

   ```bash
   docker-compose up -d --build
   ```

---

## Troubleshooting

### Container Won't Start

```bash
# Check logs
docker-compose logs aerospike-node-1

# Check if systemd is working
docker exec aerospike-node-1 systemctl status
```

### Aerospike Won't Start

```bash
# Check Aerospike logs
docker exec aerospike-node-1 cat /var/log/aerospike/aerospike.log

# Check configuration syntax
docker exec aerospike-node-1 asd --config-file /etc/aerospike/aerospike.conf --foreground
```

### Nodes Can't Form Cluster

```bash
# Test connectivity
docker exec aerospike-client ping aerospike-node-1
docker exec aerospike-client ping aerospike-node-2
docker exec aerospike-client ping aerospike-node-3

# Check mesh ports
docker exec aerospike-node-1 netstat -tlnp | grep 3002

# Verify cluster name matches in all configs
grep cluster-name /etc/aerospike/aerospike.conf
```

### Permission Issues

```bash
# Fix ownership
docker exec -u root aerospike-node-1 chown -R aero_devops:root /var/log/aerospike /var/run/aerospike /opt/aerospike
```

### Systemctl Not Working

Ensure containers are running with `--privileged` (already set in compose.yaml):

```bash
docker exec aerospike-node-1 systemctl status
```

### Reset Everything

```bash
# Stop and remove containers, networks, volumes
docker-compose down -v

# Rebuild from scratch
docker-compose up -d --build
```

---

## Cleanup

### Stop All Containers

```bash
docker-compose stop
```

### Stop and Remove Containers

```bash
docker-compose down
```

### Remove Everything (Including Data)

```bash
# Remove containers, networks, and volumes
docker-compose down -v

# Also remove images
docker-compose down -v --rmi all
```

### Clean Up Docker System

```bash
# Remove unused images, containers, volumes
docker system prune -a --volumes
```

---

## Additional Resources

- [Aerospike Documentation](https://docs.aerospike.com/)
- [Aerospike Tools Reference](https://docs.aerospike.com/tools)
- [asbench Documentation](https://docs.aerospike.com/tools/asbench)
- [Aerospike Configuration Reference](https://docs.aerospike.com/reference/configuration)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## Quick Reference Card

| Task | Command |
|------|---------|
| Start environment | `docker-compose up -d` |
| Stop environment | `docker-compose down` |
| Rebuild images | `docker-compose build` |
| View logs | `docker-compose logs -f` |
| Access node 1 | `docker exec -it aerospike-node-1 bash` |
| Access client | `docker exec -it aerospike-client bash` |
| Start Aerospike | `sudo systemctl start aerospike` |
| Stop Aerospike | `sudo systemctl stop aerospike` |
| Check cluster | `asadm -h aerospike-node-1:3000` |
| Run benchmark | `asbench -c ~/asbench-configs/insert-1m-records.yaml` |

