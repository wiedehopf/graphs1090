#!/bin/bash
systemctl stop collectd
bash /usr/share/graphs1090/gunzip.sh

for file in $(find $1 | grep '\.rrd' | cut -d. -f1)
do
	echo "Writing $file.xml"
	rrdtool dump $file.rrd $file.xml
done

systemctl restart collectd
