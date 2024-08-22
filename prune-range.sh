#!/bin/bash

if [[ -z $2 ]] || (( $2 < 50 )); then
    echo "the 2nd argument must be the range limit in nmi and must be greater than 50"
    exit 1
fi

limit=$(( $2 * 1852 ))

DB=/var/lib/collectd/rrd
source /etc/default/graphs1090

if [[ $1 == 978 ]]; then
    rrdfile="${DB}/localhost/dump1090-localhost/dump1090_range-max_range_978.rrd"
elif [[ $1 == 1090 ]]; then
    rrdfile="${DB}/localhost/dump1090-localhost/dump1090_range-max_range.rrd"
else
    echo "the 1st argument must be either 1090 or 978, depending on which max range graph you want to prune"
    exit 1
fi

tmpfile="${DB}/.prune-range.rrd"
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
fi

