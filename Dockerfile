
FROM centos:7 AS centos_base_cs

ENV container docker

RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
systemd-tmpfiles-setup.service ] || rm -f $i; done); \
rm -f /lib/systemd/system/multi-user.target.wants/*;\
rm -f /etc/systemd/system/*.wants/*;\
rm -f /lib/systemd/system/local-fs.target.wants/*; \
rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
rm -f /lib/systemd/system/basic.target.wants/*;\
rm -f /lib/systemd/system/anaconda.target.wants/*;

VOLUME [ "/sys/fs/cgroup" ]
CMD ["/usr/sbin/init"]

FROM centos_base_cs

RUN yum update && \
    yum install -y \ 
    curl \
    gpg \
    gcc \
    gcc-c++ \
    make \
    patch \
    autoconf \
    automake \
    bison \
    libffi-devel \
    libtool \
    readline-devel \
    sqlite-devel \
    zlib-devel \
    openssl-devel \
    glibc.i686 \
    libgcc.i686 \
    libstdc++.i686 \
    openssl-devel.i686 \
    wget \
    ncurses-devel \
    newt-devel \
    libxml2-devel \
    kernel-devel \
    libuuid-devel \
    ruby && \
    gem install foreman

ENV ACCEPT_EULA=Y
ENV SA_PASSWORD=**d456123789d**
ENV MSSQL_PID=Express

WORKDIR /app
COPY ./ ./

RUN curl -o /etc/yum.repos.d/mssql-server.repo https://packages.microsoft.com/config/rhel/7/mssql-server-2017.repo && \
    curl -o /etc/yum.repos.d/msprod.repo https://packages.microsoft.com/config/rhel/7/prod.repo && \
    ACCEPT_EULA=Y yum install -y mssql-server mssql-tools unixODBC-devel && \
    yum clean all && \
    mkdir -p /var/opt/mssql/backup

COPY bin/uid_entrypoint /opt/mssql-tools/bin/
ENV PATH=${PATH}:/opt/mssql/bin:/opt/mssql-tools/bin

RUN mkdir -p /var/opt/mssql/data && \
    chmod -R g=u /var/opt/mssql /etc/passwd

VOLUME /var/opt/mssql/data

RUN tar xzvf cabal_ep8_repack.tar.gz \
    && chmod +x install.sh \
    && chmod +x /app/bin/start.sh \
    && echo "Y" | ./install.sh \
    && cabal_create -s 1 \
    && echo "127.0.0.1 1433 sa ${SA_PASSWORD} $(curl ifconfig.me)" || cabal_config

RUN echo "${USER_NAME:-sqlservr}:x:$(id -u):0:${USER_NAME:-sqlservr} user:${HOME}:/sbin/nologin" >> /etc/passwd

RUN wget https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl.py -O /usr/local/bin/systemctl

EXPOSE 1433

CMD ["/app/bin/start.sh"]