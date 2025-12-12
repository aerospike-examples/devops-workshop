# Aerospike DevOps Workshop

This repository provides a Docker-based environment to learn how to install, configure, and operate an Aerospike database cluster from scratch.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Labs](#labs) \
   4.1 [Lab 1: Manual Installation](#lab-1-manual-installation--verification) \
   4.2 [Lab 2: Diagnosis with asadm](#lab-2-diagnostics-with-asadm) \
   4.3 [Lab 3: Loading Data](#lab-3-data-load--workload) \
   4.4 [Lab 4: Failure and scaling down](#lab-4-node-removal-scale-down) \
   4.5 [Lab 5: Recovery and Scaling up](#lab-5-node-addition-scale-up)
5. [Cleanup](#cleanup)

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
- Builds the Docker images (takes 2-5 minutes first time)
- Creates the network
- Starts all 4 containers in the background

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

# Labs
## **Lab 1: Manual Installation & Verification**

**Goal:** Simulate the manual installation steps inside a database node and verify the cluster has formed correctly.

1. Verify Containers are Running (from host):  
   Confirm that all services started successfully in Step 0\.  
   ```bash
   docker compose ps
   ```

   *Success Criteria: You should see aerospike-node-1, aerospike-node-2, aerospike-node-3, and aerospike-client all with status Up.*  
2. Enter a Database Node Container:  
   We will now enter aerospike-node-1 to simulate the installation procedure.  
   ```bash   
   docker compose exec aerospike-node-1 /bin/bash
   ```

3. Simulated Aerospike Install Procedure:  
   Execute the manual steps required to install Aerospike from the package (/package directory is mounted).  
   ```bash
   # Extract the package  
   tar -xzf aerospike-*.tgz
   
   # Enter the extracted directory
   cd aerospike-server-*/
   
   # Run the installation script
   sudo ./asinstall   
   
   # Copy the customized configuration file over the default one  
   cp ../aerospike-config/aerospike.conf /etc/aerospike/aerospike.conf
   
   # 7. Restart the Aerospike service to load the new config  
   service aerospike start
   
   # 8. Exit the node container  
   exit
   ```

4. Repeat Installation for All Nodes:  
   Important: Repeat the steps (2 through 8) for aerospike-node-2 and aerospike-node-3 to simulate the full installation process across the cluster.  
   * `docker compose exec aerospike-node-2 /bin/bash`
   * `docker compose exec aerospike-node-3 /bin/bash`

5. Check the logs for cluster re-formation (from host):  
   Wait a moment after installing the last node, and then confirm the cluster successfully stabilizes.  
   ```bash
   docker logs -f aerospike-node-1
   ```

   **Note:** Confirm the logs once again show **"CLUSTER-SIZE 3"**, indicating stability after the restart.

## **Lab 2: Diagnostics with asadm**

**Goal:** Use the Aerospike Admin tool to inspect the cluster health.

1. Enter the Client Container:  
   We will run all client commands from the aerospike-client container shell.  
   ```bash
   docker compose exec aerospike-client /bin/bash
   ```
2. Connect to the cluster using asadm:  
   Inside the container shell, connect to any node.  
   ```bash
   asadm -h aerospike-node-1
   ```

3. Run Diagnostics Commands:  
   At the asadm> prompt, run the following:  
   * `info`: High-level summary of the running service.  
   * `info namespace`: Verifies our test namespace is present and configured (Replication Factor: 2).
   * `show config like replication-factor`: Show the configuration parameter (Replication Factor: 2).
   * `show statistics like used_bytes`: Check memory usage (should be low/zero).  

4. Exit asadm and container:  
   Type `exit` in asadm, then exit again to return to the host terminal.

## **Lab 3: Data Load & Workload**

**Goal:** Execute the pre-staged scripts to insert data and generate a continuous read/write workload.

1. **Enter the Client Container:**  
   ```bash
   docker compose exec aerospike-client /bin/bash
   ```
2. Insert Data (1 Million Records):  
   Execute the pre-staged script to run asbench for initial data load.  
   ```bash
   ./asbench-configs/insert-1m-records.sh
   ```

**Note:** This script inserts 1,000,000 records. Observe the throughput (Ops/sec) as data is loaded.  

3. Verify Data:  
   Quickly check the cluster statistics to see the object count is around 1,000,000.  

   ```bash
   docker compose exec aerospike-client asadm -h aerospike-node-1 
   asadm> show statistics like "objects" -flip
   asadm> exit
   ```

4. Sample the Data:  
   Sample some data to see how the records look like.

   ```bash
   docker compose exec aerospike-client aql -h aerospike-node-1 
   aql> set output raw
   sql> select * from devops.testset limit 5
   aql> exit
   ```

5. **Generate Read/Write Workload:** Execute the script to start a continuous, mixed read/write workload (66% Read / 34% Update). **Keep this terminal window open.**  
   docker compose exec aerospike-client /bin/bash

   *Run the script inside the opened shell:*  
   ```bash
   ./asbench-configs/read-write-workload.sh 
   ```

   **Keep Workload Running:** This workload will serve as the continuous background load for the next labs.

6. **Show the Throughput on the Servers:**
   ```bash
   docker compose exec aerospike-client asadm -h aerospike-node-1 
   asadm> watch show latencies
   ```

## **Lab 4: Node Removal (Scale Down)**

**Goal:** Simulate a node failure (scaling down) and observe the cluster's response under load.

1. Kill a Node (Failure Simulation):  
   Open a new terminal window on your host machine and stop Node 2\.  
   ```bash
   docker compose stop aerospike-node-2
   ```
   **Observe:** Watch the performance in the Lab 3 terminal—throughput should drop as the cluster handles the failure.  
2. Observe Impact (Under-Replication):  
   Enter the client container in yet another terminal and check the cluster state immediately.  
   ```bash
   docker compose exec aerospike-client asadm -h aerospike-node-1 
   asadm> info
   ```

   * **Discussion:** 
      * The cluster_size is now 2. 
      * The surviving nodes (aerospike-node-1 and aerospike-node-3) still hold all data copies (since RF=2), but the system is running under-replicated (`info`)
      * Examine the migrations automaticlly repopulating the nodes to RF=2 (pending migrations)
      * See the throughput across multiple (`show latencies`)
      * Observe the client continueing reading and writing seamlessly.

## **Lab 5: Node Addition (Scale Up)**

**Goal:** Restore the node (scaling up) and observe Aerospike's automatic data rebalancing (migrations) to restore full redundancy.

1. Healing (Bring the Container Back):  
   In the host terminal, start Node 2 again.  
   ```bash
   docker compose start aerospike-node-2
   ```
   **Observe:** Watch the asbench terminal—performance should slowly stabilize as the cluster heals.  

2. Start the Aerospike Service (Inside Node 2):  
   Execute a command inside the restarted node to explicitly start the Aerospike daemon.  

   ```bash
   docker compose exec aerospike-node-2 /bin/bash -c "service aerospike start"
   ```
3. Watch Migrations:  
   Return to asadm and check the cluster state and migration statistics.  

   ```bash
   docker compose exec aerospike-client asadm -h aerospike-node-1
   asadm> info
   asadm> show statistics like "migrate"
   ```
   ***Discussion:** The cluster_size should return to 3. Watch the migrate\rx and migrate_tx counters. Aerospike automatically initiates **migrations** to restore the replication-factor 2 redundancy. The counters will increase until the migration is complete.  

## **Cleanup:**
   Once the workshop is complete, stop and remove all containers.  

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

