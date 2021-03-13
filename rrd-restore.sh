#!/bin/bash
systemctl stop collectd
/usr/share/graphs1090/gunzip.sh /var/lib/collectd/rrd/localhost

for file in $(find $1 | grep '\.rrd' | cut -d. -f1)
do
	echo "Writing $file.rrd"
	rrdtool restore $file.xml $file.rrd -f
	rm $file.xml
done

systemctl restart collectd
