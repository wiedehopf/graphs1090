#/bin/bash
set -e
DBFOLDER=/var/lib/collectd/rrd/localhost
RUNFOLDER=/run/collectd/localhost
mkdir -p "$DBFOLDER"
cp -aT "$DBFOLDER" "$RUNFOLDER"

/usr/share/graphs1090/gunzip.sh "$RUNFOLDER"
