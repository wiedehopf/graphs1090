#!/bin/bash
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

function cleanup {
    systemctl restart collectd
}

set -e

cd /usr/share/graphs1090/html/
rm -rf /usr/share/graphs1090/html/ultrafeeder
mkdir -p ultrafeeder/graphs1090/rrd

if dpkg --print-architecture | grep 64; then
    trap cleanup EXIT
    systemctl stop collectd

    if ! [[ -f /var/lib/collectd/rrd/localhost.tar.gz ]]; then
        pushd /var/lib/collectd/rrd
        tar -cz -f rrd.tar.gz localhost
        popd
        cp /var/lib/collectd/rrd/rrd.tar.gz ultrafeeder/graphs1090/rrd/localhost.tar.gz
    else
        cp /var/lib/collectd/rrd/localhost.tar.gz ultrafeeder/graphs1090/rrd/localhost.tar.gz
    fi

else
    /usr/share/graphs1090/rrd-dump.sh /var/lib/collectd/rrd/localhost /usr/share/graphs1090/html/ultrafeeder/graphs1090/xml.tar.gz
fi
rm -f graphs1090-to-adsb.im.backup
zip -0 -r graphs1090-to-adsb.im.backup ultrafeeder >/dev/null
rm -rf ultrafeeder

echo
echo "All done!"
echo "Backup should be available at http://$(ip route get 1.2.3.4 | grep -m1 -o -P 'src \K[0-9,.]*')/graphs1090/graphs1090-to-adsb.im.backup"
echo
