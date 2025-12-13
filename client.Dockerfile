# =============================================================================
# Aerospike Client Node - Workshop VM
# =============================================================================
# This Dockerfile creates a VM-like container with:
# - Ubuntu 24.04 with systemd support (for systemctl commands)
# - Aerospike Tools (asadm, asinfo, aql, asbench, etc.)
# - Default asbench configuration file
# =============================================================================

FROM base-image

ARG TARGETPLATFORM

# -----------------------------------------------------------------------------
# Install client-specific packages
# -----------------------------------------------------------------------------
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        gnupg \
        python3-pip \
        libreadline8t64 && \
    apt-get autoremove -y --purge && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Download and install Aerospike Tools (includes asbench)
# Version 12.0.2 supports Ubuntu 24.04
# -----------------------------------------------------------------------------
SHELL ["/bin/bash", "-c"]
RUN TOOLS_VERSION="12.0.2" && \
    if [[ "$TARGETPLATFORM" == *"arm64"* ]] || [[ "$(uname -m)" == "aarch64" ]]; then \
        ARCH="aarch64"; \
    else \
        ARCH="x86_64"; \
    fi && \
    echo "Downloading Aerospike Tools ${TOOLS_VERSION} for ${ARCH}..." && \
    cd /tmp && \
    wget -q "https://download.aerospike.com/artifacts/aerospike-tools/${TOOLS_VERSION}/aerospike-tools_${TOOLS_VERSION}_ubuntu24.04_${ARCH}.tgz" -O aerospike-tools.tgz && \
    tar -xzf aerospike-tools.tgz && \
    cd "aerospike-tools_${TOOLS_VERSION}_ubuntu24.04_${ARCH}" && \
    ./asinstall && \
    cd /tmp && \
    rm -rf aerospike-tools*

# -----------------------------------------------------------------------------
# Create asbench configuration directory
# -----------------------------------------------------------------------------
RUN mkdir -p ${HOME}/asbench-configs

# Copy asbench configuration files
COPY /asbench-configs ${HOME}/asbench-configs/

# -----------------------------------------------------------------------------
# Set permissions
# -----------------------------------------------------------------------------
RUN chown -R ${WORKSHOP_UID}:root ${HOME}/asbench-configs
