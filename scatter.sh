#!/bin/bash

# Fetch a day worth of data from the rrds
data_dir=/var/lib/graphs1090/scatter

date=$(date -I --date=yesterday)


rrdtool fetch /var/lib/collectd/rrd/localhost/dump1090-localhost/dump1090_messages-local_accepted.rrd AVERAGE -s end-1days -e midnight today -r 3m -a > /tmp/messages_l
rrdtool fetch /var/lib/collectd/rrd/localhost/dump1090-localhost/dump1090_messages-remote_accepted.rrd AVERAGE -s end-1days -e midnight today -r 3m -a > /tmp/messages_r
rrdtool fetch /var/lib/collectd/rrd/localhost/dump1090-localhost/dump1090_range-max_range.rrd MAX -s end-1days -e midnight today -r 3m -a > /tmp/range
rrdtool fetch /var/lib/collectd/rrd/localhost/dump1090-localhost/dump1090_aircraft-recent.rrd AVERAGE -s end-1days -e midnight today -r 3m -a > /tmp/aircraft


# Remove headers and extraneous :


sed -i -e 's/://' -e 's/\,/\./g' /tmp/messages_l
sed -i -e 's/://' -e 's/\,/\./g' /tmp/messages_r
sed -i -e 's/://' -e 's/\,/\./g' /tmp/range
sed -i -e 's/://' -e 's/\,/\./g' /tmp/aircraft


sed -i -e '1d;2d' /tmp/messages_l
sed -i -e '1d;2d' /tmp/messages_r
sed -i -e '1d;2d' /tmp/range
sed -i -e '1d;2d' /tmp/aircraft

# Combine files to create space separated data file for use by gnuplot


join -o 1.1 1.2 2.2 /tmp/range /tmp/messages_l > /tmp/tmp
join -o 1.1 1.2 1.3 2.2 /tmp/tmp /tmp/messages_r > /tmp/tmp1
join -o 1.2 1.3 1.4 2.2 /tmp/tmp1 /tmp/aircraft > $data_dir/$date

# some cleanup
rm -f $(find $data_dir | sort | head -n-450)
