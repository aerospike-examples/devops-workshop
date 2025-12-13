# =============================================================================
# Aerospike Database Node - Workshop VM
# =============================================================================
# This Dockerfile creates a VM-like container with:
# - Ubuntu 24.04 with systemd support (for systemctl commands)
# - Aerospike Server package (Community or Enterprise, not installed/running)
# - Pre-configured directories and permissions
#
# Build Arguments:
#   AEROSPIKE_EDITION: "community" (default) or "enterprise"
#
# For Enterprise Edition:
#   1. Place your package in package/enterprise/
#   2. Build with: AEROSPIKE_EDITION=enterprise
# =============================================================================

FROM base-image

ARG TARGETPLATFORM
ARG AEROSPIKE_EDITION=community
ARG AEROSPIKE_VERSION=8.1.0.1
ARG TOOLS_VERSION=12.0.2

ENV AEROSPIKE_EDITION=${AEROSPIKE_EDITION}

# -----------------------------------------------------------------------------
# Install database-specific packages
# -----------------------------------------------------------------------------
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        libldap-common && \
    apt-get autoremove -y --purge && \
    rm -rf /var/lib/apt/lists/*

# Create required Aerospike directories
RUN mkdir -p /var/log/aerospike \
             /var/run/aerospike \
             /opt/aerospike/data \
             /opt/aerospike/smd

# -----------------------------------------------------------------------------
# Download or copy Aerospike Server package
# -----------------------------------------------------------------------------
SHELL ["/bin/bash", "-c"]

# Copy enterprise packages if they exist (will be empty for community builds)
COPY package/ ${HOME}/package-pkg/

RUN if [[ "$TARGETPLATFORM" == *"arm64"* ]] || [[ "$(uname -m)" == "aarch64" ]]; then \
        ARCH="aarch64"; \
    else \
        ARCH="x86_64"; \
    fi && \
    echo "Building for ${AEROSPIKE_EDITION^} edition ${AEROSPIKE_VERSION} (${ARCH})..." && \
    if [[ -f ${HOME}/package-pkg/aerospike-server-${AEROSPIKE_EDITION}_${AEROSPIKE_VERSION}_tools-${TOOLS_VERSION}_ubuntu24.04_${ARCH}.tgz ]]; then \
        echo "Using ${AEROSPIKE_EDITION^} Edition from local package..." && \
        mv ${HOME}/package-pkg/aerospike-server-${AEROSPIKE_EDITION}_${AEROSPIKE_VERSION}_tools-${TOOLS_VERSION}_ubuntu24.04_${ARCH}.tgz ${HOME}/ 2>/dev/null || true; \
    else \
        echo "Downloading ${AEROSPIKE_EDITION^} Edition ${AEROSPIKE_VERSION} (${ARCH})..." && \
        wget -q "https://download.aerospike.com/artifacts/aerospike-server-${AEROSPIKE_EDITION}/${AEROSPIKE_VERSION}/aerospike-server-${AEROSPIKE_EDITION}_${AEROSPIKE_VERSION}_tools-${TOOLS_VERSION}_ubuntu24.04_${ARCH}.tgz" \
                -O ${HOME}/aerospike-server-${AEROSPIKE_EDITION}_${AEROSPIKE_VERSION}_tools-${TOOLS_VERSION}_ubuntu24.04_${ARCH}.tgz; \
    fi && \
    rm -rf ${HOME}/package-pkg

# -----------------------------------------------------------------------------
# Set permissions
# -----------------------------------------------------------------------------
RUN chown -R ${WORKSHOP_UID}:root /var/log/aerospike \
                                  /var/run/aerospike \
                                  /opt/aerospike
