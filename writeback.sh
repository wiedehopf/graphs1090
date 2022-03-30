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

mkdir -p "$TARGET"

#tar gz localhost
TMPF="$TARGET/localhost.tar.gz.tmp"
rm -f "$TMPF"

if ! tar --directory "$RUNFOLDER" -c localhost | gzip -1 -c > "$TMPF" || ! [[ -f "$TMPF" ]]; then
    echo "FATAL: writeback failed"
    exit 1
fi

if [[ -f "$TARGET/localhost.tar.gz" ]] && (( $(stat -c %s "$TARGET/localhost.tar.gz") > 150000 )); then
    mv -f -T "$TARGET/localhost.tar.gz" "$TARGET/auto-backup-$(date +%Y-week_%V).tar.gz" &>/dev/null || true
    find "$TARGET" -name 'auto-backup-*.tar.gz' -mtime +60 -delete || true
fi

sync
mv -f "$TMPF" "$TARGET/localhost.tar.gz"

echo "writeback size on disk: $(du -sh "$TARGET/localhost.tar.gz" || true)" || true

# remove localhost folder as it would be used with preference in the readback instead of localhost.tar.gz
rm -rf "$TARGET/localhost"

# remove readback-complete flag
rm "$RUNFOLDER/readback-complete"
sync
