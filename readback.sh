#/bin/bash
set -e
DBFOLDER=/var/lib/collectd/rrd
RUNFOLDER=/run/collectd
echo "copying DB from disk to $RUNFOLDER"

success() {
    #delete empty files (apparently sometimes collectd will create empty files and choke on them)
    find "$RUNFOLDER/localhost" -size -50c -type f -delete -print | sed 's/^/File empty, deleting: /' || true

    touch "$RUNFOLDER/readback-complete"
    exit 0
}


if [[ -f "$DBFOLDER/localhost.tar.gz" ]] && (( $(stat -c %s "$DBFOLDER/localhost.tar.gz") > 150000 )); then
    if tar --overwrite --directory "$RUNFOLDER" -x -f "$DBFOLDER/localhost.tar.gz"; then
        success
    else
        # damaged
        echo "file damaged, deleting: $DBFOLDER/localhost.tar.gz"
        rm -f "$DBFOLDER/localhost.tar.gz"
        exit 1
    fi
elif [[ -d "$DBFOLDER/localhost" ]] && (( "$(find "$DBFOLDER/localhost" | wc -l)" > 8 )); then
    # legacy method
    cp -aT "$DBFOLDER/localhost" "$RUNFOLDER/localhost"
elif [[ -f "$DBFOLDER/auto-backup-$(date +%Y-week_%V).tar.gz" ]] && (( $(stat -c %s "$DBFOLDER/auto-backup-$(date +%Y-week_%V).tar.gz") > 150000 )); then
    # try restoring a backup if we don't have these two other files
    cp -f "$DBFOLDER/auto-backup-$(date +%Y-week_%V).tar.gz" "$RUNFOLDER/localhost.tar.gz"
elif [[ -f "$DBFOLDER/localhost.tar.gz" ]]; then
    cp -f "$DBFOLDER/localhost.tar.gz" "$RUNFOLDER/localhost.tar.gz"
elif [[ -d "$DBFOLDER/localhost" ]]; then
    # legacy method
    cp -aT "$DBFOLDER/localhost" "$RUNFOLDER/localhost"
fi

if /usr/share/graphs1090/gunzip.sh "$RUNFOLDER/localhost"; then
    rm -rf "$RUNFOLDER/localhost.tar.gz"
else
    rm -rf "$RUNFOLDER/localhost"
    exit 1
fi

success
