FROM ubuntu:20.04

LABEL org.opencontainers.image.description="Contains all the tools needed to run MediaArea-Utils scripts \
Tools and scripts may require additional, not included, configuration"
LABEL org.opencontainers.image.authors="info@mediaarea.net"

ARG REPOSITORY=https://github.com/MediaArea/MediaArea-Utils.git
ARG BRANCH=master

WORKDIR /data

ENV UTILS=/data/MediaArea-Utils
ENV BANG=/data/bangsh/bang

RUN DEBIAN_FRONTEND=noninteractive apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y wget \
                                                      curl \
                                                      git \
                                                      gnupg2 \
                                                      autoconf \
                                                      automake \
                                                      libtool \
                                                      pkgconf \
                                                      graphviz \
                                                      doxygen \
                                                      dos2unix \
                                                      python2 \
                                                      python-is-python2 \
                                                      python-pexpect \
                                                      python3-pip \
                                                      python3-m2crypto \
                                                      python3-setuptools \
                                                      libmariadb3 \
                                                      xz-utils \
                                                      p7zip-full \
                                                      unzip \
                                                      dpkg-dev \
                                                      debhelper \
                                                      libbz2-dev \
                                                      cmake \
                                                      txt2man \
                                                      libmagic-dev \
                                                      libglib2.0-dev \
                                                      libcurl4-openssl-dev \
                                                      libxml2-dev \
                                                      libpython3-dev \
                                                      librpm-dev \
                                                      libssl-dev \
                                                      libsqlite3-dev \
                                                      liblzma-dev \
                                                      libzstd-dev \
                                                      zlib1g-dev \
                                                      rpm \
                                                      software-properties-common

# PHP 7.3
RUN DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:ondrej/php
RUN DEBIAN_FRONTEND=noninteractive apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y php7.3-cli php7.3-mbstring php7.3-curl php7.3-xml php7.3-gd php7.3-mysql composer phpunit	
RUN DEBIAN_FRONTEND=noninteractive update-alternatives --set php /usr/bin/php7.3

#  mysql-connector-python is needed by handleOBSResults.py db plugin
RUN pip3 install mysql-connector-python

RUN curl -LO http://fr.archive.ubuntu.com/ubuntu/pool/main/a/automake-1.16/automake_1.16.5-1.3_all.deb
RUN DEBIAN_FRONTEND=noninteractive dpkg -i automake_1.16.5-1.3_all.deb

# restore bash as default shell
RUN echo dash dash/sh boolean false | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# freight
RUN git clone https://github.com/freight-team/freight.git
RUN cd freight && make install
RUN rm -fr freight

# createrepo
RUN git clone https://github.com/rpm-software-management/createrepo_c.git
RUN cd createrepo_c && git checkout d8da644c45bec1429d600c619ce4e47af5906ef8
RUN mkdir createrepo_c/build
RUN cd createrepo_c/build && cmake -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_DRPM=OFF -DWITH_ZCHUNK=OFF -DWITH_LIBMODULEMD=OFF ..
RUN cd createrepo_c/build && make install
RUN rm -fr createrepo_c

# osc
RUN git clone https://github.com/openSUSE/osc.git -b 1.9.2
RUN cd osc && ./setup.py build && ./setup.py install
RUN rm -fr osc

# bangsh
RUN git clone https://github.com/bangsh/bangsh.git

# MediaArea-Utils
RUN git clone --branch ${BRANCH} ${REPOSITORY}
RUN find MediaArea-Utils -name *.sh -exec chmod +x {} \;

CMD /bin/bash
