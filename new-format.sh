#!/bin/bash

echo "This will take around 8 minutes, don't interrupt the process!"
cd /var/lib/collectd/rrd

if ! [[ -f /usr/share/graphs1090/noMalarky ]]; then
    /usr/share/graphs1090/stopMalarky.sh
    rm -f /usr/share/graphs1090/noMalarky
fi

systemctl stop collectd
/usr/share/graphs1090/gunzip.sh /var/lib/collectd/rrd/localhost

date=$(date -I)
tmp=/tmp/rrd-tmp

cp -T -r -n localhost $date
cp -T -r localhost $tmp
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
/usr/share/graphs1090/gunzip.sh /var/lib/collectd/rrd/localhost


for file in $(cd /var/lib/collectd/rrd/localhost/; find | grep '\.rrd')
do
	rrdtool create -r $tmp/$file -t localhost/$file localhost/$file
done

cp -T -r -n $tmp localhost
systemctl start collectd

if ! [[ -f /usr/share/graphs1090/noMalarky ]]; then
    /usr/share/graphs1090/malarky.sh
fi

systemctl restart graphs1090

echo
echo
echo
echo "All done!"

read
