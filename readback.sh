#!/bin/bash
set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

DBFOLDER=/var/lib/collectd/rrd
RUNFOLDER=/run/collectd
echo "copying DB from disk to $RUNFOLDER"

fail() {
    echo "readback failed!"
    exit 1
}

success() {
    #delete empty files (apparently sometimes collectd will create empty files and choke on them)
    find "$RUNFOLDER/localhost" -size -50c -type f -delete -print | sed 's/^/File empty, deleting: /' || true

    touch "$RUNFOLDER/readback-complete"
    exit 0
}

# make sure runfolder exists just in case
mkdir -p "$RUNFOLDER"
touch "${RUNFOLDER}/.write_test" || fail

# remove data in run folder
rm -f "$RUNFOLDER/readback-complete"
rm -rf "$RUNFOLDER/localhost"

if [[ -d "$RUNFOLDER/localhost" ]]; then
    echo "couldn't remove ${RUNFOLDER}/localhost"
    fail
fi

function readback_tar() {
    if ! [[ -f "$1" ]]; then
        echo "readback of $1 aborted, file does not exit"
        return 1
    elif (( $(stat -c %s "$1") < 150000 )); then
        echo "readback of $1 aborted, file is too small"
        return 1
    fi
    if out=$(tar --overwrite --directory "$RUNFOLDER" -x -f "$1" 2>&1); then
        echo "readback of $1 was successful"
        return 0
    fi

    echo "$out"
    echo "readback of $1 failed"
    # remove possible leftover from failed readback
    rm -rf "$RUNFOLDER/localhost"
    if grep -qs -i -e 'no space left' -e 'wrote only' -e 'permission' <<< "$out"; then
        echo "FATAL: readback failed due to insufficient space or permission issue in $RUNFOLDER"
        fail
    fi
    return 1
}

function readback_folder() {
    if ! [[ -d "$1" ]]; then
        echo "readback of $1 aborted, folder does not exit"
        return 1
    fi
    if (( "$(find "$1" | wc -l)" < 9 )); then
        echo "readback of $1 aborted, folder does not contain enough files"
        return 1
    fi
    if cp -aT "$1" "$RUNFOLDER/localhost"; then
        echo "readback of $1 was successful (transitioning from non compressed dir)"
        return 0
    fi
    echo "FATAL: readback of $1 failed"
    fail
    return 1
}

current="$DBFOLDER/localhost.tar.gz"
this_week="$DBFOLDER/auto-backup-$(date +%Y-week_%V).tar.gz"
last_week="$DBFOLDER/auto-backup-$(date +%Y-week_%V -d '1 week ago').tar.gz"

if readback_tar "$current"; then
    success
elif readback_folder "$DBFOLDER/localhost"; then
    success
elif readback_tar "$this_week"; then
    success
elif readback_tar "$last_week"; then
    success
fi

fail
