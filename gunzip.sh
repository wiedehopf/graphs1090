#!/bin/bash
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR
TARGET="$1"
# if no target is given assume default path
if [[ -z $TARGET ]]; then
    TARGET="/var/lib/collectd/rrd/localhost"
fi

TARGET="${TARGET%/}"

mkdir -p "$TARGET"

# current method
if [[ -f "$TARGET.tar.gz" ]]; then
    tar --overwrite --directory "$TARGET/.." -x -f "$TARGET.tar.gz"
    rm -rf "$TARGET.tar.gz"
fi

# legacy method, find shouldn't return anything.
while IFS= read -r -d '' gz; do
    rrd="${gz::-3}"
    if [[ -f "$rrd" ]] && [[ "$rrd" -ot "$gz" ]]; then
        rm -f "$gz"
    else
        gzip -f -d "$gz"
    fi
done < <(find "$TARGET" -type f -name '*.gz' -print0)
