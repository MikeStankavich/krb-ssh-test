#!/usr/bin/env bash
DEBIAN_FRONTEND=noninteractive
apt-get -y install ntp

service ntp stop
grep -s "server $1" || sed -i "/server $1/d" /etc/ntp.conf
sed -i "s/^server/# server/" /etc/ntp.conf
sed -i "/server ntp\.ubuntu\.com/a server $1" /etc/ntp.conf
ntpdate $1
service ntp start