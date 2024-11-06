#!/bin/bash
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

function cleanup {
    systemctl start collectd
}
trap cleanup EXIT

set -e

systemctl stop collectd

if ! [[ -f /var/lib/collectd/rrd/localhost.tar.gz ]]; then
    cd /var/lib/collectd/rrd
    tar -cz -f rrd.tar.gz localhost
fi

cd /usr/share/graphs1090/html/
mkdir -p ultrafeeder/graphs1090/rrd

if [[ -f /var/lib/collectd/rrd/localhost.tar.gz ]]; then
    cp /var/lib/collectd/rrd/localhost.tar.gz ultrafeeder/graphs1090/rrd
else
    cp /var/lib/collectd/rrd/rrd.tar.gz ultrafeeder/graphs1090/rrd
fi

zip -0 -r graphs1090-to-adsb.im.backup ultrafeeder >/dev/null
rm -rf ultrafeeder

echo
echo "All done!"
echo "Backup should be available at http://$(ip route get 1.2.3.4 | grep -m1 -o -P 'src \K[0-9,.]*')/graphs1090/graphs1090-to-adsb.im.backup"
echo
