FROM alpine:3.7

LABEL maintainer="jeffreystoke <jeffctor@gmail.com>"

# use your favourite mirrors
# RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories

# install necessary packages
RUN apk add --update --no-cache \
    python3 py3-psutil \
    libelf-dev libpcap-dev \
    linux-headers bison flex \
    build-base \
    make \
    cmake \
    wget \
    tar \
    xz

# home
ENV HOME=/home/gns3
RUN adduser -h ${HOME} gns3 -D

# build gns3 server deps
ENV BUILD_DIR=${HOME}/build
RUN mkdir -p ${BUILD_DIR}
ADD ./dynamips ${BUILD_DIR}/dynamips
ADD ./iniparser ${BUILD_DIR}/iniparser 
ADD ./iouyap ${BUILD_DIR}/iouyap
ADD ./ubridge ${BUILD_DIR}/ubridge
ADD ./bin/vpcs_0.8b_Linux64 /usr/local/bin/vpcs
ADD ./container.mk ${BUILD_DIR}/Makefile
WORKDIR ${BUILD_DIR}
RUN make

# install gns3 server
ADD ./gns3server ${HOME}/server
WORKDIR ${HOME}/server
RUN python3 setup.py install
WORKDIR ${HOME}
ADD ./server.conf ${HOME}/server.conf

# add 32bit support for iou
ADD ./bin/libc-i386.tar.gz /

# add gns3 server user data folders
ENV IMAGES_DIR=/images APPLIANCES_DIR=/appliances PROJECTS_DIR=/projects
RUN mkdir -p ${IMAGES_DIR} ${APPLIANCES_DIR} ${PROJECTS_DIR} && \
    chown -R gns3:gns3 ${IMAGES_DIR} ${APPLIANCES_DIR} ${PROJECTS_DIR} ${HOME} && \
    apk del build-base make cmake wget tar xz linux-headers && \
    chmod -R a+x /usr/local/bin/ && \
    rm -rf ${BUILD_DIR} ${HOME}/server

VOLUME [ "/appliances", "/projects", "/images" ]

# expose gns3 server port
EXPOSE 3080
# expose console port
EXPOSE 5000-10000

# setup entrypoint
ADD ./scripts /
RUN chmod +x /start.sh

STOPSIGNAL SIGTERM

ENTRYPOINT [ "/start.sh" ]
