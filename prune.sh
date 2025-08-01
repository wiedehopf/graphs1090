#!/bin/bash

DB=/var/lib/collectd/rrd
source /etc/default/graphs1090

if [[ -n "$1" ]]; then
    rrdfile="$1"
else
    echo "the 1st argument must be the rrd file to be pruned"
    exit 1
fi

if [[ -n $2 ]]; then
    limit="$2"
else
    echo "the 2nd argument must be value beyond the pruning is done, this value is often different from graph values"
    exit 1
fi

tmpfile="${rrdfile}.prune.rrd"

prune_py=./prune-value.py
if ! [[ -f $prune_py ]]; then
    prune_py=/usr/share/graphs1090/prune-value.py
    if ! [[ -f $prune_py ]]; then
        echo "prune-value.py not found"
        exit 1
    fi
fi

if rrdtool dump "$rrdfile" | python3 "$prune_py" "$limit" | rrdtool restore -f - "$tmpfile"; then
    mv -f "$tmpfile" "$rrdfile"
else
    rm -f "$tmpfile"
fi

