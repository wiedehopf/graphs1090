#!/bin/bash
systemctl stop collectd &>/dev/null

set -e
mkdir -p /etc/systemd/system/collectd.service.d
rm -f /etc/systemd/system/collectd.service
cp -f /usr/share/graphs1090/malarky.conf /etc/systemd/system/collectd.service.d/malarky.conf
set +e
sed -i -e 's?DataDir.*?DataDir "/run/collectd"?' /etc/collectd/collectd.conf

if ! grep -qs -e '^DB=' /etc/default/graphs1090; then
    echo "DB=" >>/etc/default/graphs1090
fi

sed -i -e 's#^DB=.*#DB=/run/collectd#' /etc/default/graphs1090

systemctl daemon-reload
systemctl restart collectd
systemctl restart graphs1090

cat >/etc/cron.d/collectd_to_disk <<"EOF"
# restart collectd so data is saved to disk
42 23 * * * root /bin/systemctl restart collectd
EOF

# remove legacy stuff
rm -rf "$TARGET/graphs1090-writeback-backup1" "$TARGET/graphs1090-writeback-backup2"

rm -f /usr/share/graphs1090/noMalarky

echo ---------
echo write reducing measures enabled!
echo ---------
