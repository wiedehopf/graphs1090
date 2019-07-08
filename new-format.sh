#!/bin/bash

echo "This will take around 8 minutes, don't interrupt the process!"
cd /var/lib/collectd/rrd


systemctl stop collectd

date=$(date -I)

cp -T -r -n localhost $date
rm -r localhost

systemctl start collectd
sleep 60
echo 7 minutes left
sleep 60
echo 6 minutes left
sleep 60
echo 5 minutes left
sleep 60
echo 4 minutes left
sleep 60
echo 3 minutes left
sleep 60
echo 2 minutes left
sleep 60
systemctl stop collectd


for file in $(cd /var/lib/collectd/rrd/localhost/;find | grep '\.rrd')
do
	rrdtool create -r $date/$file -t localhost/$file localhost/$file
done

cp -T -r -n $date localhost
systemctl start collectd

for i in 1h 6h 24h 48h 7d 30d 90d 180d 365d;do nice /usr/share/graphs1090/graphs1090.sh $i;done

echo
echo
echo
echo "All done!"
