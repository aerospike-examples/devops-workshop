FROM ubuntu:24.04 as build

# remove default ubuntu user
RUN touch /var/mail/ubuntu && \
    chown ubuntu /var/mail/ubuntu && \
    userdel -r ubuntu

USER root

ARG TARGETPLATFORM
ARG WORKSHOP_USER=aero_devops
ARG WORKSHOP_UID=1000

ENV HOME=/home/${WORKSHOP_USER}

RUN useradd -l -m -s /bin/bash -N -u "${WORKSHOP_UID}" "${WORKSHOP_USER}"

WORKDIR /home/${WORKSHOP_USER}

# basic setup
RUN mkdir -p /var/log/aerospike /var/run/aerospike /etc/aerospike && \
    apt-get update -y && \
    apt-get install -y --no-install-recommends wget curl software-properties-common build-essential vim nano less && \
    apt-get autoremove -y --purge && \
    rm -rf /var/lib/apt/lists/*

COPY /etc/aerospike /etc/aerospike/
COPY /package ${HOME}/

# find target and keep only one install file
SHELL ["/bin/bash", "-c"]
RUN echo ${TARGETPLATFORM}
RUN if [[ "$TARGETPLATFORM" == *"linux/amd64"* ]]; then \
        rm *aarch64*; \
    elif [[ "$TARGETPLATFORM" == *"linux/arm64"* ]]; then \
        rm *x86_64*; \
    fi

RUN chown -R ${WORKSHOP_UID} ${HOME} /var/log/aerospike /var/run/aerospike /etc/aerospike

FROM ubuntu:24.04 as final

USER root

ARG WORKSHOP_USER=aero_devops

ENV HOME=/home/${WORKSHOP_USER} \
    SHELL=/bin/bash

WORKDIR /

# Load data
COPY --from=build . /

WORKDIR ${HOME}
USER ${WORKSHOP_USER}