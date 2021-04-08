#/bin/bash
set -e
DBFOLDER=/var/lib/collectd/rrd/localhost
RUNFOLDER=/run/collectd/localhost
echo "copying DB from disk to $RUNFOLDER"
mkdir -p "$DBFOLDER"
cp -aT "$DBFOLDER" "$RUNFOLDER"

/usr/share/graphs1090/gunzip.sh "$RUNFOLDER"
