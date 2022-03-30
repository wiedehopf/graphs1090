#!/bin/bash
set -e

TARGET=/var/lib/collectd/rrd
RUNFOLDER=/run/collectd

if ! [[ -f "$RUNFOLDER/readback-complete" ]]; then
    echo "readback didn't complete, no writeback of $RUNFOLDER to disk!"
    exit 1
fi

if ! [[ -d "$RUNFOLDER/localhost" ]]; then
    echo "directory $RUNFOLDER/localhost not present, collectd hasn't been running long. if collectd has been running for a bit, this condition is unexpeted!"
    exit 1
fi
echo "writing DB from $RUNFOLDER to disk"

#delete empty files (apparently sometimes collectd will create empty files and choke on them)
find "$RUNFOLDER/localhost" -size -50c -type f -delete -print | sed 's/^/File empty, deleting: /' || true

#tar gz localhost
tar --directory "$RUNFOLDER" -cz -f "$RUNFOLDER/localhost.tar.gz" localhost

mkdir -p "$TARGET"

if ! [[ -f "$RUNFOLDER/localhost.tar.gz" ]]; then
    echo "FATAL: missing file: $RUNFOLDER/localhost.tar.gz"
    exit 1
fi

if [[ -f "$TARGET/localhost.tar.gz" ]] && (( $(stat -c %s "$TARGET/localhost.tar.gz") > 150000 )); then
    mv -T "$TARGET/localhost.tar.gz" "$TARGET/auto-backup-$(date +%Y-week_%V).tar.gz" &>/dev/null || true
    find "$TARGET" -name 'auto-backup-*.tar.gz' -mtime +60 -delete
fi

cp -fT "$RUNFOLDER/localhost.tar.gz" "$TARGET/localhost.tar.gz.tmp"
sync
mv -f "$TARGET/localhost.tar.gz.tmp" "$TARGET/localhost.tar.gz"

# remove localhost folder as it would be used with preference in the readback instead of localhost.tar.gz
rm -rf "$TARGET/localhost"

# remove readback-complete flag
rm "$RUNFOLDER/readback-complete"
sync
