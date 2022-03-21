FROM artifactory.primekey.com/con-develop-container/primekey/hsm-driver-base

LABEL maintainer="Bastian Fredriksson"

USER 0:0
WORKDIR /

RUN microdnf install tar && \
    microdnf install python3-pip && \
    pip3 install jinja2-cli 

COPY ./PrimusAPI_PKCS11-X-*-rhel8-x86_64.tar.gz /root
COPY ./start.sh /usr/bin
COPY ./primus.cfg.j2 /root

RUN tar -xf /root/PrimusAPI_PKCS11-X-*-rhel8-x86_64.tar.gz && \
    rm /root/PrimusAPI_PKCS11-X-*-rhel8-x86_64.tar.gz && \
    ln -s /usr/local/primus/bin/ppin /usr/bin/ppin && \
    ln -s /usr/local/primus/lib/libprimusP11.so.1 /usr/lib64/libprimusP11.so && \
    ln -s /usr/local/primus/lib/libprimusP11.so.1 /usr/lib64/libprimusP11.so.1 && \
    chmod +x /usr/bin/start.sh

# Required by hsm-driver-base
ENV HSM_PKCS11_LIBRARY=/usr/local/primus/lib/libprimusP11.so
VOLUME /opt/primekey/p11proxy-client

EXPOSE 7121
ENV PKCS11_DAEMON_SOCKET="tcp://0.0.0.0:7121"

CMD /usr/bin/start.sh