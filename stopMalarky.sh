#!/bin/bash
systemctl stop collectd &>/dev/null

rm -f /etc/systemd/system/collectd.service
rm -f /etc/systemd/system/collectd.service.d/malarky.conf
sed -i -e 's?DataDir.*?DataDir "/var/lib/collectd/rrd/"?' /etc/collectd/collectd.conf

if ! grep -qs -e '^DB=' /etc/default/graphs1090; then
    echo "DB=" >>/etc/default/graphs1090
fi

sed -i -e 's#^DB=.*#DB=/var/lib/collectd/rrd#' /etc/default/graphs1090

systemctl daemon-reload

/usr/share/graphs1090/gunzip.sh /var/lib/collectd/rrd/localhost

systemctl restart collectd
systemctl restart graphs1090

rm -f /etc/cron.d/collectd_to_disk

touch /usr/share/graphs1090/noMalarky

echo ---------
echo write reducing measures disabled!
echo ---------
