#!/bin/bash
cp -f /usr/share/graphs1090/malarky.service /etc/systemd/system/collectd.service || exit
sed -i -e 's?DataDir.*?DataDir "/run/collectd"?' /etc/collectd/collectd.conf

if ! grep -qs -e '^DB=' /etc/default/graphs1090; then
    echo "DB=" >>/etc/default/graphs1090
fi

sed -i -e 's#^DB=.*#DB=/run/collectd#' /etc/default/graphs1090

systemctl stop collectd &>/dev/null
systemctl daemon-reload
systemctl restart collectd
systemctl restart graphs1090

cat >/etc/cron.d/collectd_to_disk <<"EOF"
# restart collectd so data is saved to disk
42 23 * * * root /bin/systemctl restart collectd
EOF

rm -f /usr/share/graphs1090/noMalarky

echo ---------
echo write reducing measures enabled!
echo ---------
