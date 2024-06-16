#!/bin/bash
set -e

trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

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
    BACKUP="$TARGET/auto-backup-$(date +%Y-week_%V).tar.gz"
    # overwrite auto-backup only if it's smaller or less than 0.5 MB larger than the newly created file
    if ! [[ -f "$BACKUP" ]] || (( $(stat -c %s "$BACKUP") < $(stat -c %s "$TARGET/localhost.tar.gz") + 512 * 1024 )); then
        mv -v -f -T "$TARGET/localhost.tar.gz" "$BACKUP" &>/dev/null || true
    fi
    find "$TARGET" -name 'auto-backup-*.tar.gz' -mtime +60  -printf "Removing %P (older than 60 days)\n" -delete || true
fi

if ! sync "$TMPF"; then
    echo "writeback failed due to sync failure"
    exit 1
fi

mv -f "$TMPF" "$TARGET/localhost.tar.gz"

echo "writeback size on disk: $(du -sh "$TARGET/localhost.tar.gz" || true)" || true

# remove localhost folder as it will be outdated
if [[ -d "$TARGET/localhost" ]]; then
    if tar --directory "$TARGET" -c localhost | gzip -1 -c > "$TMPF"; then
        mv -f -T "$TMPF" "$TARGET/auto-backup-old-localhost-folder-$(date +%Y-week_%V).tar.gz" &>/dev/null || true
        rm -rf "$TARGET/localhost"
    fi
    rm -f "$TMPF"
fi

