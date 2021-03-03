#/bin/bash
set -e
mkdir -p /var/lib/collectd/rrd/localhost
cp -aT /var/lib/collectd/rrd/localhost /run/collectd/localhost
find /run/collectd/localhost -name '*.gz' -exec gunzip '{}' \+
