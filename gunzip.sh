#!/bin/bash
TARGET="$1"
if [[ -z $TARGET ]]; then
    TARGET="/var/lib/collectd/rrd/localhost"
fi
while IFS= read -r -d '' gz; do
    rrd="${gz::-3}"
    if [[ -f "$rrd" ]] && [[ "$rrd" -ot "$gz" ]]; then
        rm -f "$gz"
    else
        gzip -f -d "$gz"
    fi
done < <(find $1 -type f -name '*.gz' -print0)
