#!/bin/bash
set -e

TARGET=/var/lib/collectd/rrd/
RUNFOLDER=/run/collectd/

if ! [[ -f "$RUNFOLDER/readback-complete" ]]; then
    echo "readback didn't complete, no writeback of $RUNFOLDER to disk!"
    exit 1
fi

echo "writing DB from $RUNFOLDER to disk"

tar --directory "$RUNFOLDER" -cz -f "$RUNFOLDER/localhost.tar.gz" localhost

mkdir -p "$TARGET"

if [[ -f "$TARGET/localhost.tar.gz" ]] && (( $(stat -c %s "$TARGET/localhost.tar.gz") > 150000 )); then
    mv -T "$TARGET/localhost.tar.gz" "$TARGET/auto-backup-$(date +%Y-week_%V).tar.gz" &>/dev/null || true
    find "$TARGET" -name 'auto-backup-*.tar.gz' -mtime +60 -delete
fi
rm -rf "$TARGET/localhost.tar.gz"
cp -fT "$RUNFOLDER/localhost.tar.gz" "$TARGET/localhost.tar.gz"

# remove legacy stuff
rm -rf "$TARGET/graphs1090-writeback-backup1" "$TARGET/graphs1090-writeback-backup2"
# remove localhost folder as it would be used with preference in the readback instead of localhost.tar.gz
rm -rf "$TARGET/localhost"
# remove readback-complete flag
rm "$RUNFOLDER/readback-complete"
sync
