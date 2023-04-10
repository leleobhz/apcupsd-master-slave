FROM registry.access.redhat.com/ubi9-minimal:latest

LABEL "creator"="Scott Ueland (https://github.com/bnhf)"
LABEL "mantainer"="Leonardo Amaral (https://github.com/leleobhz)"

ENV LANG=C.UTF-8

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm https://dl.rockylinux.org/pub/rocky/9/AppStream/x86_64/os/Packages/l/libusb-0.1.7-5.el9.$(rpm --eval '%{_arch}').rpm \
 && microdnf --setopt=tsflags=nodocs --setopt=install_weak_deps=0 -y install tzdata apcupsd dbus-tools \
 && microdnf -y remove epel-release \
 && rm -rf /var/cache/yum /var/lib/dnf \
 && mkdir /opt/apcupsd \
 && mv /etc/apcupsd/* /opt/apcupsd

COPY scripts /opt/apcupsd
COPY start.sh /

# Add Tini
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
RUN chmod +x /tini /start.sh

ENTRYPOINT ["/tini", "--"]
CMD ["/start.sh"]
