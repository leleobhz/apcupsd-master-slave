FROM ubuntu:latest
LABEL Greg Ewing (https://github.com/gregewing)
ENV LANG=C.UTF-8 DEBIAN_FRONTEND=noninteractive

RUN echo Starting. \
 && apt-get -q -y update \
 && apt-get -q -y install --no-install-recommends apcupsd dbus libapparmor1 libdbus-1-3 libexpat1 tzdata \
 && apt-get -q -y full-upgrade \
 && rm -rif /var/lib/apt/lists/* \
 && mkdir /opt/apcupsd \
 && mv /etc/apcupsd/* /opt/apcupsd \
 && echo Finished.

COPY scripts /opt/apcupsd
COPY start.sh /

CMD /start.sh
