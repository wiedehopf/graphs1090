#!/bin/bash
target=$1
if [ -z $1 ]
then
	exit 1
fi

if ! pgrep collectd; then
	exit 1
fi
systemctl stop collectd

average="dump1090_dbfs-quart1.rrd \
	dump1090_dbfs-median.rrd \
	dump1090_dbfs-quart3.rrd \
	dump1090_dbfs-noise.rrd \
	dump1090_cpu-airspy.rrd \
	dump1090_cpu-background.rrd \
	dump1090_cpu-demod.rrd \
	dump1090_cpu-reader.rrd \
	dump1090_messages-local_accepted_0.rrd \
	dump1090_messages-local_accepted_1.rrd \
	dump1090_messages-remote_accepted_0.rrd \
	dump1090_messages-remote_accepted_1.rrd \
	dump1090_messages-strong_signals.rrd \
	dump1090_tracks-all.rrd \
	dump1090_tracks-single_message.rrd \
	dump1090_range-median.rrd \
	dump1090_range-quart1.rrd \
	dump1090_range-quart3.rrd \
	"

cd $target/dump1090-localhost
for i in $average
do
	rrdtool tune $i $(rrdtool info $i | grep 'MIN\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done

cd $target
average=$(find system_stats | tail -n+2)
for i in $average
do
	rrdtool tune $i $(rrdtool info $i | grep 'MIN\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done
average=$(find aggregation-cpu-average | tail -n+2)
for i in $average
do
	rrdtool tune $i $(rrdtool info $i | grep 'MIN\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done
average=$(find interface* | tail -n+2)
for i in $average
do
	rrdtool tune $i $(rrdtool info $i | grep 'MIN\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done
average=$(find disk* | tail -n+2)
for i in $average
do
	rrdtool tune $i $(rrdtool info $i | grep 'MIN\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done
average=$(find df-root | tail -n+2)
for i in $average
do
	rrdtool tune $i $(rrdtool info $i | grep 'MIN\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done


systemctl restart collectd
exit 0
