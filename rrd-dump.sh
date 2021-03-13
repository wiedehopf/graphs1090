#!/bin/bash
systemctl stop collectd
/usr/share/graphs1090/gunzip.sh /var/lib/collectd/rrd/localhost

for file in $(find $1 | grep '\.rrd' | cut -d. -f1)
do
	echo "Writing $file.xml"
	rrdtool dump $file.rrd $file.xml
done

systemctl restart collectd
