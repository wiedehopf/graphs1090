#!/bin/bash

date=$(date -I)
new=/tmp/rrd-tmp

old=$1

if ! [ -d "$old" ]; then
    echo "Supplied argument is not a directory, exiting!"
    exit 1
fi
if ! [ -d /var/lib/collectd/rrd/localhost ]; then
    echo "/var/lib/collectd/rrd/localhost not found, exiting!"
    exit 1
fi


systemctl stop collectd
/usr/share/graphs1090/gunzip.sh /var/lib/collectd/rrd/localhost

cd /var/lib/collectd/rrd

cp -T -r -n localhost $date
rm -rf $new
cp -T -r localhost $new

for file in $(cd /var/lib/collectd/rrd/localhost/;find | grep '\.rrd')
do
	rrdtool create -r "$new/$file" -r "$old/$file" -t "$new/$file" "localhost/$file"
done

systemctl start collectd
systemctl restart graphs1090

echo
echo
echo
echo "All done!"
