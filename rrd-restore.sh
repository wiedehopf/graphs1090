#!/bin/bash
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR
if [[ -z "$1" ]] || [[ -z "$2" ]]; then
    echo requires 2 parameters, directory with xml files, directory where the rrd files will be placed
    exit 1
fi

tmp="$1.tmp"
rm -rf "$tmp"
mkdir -p "$tmp"

cp -T -f "$1" "$tmp/$(basename $1)"
cd "$tmp"
tar -x -f "$1"

rm "$tmp/$(basename $1)"

for file in $(find "$tmp" | grep '\.rrd$' | sed 's/.\{4\}$//')
do
	echo "Writing $file.rrd"
	rrdtool restore $file.xml $file.rrd -f
	rm -f $file.xml
done

systemctl stop collectd
/usr/share/graphs1090/gunzip.sh "$2"
rm -rf "$2"
cp -r -T -f "$tmp" "$2"
systemctl restart collectd
systemctl restart graphs1090

rm -rf "$tmp"

echo "Files restored, check graphs in 2 mins!"
