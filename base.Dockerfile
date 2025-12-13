# =============================================================================
# Aerospike Workshop Base Image
# =============================================================================
# Shared base image for both database and client nodes
# Contains: Ubuntu 24.04, systemd, common packages, user setup
# =============================================================================

FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Remove default ubuntu user (UID 1000 conflict)
RUN touch /var/mail/ubuntu && \
    chown ubuntu /var/mail/ubuntu && \
    userdel -r ubuntu

USER root

ARG WORKSHOP_USER=aero_devops
ARG WORKSHOP_UID=1000

ENV HOME=/home/${WORKSHOP_USER} \
    SHELL=/bin/bash

# Create workshop user
RUN useradd -l -m -s /bin/bash -N -u "${WORKSHOP_UID}" "${WORKSHOP_USER}"

WORKDIR /home/${WORKSHOP_USER}

# -----------------------------------------------------------------------------
# Install systemd and common packages
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
        sudo \
        ca-certificates \
        python3 && \
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
# Set permissions and sudo access
# -----------------------------------------------------------------------------
RUN echo "${WORKSHOP_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R ${WORKSHOP_UID}:root ${HOME}

# -----------------------------------------------------------------------------
# Systemd configuration
# -----------------------------------------------------------------------------
VOLUME ["/sys/fs/cgroup"]

STOPSIGNAL SIGRTMIN+3

CMD ["/lib/systemd/systemd"]
