FROM ubuntu:20.04
MAINTAINER Nathan Coats <ncoats@guardsight.com>

RUN apt update && apt install -y wget gnupg2 nano curl net-tools

RUN wget -qO - https://download.opensuse.org/repositories/home:/laszlo_budai:/syslog-ng/xUbuntu_20.04/Release.key | apt-key add -
RUN echo 'deb http://download.opensuse.org/repositories/home:/laszlo_budai:/syslog-ng/xUbuntu_20.04 ./' | tee --append /etc/apt/sources.list.d/syslog-ng-obs.list

RUN apt update && apt install -y --upgrade syslog-ng=3.27.1-2 syslog-ng-core=3.27.1-2 syslog-ng-mod-java-http=3.27.1-2  syslog-ng-mod-elastic=3.27.1-2  syslog-ng-mod-java-common-lib=3.27.1-2 syslog-ng-mod-java=3.27.1-2  syslog-ng-mod-json syslog-ng-mod-sql=3.27.1-2 syslog-ng-mod-mongodb=3.27.1-2

RUN groupadd -g 1111 logs
RUN useradd -u 1111 -g 1111 logs

ADD syslog-ng.conf /etc/syslog-ng/syslog-ng.conf
ADD conf.d/* /etc/syslog-ng/conf.d/

ADD cronjobs/daily/* /etc/cron.daily/

RUN chmod +x /etc/cron.daily/GSVSOC-*

EXPOSE 514/udp
EXPOSE 601/tcp

WORKDIR /logs/HOSTS

HEALTHCHECK --interval=2m --timeout=3s --start-period=30s CMD /usr/sbin/syslog-ng-ctl stats || exit 1

ENTRYPOINT ["/usr/sbin/syslog-ng", "-Fevdt"]