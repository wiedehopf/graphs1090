#!/bin/bash

ipath=/usr/share/graphs1090
systemctl stop collectd

/usr/share/graphs1090/gunzip.sh /var/lib/collectd/rrd/localhost

rm -f /etc/systemd/system/collectd.service.d/malarky.conf
rm -f /etc/systemd/system/collectd.service
mv /etc/collectd/collectd.conf.graphs1090 /etc/collectd/collectd.conf &>/dev/null
rm -f /etc/cron.d/cron-graphs1090

lighty-disable-mod graphs1090 >/dev/null

apt-get remove -y $(ls $ipath/installed)

systemctl daemon-reload
systemctl restart collectd
rm -r $ipath


echo Uninstall finished
