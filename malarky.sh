cp -f /usr/share/graphs1090/git/malarky.service /etc/systemd/system/collectd.service || exit
sed -i -e 's?DataDir.*?DataDir "/run/collectd"?' /etc/collectd/collectd.conf
sed -i -e '$d' /etc/default/graphs1090
echo "DB=/run/collectd" >>/etc/default/graphs1090
systemctl daemon-reload
systemctl restart collectd
systemctl restart graphs1090

cat >/etc/cron.d/collectd_to_disk <<"EOF"
# restart collectd so data is saved to disk
42 23 * * * root /bin/systemctl restart collectd
EOF

echo ---------
echo the malarky has come to pass!
echo ---------
