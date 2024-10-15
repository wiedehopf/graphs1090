#!/bin/bash
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR
set -e
cd /usr/share/graphs1090/html/
mkdir -p ultrafeeder/graphs1090/rrd
systemctl restart collectd
cp /var/lib/collectd/rrd/localhost.tar.gz ultrafeeder/graphs1090/rrd
zip -0 -r graphs1090-to-adsb.im.backup ultrafeeder
rm -rf ultrafeeder
