#!/bin/bash

mkdir -p /run/graphs1090


if [ -f /var/lib/collectd/rrd/$1/dump1090-$2/dump1090_messages-messages_978.rrd ]
then
	sed -i -e 's/ style="display:none"> <!-- dump978 -->/> <!-- dump978 -->/' /usr/share/graphs1090/html/index.html
	sed -i -e "/sed -i -e 's\/ style=\"display/d" /usr/share/graphs1090/graphs1090.sh
else
	sed -i -e 's/panel-default"> <!-- dump978 -->/panel-default" style="display:none"> <!-- dump978 -->/' /usr/share/graphs1090/html/index.html
fi

sleep 15

for i in 1h 6h 24h 48h 7d 14d 30d 90d 180d 365d 730d 1095d
do
	/usr/share/graphs1090/graphs1090.sh $i slow
	sleep 2
done
