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

FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Remove default ubuntu user (UID 1000 conflict)
RUN touch /var/mail/ubuntu && \
    chown ubuntu /var/mail/ubuntu && \
    userdel -r ubuntu

USER root

ARG TARGETPLATFORM
ARG WORKSHOP_USER=aero_devops
ARG WORKSHOP_UID=1000
ARG AEROSPIKE_EDITION=community
ARG AEROSPIKE_VERSION=8.1.0.1
ARG TOOLS_VERSION=12.0.2

ENV HOME=/home/${WORKSHOP_USER} \
    SHELL=/bin/bash \
    AEROSPIKE_EDITION=${AEROSPIKE_EDITION}

# Create workshop user
RUN useradd -l -m -s /bin/bash -N -u "${WORKSHOP_UID}" "${WORKSHOP_USER}"

WORKDIR /home/${WORKSHOP_USER}

# -----------------------------------------------------------------------------
# Install systemd and required packages
# -----------------------------------------------------------------------------
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
        systemd \
        systemd-sysv \
        dbus \
        dbus-user-session \
        wget \
        curl \
        software-properties-common \
        build-essential \
        vim \
        nano \
        less \
        iproute2 \
        iputils-ping \
        net-tools \
        less \
        sudo \
        ca-certificates \
        python3 \
        libldap-common && \
    apt-get autoremove -y --purge && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Configure systemd for container operation
# -----------------------------------------------------------------------------
RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
    /lib/systemd/system/systemd-update-utmp*

# Create required Aerospike directories
RUN mkdir -p /var/log/aerospike \
             /var/run/aerospike \
             /opt/aerospike/data \
             /opt/aerospike/smd

# -----------------------------------------------------------------------------
# Download or copy Aerospike Server package
# -----------------------------------------------------------------------------
# For Community Edition: Download from Aerospike
# For Enterprise Edition: Copy from local package/enterprise/ directory
SHELL ["/bin/bash", "-c"]

# Copy enterprise packages if they exist (will be empty for community builds)
COPY package/enterprise/ ${HOME}/enterprise-pkg/

RUN if [[ "$TARGETPLATFORM" == *"arm64"* ]] || [[ "$(uname -m)" == "aarch64" ]]; then \
        ARCH="aarch64"; \
    else \
        ARCH="x86_64"; \
    fi && \
    echo "Building for ${AEROSPIKE_EDITION} edition (${ARCH})..." && \
    if [[ "${AEROSPIKE_EDITION}" == "enterprise" ]]; then \
        echo "Using Enterprise Edition from local package..." && \
        mv ${HOME}/enterprise-pkg/*${ARCH}*.tgz ${HOME}/ 2>/dev/null || \
        (echo "ERROR: Enterprise package not found for ${ARCH}. Place it in package/enterprise/" && exit 1); \
    else \
        echo "Downloading Community Edition ${AEROSPIKE_VERSION}..." && \
        wget -q "https://download.aerospike.com/artifacts/aerospike-server-community/${AEROSPIKE_VERSION}/aerospike-server-community_${AEROSPIKE_VERSION}_tools-${TOOLS_VERSION}_ubuntu24.04_${ARCH}.tgz" \
             -O ${HOME}/aerospike-server-community_${AEROSPIKE_VERSION}_tools-${TOOLS_VERSION}_ubuntu24.04_${ARCH}.tgz; \
    fi && \
    rm -rf ${HOME}/enterprise-pkg

# -----------------------------------------------------------------------------
# Set permissions
# -----------------------------------------------------------------------------
RUN echo "${WORKSHOP_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN chown -R ${WORKSHOP_UID}:root ${HOME} \
                                  /var/log/aerospike \
                                  /var/run/aerospike \
                                  /opt/aerospike

# -----------------------------------------------------------------------------
# Systemd configuration
# -----------------------------------------------------------------------------
VOLUME ["/sys/fs/cgroup"]

STOPSIGNAL SIGRTMIN+3

CMD ["/lib/systemd/systemd"]
