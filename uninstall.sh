#!/bin/bash

ipath=/usr/share/graphs1090

mv /etc/collectd/collectd.conf.graphs1090 /etc/collectd/collectd.conf &>/dev/null
rm -f /etc/cron.d/cron-graphs1090

lighty-disable-mod graphs1090 >/dev/null

apt-get remove -y $(ls $ipath/installed)

systemctl restart collectd
rm -r $ipath


echo Uninstall finished
