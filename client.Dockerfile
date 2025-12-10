# =============================================================================
# Aerospike Client Node - Workshop VM
# =============================================================================
# This Dockerfile creates a VM-like container with:
# - Ubuntu 24.04 with systemd support (for systemctl commands)
# - Aerospike Tools (asadm, asinfo, aql, asbench, etc.)
# - Default asbench configuration file
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

ENV HOME=/home/${WORKSHOP_USER} \
    SHELL=/bin/bash

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
        iproute2 \
        iputils-ping \
        net-tools \
        less \
        sudo \
        ca-certificates \
        gnupg \
        python3 \
        python3-pip \
        libreadline8t64 && \
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
# Give workshop user sudo access
RUN echo "${WORKSHOP_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN chown -R ${WORKSHOP_UID}:root ${HOME}

# -----------------------------------------------------------------------------
# Systemd configuration
# -----------------------------------------------------------------------------
VOLUME ["/sys/fs/cgroup"]

STOPSIGNAL SIGRTMIN+3

# Start systemd as init process (PID 1)
CMD ["/lib/systemd/systemd"]
