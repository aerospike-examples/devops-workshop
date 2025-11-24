FROM ubuntu:24.04 as build

# remove default ubuntu user
RUN touch /var/mail/ubuntu && \
    chown ubuntu /var/mail/ubuntu && \
    userdel -r ubuntu

USER root

ARG WORKSHOP_USER=aero_devops
ARG WORKSHOP_UID=1000

ENV HOME=/home/${WORKSHOP_USER} \
    SHELL=/bin/bash

RUN useradd -l -m -s /bin/bash -N -u "${WORKSHOP_UID}" "${WORKSHOP_USER}"

WORKDIR /home/${WORKSHOP_USER}

# basic setup
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends wget curl software-properties-common build-essential vim nano && \
    apt-get autoremove -y --purge && \
    rm -rf /var/lib/apt/lists/*

RUN chown -R ${WORKSHOP_UID} ${HOME}

USER ${WORKSHOP_USER}