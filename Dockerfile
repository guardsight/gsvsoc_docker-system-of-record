FROM ubuntu:18.04
MAINTAINER Nathan Coats <ncoats@guardsight.com>

RUN apt-get update && apt-get install -y wget gnupg2 nano curl net-tools

ADD Release.key /tmp/Release.key
RUN /usr/bin/apt-key add /tmp/Release.key

RUN echo deb http://download.opensuse.org/repositories/home:/laszlo_budai:/syslog-ng/xUbuntu_18.04 ./ > /etc/apt/sources.list.d/syslog-ng.list

RUN apt-get update && apt-get install -y syslog-ng syslog-ng-core syslog-ng-mod-java-http syslog-ng-mod-elastic syslog-ng-mod-java-common-lib syslog-ng-mod-java syslog-ng-mod-json

RUN groupadd -g 1001 logs
RUN useradd -u 1001 -g 1001 logs

ADD syslog-ng.conf /etc/syslog-ng/syslog-ng.conf
ADD conf.d/* /etc/syslog-ng/conf.d/

ADD /cronjobs/daily/* /etc/cron.daily/

RUN chmod +x /etc/cron.daily/GSVSOC-*

EXPOSE 514/udp
EXPOSE 601/tcp

WORKDIR /logs/HOSTS

HEALTHCHECK --interval=2m --timeout=3s --start-period=30s CMD /usr/sbin/syslog-ng-ctl stats || exit 1

ENTRYPOINT ["/usr/sbin/syslog-ng", "-F"]