#!/bin/bash
systemctl stop collectd
bash /usr/share/graphs1090/gunzip.sh

for file in $(find $1 | grep '\.rrd' | cut -d. -f1)
do
	echo "Writing $file.rrd"
	rrdtool restore $file.xml $file.rrd -f
	rm $file.xml
done

systemctl restart collectd
