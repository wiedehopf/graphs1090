#/bin/bash
set -e
DBFOLDER=/var/lib/collectd/rrd
RUNFOLDER=/run/collectd
echo "copying DB from disk to $RUNFOLDER"

if [[ -d "$DBFOLDER/localhost" ]]; then
    # legacy method
    cp -aT "$DBFOLDER/localhost" "$RUNFOLDER/localhost"
else
    cp -f "$DBFOLDER/localhost.tar.gz" "$RUNFOLDER/localhost.tar.gz" \
        || cp -f "$DBFOLDER/auto-backup-$(date +%Y-week_%V).tar.gz" "$RUNFOLDER/localhost.tar.gz"
fi

if /usr/share/graphs1090/gunzip.sh "$RUNFOLDER/localhost"; then
    rm -rf "$RUNFOLDER/localhost.tar.gz"
else
    rm -rf "$RUNFOLDER/localhost"
    exit 1
fi

