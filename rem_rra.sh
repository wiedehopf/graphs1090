#!/bin/bash
if [ -z $1 ]
then
	exit 1
fi
target=/tmp/rra

cp -r -T $1 /tmp/rra

if ! pgrep collectd; then
	exit 1
fi
systemctl stop collectd

average=" \
	dump1090_dbfs-quart1.rrd \
	dump1090_dbfs-median.rrd \
	dump1090_dbfs-quart3.rrd \
	dump1090_dbfs-noise.rrd \
	dump1090_dbfs-signal.rrd \
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
	dump1090_range-median_978.rrd \
	dump1090_range-quart1_978.rrd \
	dump1090_range-quart3_978.rrd \
	dump1090_dbfs-quart1_978.rrd \
	dump1090_dbfs-median_978.rrd \
	dump1090_dbfs-quart3_978.rrd \
	dump1090_dbfs-signal_978.rrd \
	"

#	dump1090_dbfs-min_signal.rrd \
#	dump1090_dbfs-min_signal_978.rrd \
#	dump1090_range-minimum.rrd \
#	dump1090_range-minimum_978.rrd \
#	dump1090_dbfs-peak_signal_978.rrd \
#	dump1090_dbfs-peak_signal.rrd \
# removing average has issues when redoing the database format, don't use min / max only
minimum=" \
	"
maximum=" \
	"
rem_min="
	dump1090_aircraft-recent.rrd \
	dump1090_aircraft-recent_978.rrd \
	dump1090_gps-recent.rrd \
	dump1090_gps-recent_978.rrd \
	dump1090_mlat-recent.rrd \
	dump1090_tisb-recent.rrd \
	dump1090_tisb-recent_978.rrd \
	"


cd $target/dump1090-localhost

for i in $average
do
	rrdtool tune $i $(rrdtool info $i | tac | grep 'MIN\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done

for i in $minimum
do
	rrdtool tune $i $(rrdtool info $i | tac | grep 'AVERAGE\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done

for i in $maximum
do
	rrdtool tune $i $(rrdtool info $i | tac | grep 'AVERAGE\|MIN' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done

for i in $rem_min
do
	rrdtool tune $i $(rrdtool info $i | tac | grep 'MIN' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done

cd $target
average=$(find system_stats | tail -n+2)
for i in $average
do
	rrdtool tune $i $(rrdtool info $i | tac | grep 'MIN\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done
average=$(find aggregation-cpu-average | tail -n+2)
for i in $average
do
	rrdtool tune $i $(rrdtool info $i | tac | grep 'MIN\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done
average=$(find interface* | tail -n+2)
for i in $average
do
	rrdtool tune $i $(rrdtool info $i | tac | grep 'MIN\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done
average=$(find disk* | tail -n+2)
for i in $average
do
	rrdtool tune $i $(rrdtool info $i | tac | grep 'MIN\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done
average=$(find df-root | tail -n+2)
for i in $average
do
	rrdtool tune $i $(rrdtool info $i | tac | grep 'MIN\|MAX' | tr -c -d '[:digit:]\n' | sed 's/^/DELRRA:/')
done


for file in $(cd /var/lib/collectd/rrd/localhost/;find | grep '\.rrd')
do
	rrdtool create -r $1/$file -t /tmp/rra/$file $1/$file
done

systemctl restart collectd
exit 0
