#!/bin/bash

source /etc/default/graphs1090

# fontconfig writes stuff to that directory for no good reason
# graphs1090 is mostly used on RPis, avoiding frequent disk writes is preferred
# if this fails, no big deal either.
if ! mount | grep -qs -e /var/cache/fontconfig &>/dev/null; then
    mount -o rw,nosuid,nodev,relatime,size=32000k,mode=755 -t tmpfs tmpfs /var/cache/fontconfig &>/dev/null || true
fi

if [ -f /var/lib/collectd/rrd/localhost/dump1090-localhost/dump1090_messages-messages_978.rrd ] \
    || [ -f /var/lib/collectd/rrd/localhost/dump1090-localhost/dump1090_messages-messages_978.rrd.gz ] \
    || [ -f /run/collectd/localhost/dump1090-localhost/dump1090_messages-messages_978.rrd ]
then
    if grep -qs -e 'style="display:none"> <!-- dump978 -->' /usr/share/graphs1090/html/index.html; then
        sed -i -e 's/ style="display:none"> <!-- dump978 -->/> <!-- dump978 -->/' /usr/share/graphs1090/html/index.html
    fi
else
    if ! grep -qs -e 'style="display:none"> <!-- dump978 -->' /usr/share/graphs1090/html/index.html; then
        sed -i -e 's/panel-default"> <!-- dump978 -->/panel-default" style="display:none"> <!-- dump978 -->/' /usr/share/graphs1090/html/index.html
    fi
fi

if [[ $all_large == "yes" ]]; then
    if grep -qs -e 'flex: 50%; // all_large' /usr/share/graphs1090/html/portal.css; then
        sed -i -e 's?flex: 50%; // all_large?flex: 100%; // all_large?' /usr/share/graphs1090/html/portal.css
        sed -i -e 's?display: flex; // all_large2?display: inline; // all_large2?' /usr/share/graphs1090/html/portal.css
    fi
else
    if ! grep -qs -e 'flex: 50%; // all_large' /usr/share/graphs1090/html/portal.css; then
        sed -i -e 's?flex: 100%; // all_large?flex: 50%; // all_large?' /usr/share/graphs1090/html/portal.css
        sed -i -e 's?display: inline; // all_large2?display: flex; // all_large2?' /usr/share/graphs1090/html/portal.css
    fi
fi

if [[ $1 == "nographs" ]]; then
	exit 0
fi

# disable this for the moment
#if rrdtool info /var/lib/collectd/rrd/localhost/system_stats/memory-used.rrd | grep -qs 'MIN'; then
	#cp -T -r -n /var/lib/collectd/rrd/localhost /var/lib/collectd/rrd/rme_rra_backup
	#/usr/share/graphs1090/rem_rra.sh /var/lib/collectd/rrd/localhost/
#fi

while ! [[ -d $DB ]] && sleep 5; do
    echo Sleeping a bit, waiting for database directory / collectd to start.
    true
done

for i in 24h 8h 2h 48h 7d 14d 30d 90d 180d 365d 730d 1095d
do
	/usr/share/graphs1090/graphs1090.sh $i $1 &>/dev/null
done
