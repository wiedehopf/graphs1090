#!/bin/bash

ipath=/usr/share/graphs1090
install=0

packages="collectd rrdtool lighttpd"
mkdir -p $ipath/installed

for i in $packages
do
	if ! $i -h &>/dev/null
	then
		install=1
		touch $ipath/installed/$i
	fi
done

if [ $install == 1 ]
then
	echo "Installing required packages: $packages"
	apt-get update
	if ! apt-get install -y $packages
	then
		echo "Failed to install required packages: $packages"
		echo "Exiting ..."
		exit 1
	fi
fi


if [ -z $1 ] || [ $1 != "test" ]
then
	cd /tmp
	if ! wget -q -O master.zip https://github.com/wiedehopf/graphs1090/archive/master.zip
	then
		echo "Unable to download files, exiting!"
		exit 1
	fi
	unzip -o master.zip
	cd graphs1090-master
fi

cp graphs1090.sh dump1090.db dump1090.py boot.sh uninstall.sh LICENSE $ipath
cp -n /etc/collectd/collectd.conf /etc/collectd/collectd.conf.graphs1090
cp collectd.conf /etc/collectd/collectd.conf
cp cron-graphs1090 /etc/cron.d/
cp -r html $ipath

cp 88-graphs1090.conf /etc/lighttpd/conf-available
lighty-enable-mod graphs1090 >/dev/null


if wget http://localhost/dump1090/data/stats.json -O /dev/null -q
then
	sed -i 's?localhost/dump1090-fa?localhost/dump1090?' /etc/collectd/collectd.conf
	echo --------------
	echo "dump1090 webaddress automatically set to http://localhost/dump1090/"
fi

systemctl daemon-reload
systemctl enable collectd &>/dev/null
systemctl restart collectd lighttpd


echo --------------
echo "All done!"
