#!/bin/bash
set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR
if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo requires 2 parameters, directory with rrd files, directory where all the files will be placed
    exit 1
fi

systemctl stop collectd || true
/usr/share/graphs1090/gunzip.sh "$1"

tmp="$2.tmp"
rm -rf "$2" "$tmp"
mkdir -p "$tmp"
cp -r -T -f "$1" "$tmp"

systemctl restart collectd || true

for file in $(find "$tmp" | grep '\.rrd$' | sed 's/.\{4\}$//')
do
	echo "Writing $file.xml"
	rrdtool dump $file.rrd $file.xml
done

cd "$tmp"
target=$(basename $2)
tar -c -z -f "$target" *
mv "$target" "$2"
rm -rf "$tmp"

echo "$2 created:"
du -s "$2"
