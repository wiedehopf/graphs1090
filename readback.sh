#/bin/bash
set -e
DBFOLDER=/var/lib/collectd/rrd
RUNFOLDER=/run/collectd
echo "copying DB from disk to $RUNFOLDER"

if [[ -d "$DBFOLDER/localhost" ]]; then
    # legacy method
    cp -aT "$DBFOLDER/localhost" "$RUNFOLDER/localhost"
else
    cp "$DBFOLDER/localhost.tar.gz" "$RUNFOLDER/localhost.tar.gz" || true
fi

/usr/share/graphs1090/gunzip.sh "$RUNFOLDER/localhost"

rm -rf "$RUNFOLDER/localhost.tar.gz"
