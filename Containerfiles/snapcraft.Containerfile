FROM ubuntu:24.04

LABEL org.opencontainers.image.description="snapcraft base24 image by MediaArea.Net \
This image is entended to work the same way as the official ghcr.io/canonical/snapcraft:8_core24 image"
LABEL org.opencontainers.image.authors="info@mediaarea.net"

ARG ARCH=amd64
ARG CORE=core24
ARG CHANNEL=stable

WORKDIR /project

RUN DEBIAN_FRONTEND=noninteractive apt-get -y update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install curl jq squashfs-tools snapd locales git binutils

RUN locale-gen C.UTF-8

RUN mkdir -p /snap/${CORE} /snap/snapcraft
RUN curl -L $(curl -H "X-Ubuntu-Series: 16" -H "X-Ubuntu-Architecture:${ARCH}" "https://api.snapcraft.io/api/v1/snaps/details/${CORE}" | jq .download_url -r) --output ${CORE}.snap
RUN unsquashfs -d /snap/${CORE}/current ${CORE}.snap || true

RUN curl -L $(curl -H "X-Ubuntu-Series: 16" -H "X-Ubuntu-Architecture:${ARCH}" "https://api.snapcraft.io/api/v1/snaps/details/snapcraft?channel=${CHANNEL}" | jq .download_url -r) --output snapcraft.snap
RUN unsquashfs -d /snap/snapcraft/current snapcraft.snap

# If these directories are missing, snapcraft will raise SnapcraftDataDirectoryMissingError error
RUN mkdir -p /snap/snapcraft/current/lib/python3.12/site-packages/keyrings /snap/snapcraft/current/lib/python3.12/site-packages/extensions /snap/snapcraft/current/lib/python3.12/site-packages/schema

ENV SNAPCRAFT_BUILD_ENVIRONMENT="host"
ENV LC_ALL="C.UTF-8"

ENTRYPOINT ["/snap/snapcraft/current/bin/python3", "-m", "snapcraft", "pack"]
