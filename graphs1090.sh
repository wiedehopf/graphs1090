#!/bin/bash

DOCUMENTROOT=/run/graphs1090

DB=/var/lib/collectd/rrd
# settings in /etc/default/graphs1090 will overwrite the DB directory

renice -n 19 -p $$

trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

mult() {
	echo $1 $2 | LC_ALL=C awk '{printf "%.9f", $1 * $2}'
}
div() {
	echo $1 $2 | LC_ALL=C awk '{printf "%.9f", $1 / $2}'
}

TEMP_MULTIPLIER=1000

lwidth=1096
#1096 or 960
lheight=235
swidth=619
sheight=324

font_size=10.0
graph_size=default

# default colorscheme
colors=""

CANVAS=FFFFFF

LGREEN=7de87d
GREEN=32CD32
DGREEN=228B22

LBLUE=4f59e3
BLUE=0011EE
ABLUE=0022DD
DBLUE=0033AA

LCYAN=29a7e6
CYAN=00A0F0

RED=E30022
DRED=990000
LRED=FFCCCB

LIGHTYELLOW=FFFF99
AYELLOW=ffcc00


AGRAY=dddddd


source /etc/default/graphs1090

if [[ "$colorscheme" == "dark" ]]; then
    CANVAS=161618
    colors="\
        -c CANVAS#$CANVAS \
        -c BACK#2a2e31 \
        -c FONT#f2f5f4 \
        -c AXIS#f2f5f4 \
        -c FRAME#888888 \
        -c GRID#444444 \
        -c MGRID#444444 \
        -c SHADEA#212427 \
        -c SHADEB#171a1c \
        "

    LGREEN=1db992
    DGREEN=5cb85c
    GREEN=3d532d

    GREEN=386619



    LBLUE=7fc7ff
    BLUE=1cb992
    ABLUE=0c5685
    DBLUE=10366f

    CYAN=00A0F0
    LCYAN=29a7e6

    RED=c52b2f
    DRED=c52b2f
    LRED=a6595c

    LIGHTYELLOW=444444
    AYELLOW=cca300


    AGRAY=2a2e31
fi

source /etc/default/graphs1090

if [[ -n $ether ]]; then
    ether="interface-${ether}"
else
    ether="$(ls ${DB}/localhost | grep -v 'interface-lo' | grep interface -m1)"
fi

if [[ -n $wifi ]]; then
    wifi="interface-${wifi}"
else
    wifi="$(ls ${DB}/localhost | grep -v 'interface-lo' | grep interface -m2 | tail -n1)"
fi

if [[ -n $disk ]]; then
    disk="disk-${disk}"
else
    disk="$(ls ${DB}/localhost | grep disk -m1)"
fi


if ! [ $position_scaling ]; then
    position_scaling=0.1
fi

case $graph_size in
	custom)
		;;
	small)
		lwidth=960; lheight=206; swidth=543; sheight=276
		font_size=$(mult $font_size 0.92)
		;;
	large)
		lwidth=1260; lheight=271; swidth=702; sheight=362
		font_size=$(mult $font_size 1.08)
		;;
	huge)
		lwidth=1440; lheight=310; swidth=796; sheight=414
		font_size=$(mult $font_size 1.15)
		;;
	*|default)
		lwidth=1096; lheight=235; swidth=619; sheight=324
		;;
esac


fontsize="-n TITLE:$(mult 1.1 $font_size):. -n AXIS:$(mult 0.8 $font_size):. -n UNIT:$(mult 0.9 $font_size):. -n LEGEND:$(mult 0.9 $font_size):."
grid="-c GRID#FFFFFF --grid-dash 2:1"
options="$grid $fontsize -e $(date +%H:%M) $colors"
small="$options -D --width $swidth --height $sheight"
big="$options --width $lwidth --height $lheight"

if [[ $all_large == "yes" ]]; then
	small="$options --width $lwidth --height $lheight"
fi


# load bash sleep builtin if available
[[ -f /usr/lib/bash/sleep ]] && enable -f /usr/lib/bash/sleep sleep || true

pre="sleep 0.01"
if ! [ -z "$2" ]; then
	pre="sleep $2"
fi

#checks a file name for existence and otherwise uses an "empty" rrd as a source so the graphs can still be printed even if the file is missing

check() {
	if [ -f $1 ]
	then
		echo $1
	else
		echo "File $1 not found! Associated graph will be empty!" 1>&2
		echo "${DB}/$collectd_hostname/dump1090-$dump1090_instance/dump1090_dbfs-NaN.rrd"
	fi
}


## DUMP1090 GRAPHS

aircraft_graph() {
	$pre
	if [ $ul_aircraft ]; then upper="--rigid --upper-limit $ul_aircraft"; else upper=""; fi
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "$3 Aircraft Seen / Tracked" \
		--vertical-label "Aircraft" \
		--right-axis 1:0 \
		--lower-limit 0 \
		$upper \
		--units-exponent 0 \
		"TEXTALIGN:center" \
		"DEF:all=$(check $2/dump1090_aircraft-recent.rrd):total:AVERAGE" \
		"DEF:all_max=$(check $2/dump1090_aircraft-recent.rrd):total:MAX" \
		"DEF:pos=$(check $2/dump1090_aircraft-recent.rrd):positions:AVERAGE" \
		"DEF:mlat=$(check $2/dump1090_mlat-recent.rrd):value:AVERAGE" \
		"DEF:tisb=$(check $2/dump1090_tisb-recent.rrd):value:AVERAGE" \
		"DEF:rgps=$(check $2/dump1090_gps-recent.rrd):value:AVERAGE" \
		"CDEF:tisb0=tisb,UN,0,tisb,IF" \
		"CDEF:noloc=all,pos,-" \
		"CDEF:cgps=pos,tisb0,-,mlat,-" \
		"CDEF:gps=rgps,UN,cgps,rgps,IF" \
		"VDEF:avgac=all,AVERAGE" \
		"VDEF:maxac=all_max,MAXIMUM" \
		"AREA:all#$GREEN:Aircraft Seen / Tracked,   " \
		"GPRINT:avgac:Average\:%3.0lf     " \
		"GPRINT:maxac:Maximum\:%3.0lf\c" \
		"LINE1:gps#$BLUE:w/ ADS-B pos." \
		"LINE1:mlat#000000:w/ MLAT pos." \
		"LINE1:tisb#DD8800:w/ TIS-B pos." \
		"LINE1:noloc#$RED:w/o pos." \
		"LINE1:gps#$BLUE:" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}


aircraft_message_rate_graph() {
	if [ $ul_rate_per_aircraft ]; then upper="--rigid --upper-limit $ul_rate_per_aircraft"; else upper=""; fi
	if [ $lr_rate_per_aircraft ]; then ratio="$lr_rate_per_aircraft"; else ratio=10; fi
	if [ -f $2/dump1090_messages-remote_accepted.rrd ]
	then messages="CDEF:messages=messages1,messages2,ADDNAN"
	else messages="CDEF:messages=messages1"
	fi
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "$3 Message Rate / Aircraft" \
		--vertical-label "Messages/Aircraft/Second" \
		--lower-limit 0 \
		$upper \
		--units-exponent 0 \
		--right-axis "$ratio":0 \
		"TEXTALIGN:center" \
		"DEF:aircrafts=$(check $2/dump1090_aircraft-recent.rrd):total:AVERAGE" \
		"DEF:messages1=$(check $2/dump1090_messages-local_accepted.rrd):value:AVERAGE" \
		"DEF:messages2=$(check $2/dump1090_messages-remote_accepted.rrd):value:AVERAGE" \
		$messages \
		"CDEF:raw_rate=messages,aircrafts,/" \
		"CDEF:rate=aircrafts,0,GT,raw_rate,UNKN,IF" \
		"CDEF:aircrafts10=aircrafts,$ratio,/" \
		"VDEF:avgrate=rate,AVERAGE" \
		"VDEF:maxrate=rate,MAXIMUM" \
		"LINE1:rate#$BLUE:Messages / AC" \
		"LINE1:avgrate#666666:Average:dashes" \
		"GPRINT:avgrate:%3.1lf" \
		"LINE1:maxrate#$RED:Maximum" \
		"GPRINT:maxrate:%3.1lf\c" \
		"LINE1:aircrafts10#$DRED:Aircraft Seen / Tracked (RHS) \c" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

cpu_graph_dump1090() {
	if [ $ul_adsb_cpu ]; then upper="--rigid --upper-limit $ul_adsb_cpu"; else upper=""; fi
	if [ -f $2/dump1090_cpu-airspy.rrd ]; then
		airspy_graph1="DEF:airspy=$2/dump1090_cpu-airspy.rrd:value:AVERAGE"
		airspy_graph2="CDEF:airspyp=airspy,10,/"
		airspy_graph3="AREA:airspyp#$ABLUE:Airspy"
	fi
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "$3 CPU Utilization" \
		--units-exponent 0 \
		--vertical-label "CPU %" \
		--lower-limit 0 \
		--upper-limit 5 \
		$upper \
		--right-axis 1:0 \
		--left-axis-format "%.0lf" \
		--right-axis-format "%.0lf" \
        --units-exponent 0 \
		"DEF:demod=$(check $2/dump1090_cpu-demod.rrd):value:AVERAGE" \
		"CDEF:demodp=demod,10,/" \
		"DEF:reader=$(check $2/dump1090_cpu-reader.rrd):value:AVERAGE" \
		"CDEF:readerp=reader,10,/" \
		"DEF:background=$(check $2/dump1090_cpu-background.rrd):value:AVERAGE" \
		"CDEF:backgroundp=background,10,/" \
		$airspy_graph1 \
		$airspy_graph2 \
		$airspy_graph3 \
		"AREA:readerp#$LGREEN:USB" \
		"AREA:backgroundp#$DGREEN:Other:STACK" \
		"AREA:demodp#$GREEN:Demodulator\c:STACK" \
		"COMMENT: \n" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

tracks_graph() {
	if [ $ul_tracks ]; then upper="--upper-limit $ul_tracks"; else upper=""; fi
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "$3 Tracks Seen (8 minute exp. moving avg.)" \
		--vertical-label "Tracks/Hour" \
		--rigid \
		--lower-limit 0 \
		$upper \
		--units-exponent 0 \
		--right-axis 1:0 \
		--left-axis-format "%.0lf" \
		--right-axis-format "%.0lf" \
        --units-exponent 0 \
		"DEF:all=$(check $2/dump1090_tracks-all.rrd):value:AVERAGE" \
		"DEF:single=$(check $2/dump1090_tracks-single_message.rrd):value:AVERAGE" \
		"SHIFT:single:-60" \
		"CDEF:s=single,3600,*" \
		"CDEF:m=all,3600,*,s,-" \
		"CDEF:s8=s,480,TRENDNAN,4.1,*" \
		"CDEF:m8=m,480,TRENDNAN,4.1,*" \
		"CDEF:s4=s,240,TRENDNAN,2.6,*" \
		"CDEF:m4=m,240,TRENDNAN,2.6,*" \
		"CDEF:s2=s,120,TRENDNAN,1.6,*" \
		"CDEF:m2=m,120,TRENDNAN,1.6,*" \
		"CDEF:s1=s,60,TRENDNAN" \
		"CDEF:m1=m,60,TRENDNAN" \
		"CDEF:s_ema=s8,s4,+,s2,+,s1,+,9.3,/" \
		"CDEF:m_ema=m8,m4,+,m2,+,m1,+,9.3,/" \
		"AREA:m_ema#$GREEN:Tracks with more than one message\c" \
		"AREA:s_ema#$LRED:Tracks with single message\c:STACK" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

## SYSTEM GRAPHS

cpu_graph() {
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$big \
		--title "Overall CPU Utilization" \
		--units-exponent 0 \
		--vertical-label "CPU %" \
		--right-axis 1:0 \
		--lower-limit 0 \
		--upper-limit 5 \
		--left-axis-format "%.0lf" \
		--right-axis-format "%.0lf" \
        --units-exponent 0 \
		--pango-markup \
		"DEF:idle=$(check $2/cpu-idle.rrd):value:AVERAGE" \
		"DEF:interrupt=$(check $2/cpu-interrupt.rrd):value:AVERAGE" \
		"DEF:nice=$(check $2/cpu-nice.rrd):value:AVERAGE" \
		"DEF:softirq=$(check $2/cpu-softirq.rrd):value:AVERAGE" \
		"DEF:steal=$(check $2/cpu-steal.rrd):value:AVERAGE" \
		"DEF:system=$(check $2/cpu-system.rrd):value:AVERAGE" \
		"DEF:user=$(check $2/cpu-user.rrd):value:AVERAGE" \
		"DEF:wait=$(check $2/cpu-wait.rrd):value:AVERAGE" \
		"CDEF:all=idle,interrupt,nice,softirq,steal,system,user,wait,+,+,+,+,+,+,+" \
		"CDEF:usage=interrupt,nice,softirq,steal,system,user,wait,+,+,+,+,+,+" \
		"CDEF:pinterrupt=100,interrupt,*,all,/" \
		"CDEF:pnice=100,nice,*,all,/" \
		"CDEF:psoftirq=100,softirq,*,all,/" \
		"CDEF:psteal=100,steal,*,all,/" \
		"CDEF:psystem=100,system,*,all,/" \
		"CDEF:puser=100,user,*,all,/" \
		"CDEF:pwait=100,wait,*,all,/" \
		"AREA:pinterrupt#$ABLUE:irq" \
		"AREA:psoftirq#$DBLUE:softirq:STACK" \
		"AREA:psteal#$ABLUE:steal:STACK" \
		"AREA:pwait#C00000:io:STACK" \
		"AREA:psystem#$RED:sys:STACK" \
		"AREA:puser#$GREEN:user:STACK" \
		"AREA:pnice#$DGREEN:nice\t\t:STACK" \
		"GPRINT:usage:AVERAGE:Total\:    Avg\: %4.1lf<span font='2'> </span>%%" \
		"GPRINT:usage:LAST:Current\: %4.1lf<span font='2'> </span>%%\c" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

df_root_graph() {
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "Disk Usage (/)" \
		--vertical-label "Bytes" \
		--right-axis 1:0 \
		--lower-limit 0  \
		-M \
		"TEXTALIGN:center" \
		"DEF:used=$(check $2/df_complex-used.rrd):value:AVERAGE" \
		"DEF:reserved=$(check $2/df_complex-reserved.rrd):value:AVERAGE" \
		"DEF:free=$(check $2/df_complex-free.rrd):value:AVERAGE" \
		"CDEF:totalused=used,reserved,+" \
		"AREA:totalused#$ABLUE:Used\::STACK" \
		"GPRINT:totalused:LAST:%4.1lf%s\t\t" \
		"AREA:free#$GREEN:Free\::STACK" \
		"GPRINT:free:LAST:%4.1lf%s\c" \
		"COMMENT: \n" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

disk_io_iops_graph() {
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "Disk I/O - IOPS" \
		--vertical-label "IOPS" \
		--right-axis 1:0 \
		-A \
		"TEXTALIGN:center" \
		"DEF:read=$(check $2/disk_ops.rrd):read:AVERAGE" \
		"DEF:write=$(check $2/disk_ops.rrd):write:AVERAGE" \
		"CDEF:write_neg=write,-1,*" \
		"AREA:read#$GREEN:Reads " \
		"LINE1:read#$DGREEN" \
		"GPRINT:read:MAX:Max\:%4.1lf iops" \
		"GPRINT:read:AVERAGE:Avg\:%4.1lf iops" \
		"GPRINT:read:LAST:Current\:%4.1lf iops\c" \
		"TEXTALIGN:center" \
		"AREA:write_neg#$ABLUE:Writes" \
		"LINE1:write_neg#$DBLUE" \
		"GPRINT:write:MAX:Max\:%4.1lf iops" \
		"GPRINT:write:AVERAGE:Avg\:%4.1lf iops" \
		"GPRINT:write:LAST:Current\:%4.1lf iops\c" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

disk_io_octets_graph() {
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "Disk I/O - Bandwidth" \
		--vertical-label "kBytes/Sec" \
		--right-axis 1:0 \
		--upper-limit 10 \
		--lower-limit -10 \
		--left-axis-format "%.0lf" \
		--right-axis-format "%.0lf" \
		--units-exponent 0 \
		-A \
		"TEXTALIGN:center" \
		"DEF:read_b=$(check $2/disk_octets.rrd):read:AVERAGE" \
		"DEF:write_b=$(check $2/disk_octets.rrd):write:AVERAGE" \
		"CDEF:read=read_b,1000,/" \
		"CDEF:write=write_b,1000,/" \
		"CDEF:write_neg=write,-1,*" \
		"AREA:read#$GREEN:Reads " \
		"LINE1:read#$DGREEN" \
		"GPRINT:read_b:MAX:Max\: %4.1lf %sB/sec" \
		"GPRINT:read_b:AVERAGE:Avg\: %4.1lf %sB/sec" \
		"GPRINT:read_b:LAST:Current\: %4.1lf %sB/sec\c" \
		"TEXTALIGN:center" \
		"AREA:write_neg#$ABLUE:Writes" \
		"LINE1:write_neg#$DBLUE" \
		"GPRINT:write_b:MAX:Max\: %4.1lf %sB/sec" \
		"GPRINT:write_b:AVERAGE:Avg\: %4.1lf %sB/sec" \
		"GPRINT:write_b:LAST:Current\: %4.1lf %sB/sec\c" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

eth0_graph() {
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "Bandwidth Usage (eth0)" \
		--vertical-label "Bytes/Sec" \
		--right-axis 1:0 \
		"TEXTALIGN:center" \
		"DEF:rx=$(check $2/if_octets.rrd):rx:AVERAGE" \
		"DEF:tx=$(check $2/if_octets.rrd):tx:AVERAGE" \
		"CDEF:tx_neg=tx,-1,*" \
		"AREA:rx#$GREEN:Incoming" \
		"LINE1:rx#$DGREEN" \
		"GPRINT:rx:MAX:Max\:%8.1lf %s" \
		"GPRINT:rx:AVERAGE:Avg\:%8.1lf %S" \
		"GPRINT:rx:LAST:Current\:%8.1lf %Sbytes/sec\c" \
		"AREA:tx_neg#$ABLUE:Outgoing" \
		"LINE1:tx_neg#$DBLUE" \
		"GPRINT:tx:MAX:Max\:%8.1lf %S" \
		"GPRINT:tx:AVERAGE:Avg\:%8.1lf %S" \
		"GPRINT:tx:LAST:Current\:%8.1lf %Sbytes/sec\c" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

memory_graph() {
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--lower-limit 0 \
		--title "Memory Utilization" \
		--vertical-label "Bytes" \
		--right-axis 1:0 \
		-b 1024 \
		-M \
		"TEXTALIGN:center" \
		"DEF:used=$(check $2/memory-used.rrd):value:AVERAGE" \
		"DEF:buffers=$(check $2/memory-buffers.rrd):value:AVERAGE" \
		"DEF:cached=$(check $2/memory-cached.rrd):value:AVERAGE" \
		"DEF:free=$(check $2/memory-free.rrd):value:AVERAGE" \
		"AREA:used#$GREEN:Used\::STACK" \
		"GPRINT:used:LAST:%4.1lf%s" \
		"AREA:buffers#$ABLUE:Buffers\::STACK" \
		"GPRINT:buffers:LAST:%4.1lf%s\c" \
		"AREA:cached#$LIGHTYELLOW:Cache\::STACK" \
		"GPRINT:cached:LAST:%4.1lf%s" \
		"AREA:free#$AGRAY:Unused\::STACK" \
		"GPRINT:free:LAST:%4.1lf%s\c" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}


network_graph() {
	$pre
	if [[ $(ls ${DB}/localhost | grep interface -c) < 2 ]]
	then
		interfaces=(\
			"DEF:rx_b=$(check $2/$ether/if_octets.rrd):rx:AVERAGE" \
			"DEF:tx_b=$(check $2/$ether/if_octets.rrd):tx:AVERAGE" )
	else
		interfaces=(\
			"DEF:rx1=$(check $2/$wifi/if_octets.rrd):rx:AVERAGE" \
			"DEF:tx1=$(check $2/$wifi/if_octets.rrd):tx:AVERAGE" \
			"DEF:rx2=$(check $2/$ether/if_octets.rrd):rx:AVERAGE" \
			"DEF:tx2=$(check $2/$ether/if_octets.rrd):tx:AVERAGE" \
			"CDEF:rx_b=rx1,rx2,ADDNAN" \
			"CDEF:tx_b=tx1,tx2,ADDNAN")
	fi
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "Bandwidth Usage (wireless + ethernet)" \
		--vertical-label "kBytes/Sec" \
		--units-exponent 0 \
		--right-axis 1:0 \
		--upper-limit 10 \
		--lower-limit -10 \
		--left-axis-format "%.0lf" \
		--right-axis-format "%.0lf" \
		--units-exponent 0 \
		-A \
		"TEXTALIGN:center" \
		"${interfaces[@]}" \
		"CDEF:rx=rx_b,1000,/" \
		"CDEF:tx=tx_b,1000,/" \
		"CDEF:tx_neg=tx,-1,*" \
		"AREA:rx#$GREEN:Incoming" \
		"LINE1:rx#$DGREEN" \
		"GPRINT:rx_b:MAX:Max\:%8.1lf %s" \
		"GPRINT:rx_b:AVERAGE:Avg\:%8.1lf %s" \
		"GPRINT:rx_b:LAST:Current\:%8.1lf %sBytes/sec\c" \
		"AREA:tx_neg#$ABLUE:Outgoing" \
		"LINE1:tx_neg#$DBLUE" \
		"GPRINT:tx_b:MAX:Max\:%8.1lf %s" \
		"GPRINT:tx_b:AVERAGE:Avg\:%8.1lf %s" \
		"GPRINT:tx_b:LAST:Current\:%8.1lf %sBytes/sec\c" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

temp_graph_imperial() {
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "Maximum Core Temperature" \
		--vertical-label "Degrees Fahrenheit" \
		--right-axis 1:0 \
		--lower-limit 77 \
		--upper-limit 153 \
		-A \
		"DEF:traw_max=$(check $2/gauge-cpu_temp.rrd):value:MAX" \
		"DEF:traw_avg=$(check $2/gauge-cpu_temp.rrd):value:AVERAGE" \
		"DEF:traw_min=$(check $2/gauge-cpu_temp.rrd):value:MIN" \
		"CDEF:tfin_max=traw_max,${TEMP_MULTIPLIER},/,1.8,*,32,+" \
		"CDEF:tfin_avg=traw_avg,${TEMP_MULTIPLIER},/,1.8,*,32,+" \
		"CDEF:tfin_min=traw_min,${TEMP_MULTIPLIER},/,1.8,*,32,+" \
		"AREA:tfin_max#$AYELLOW:Temperature\:" \
		"GPRINT:tfin_max:LAST:%4.1lf F\c" \
		"GPRINT:tfin_min:MIN:Min\: %4.1lf F" \
		"GPRINT:tfin_avg:AVERAGE:Avg\: %4.1lf F" \
		"GPRINT:tfin_max:MAX:Max\: %4.1lf F\c" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

temp_graph_metric() {
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "Maximum Core Temperature" \
		--vertical-label "Degrees Celsius" \
		--right-axis 1:0 \
		--lower-limit 24 \
		--upper-limit 66 \
		-A \
		"DEF:traw_max=$(check $2/gauge-cpu_temp.rrd):value:MAX" \
		"DEF:traw_avg=$(check $2/gauge-cpu_temp.rrd):value:AVERAGE" \
		"DEF:traw_min=$(check $2/gauge-cpu_temp.rrd):value:MIN" \
		"CDEF:tfin_max=traw_max,${TEMP_MULTIPLIER},/" \
		"CDEF:tfin_min=traw_min,${TEMP_MULTIPLIER},/" \
		"CDEF:tfin_avg=traw_avg,${TEMP_MULTIPLIER},/" \
		"AREA:tfin_max#$AYELLOW:Temperature\:" \
		"GPRINT:tfin_max:LAST:%4.1lf C\c" \
		"GPRINT:tfin_min:MIN:Min\: %4.1lf C" \
		"GPRINT:tfin_avg:AVERAGE:Avg\: %4.1lf C" \
		"GPRINT:tfin_max:MAX:Max\: %4.1lf C\c" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

wlan0_graph() {
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "Bandwidth Usage (wlan0)" \
		--vertical-label "Bytes/Sec" \
		--right-axis 1:0 \
		"TEXTALIGN:center" \
		"DEF:rx=$(check $2/if_octets.rrd):rx:AVERAGE" \
		"DEF:tx=$(check $2/if_octets.rrd):tx:AVERAGE" \
		"CDEF:tx_neg=tx,-1,*" \
		"AREA:rx#$GREEN:Incoming" \
		"LINE1:rx#$DGREEN" \
		"GPRINT:rx:MAX:Max\:%8.1lf %s" \
		"GPRINT:rx:AVERAGE:Avg\:%8.1lf %S" \
		"GPRINT:rx:LAST:Current\:%8.1lf %Sbytes/sec\c" \
		"AREA:tx_neg#$ABLUE:Outgoing" \
		"LINE1:tx_neg#$DBLUE" \
		"GPRINT:tx:MAX:Max\:%8.1lf %S" \
		"GPRINT:tx:AVERAGE:Avg\:%8.1lf %S" \
		"GPRINT:tx:LAST:Current\:%8.1lf %Sbytes/sec\c" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

## RECEIVER GRAPHS

local_rate_graph() {
	$pre
	if [ $ul_maxima ]; then upper="--rigid --upper-limit $ul_maxima"; else upper=""; fi
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "$3 Maxima" \
		--vertical-label "Messages/Second" \
		--right-axis 1:0 \
		--lower-limit 0  \
		-M \
		$upper \
		--units-exponent 0 \
		--right-axis $position_scaling:0 \
		"DEF:gps=$(check $2/dump1090_gps-recent.rrd):value:MAX" \
		"DEF:mlat=$(check $2/dump1090_mlat-recent.rrd):value:MAX" \
		"DEF:messages1=$(check $2/dump1090_messages-local_accepted.rrd):value:MAX" \
		"DEF:messages2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MAX" \
		"DEF:positions=$(check $2/dump1090_messages-positions.rrd):value:MAX" \
		"CDEF:y2positions=positions,$position_scaling,/" \
		"CDEF:y2gps=gps,$position_scaling,/" \
		"CDEF:y2mlat=mlat,$position_scaling,/" \
		"COMMENT:Messages per second\:\t" \
		"LINE1:messages1#$BLUE:Local\:\g" \
		"GPRINT:messages1:MAX: %.0lf\t" \
		"LINE1:messages2#$DGREEN:Remote\:\g" \
		"GPRINT:messages2:MAX: %.0lf\c" \
		"COMMENT:Aircraft seen (RHS)\:\t" \
		"LINE1:y2mlat#000000:MLAT\:\g" \
		"GPRINT:mlat:MAX: %.0lf\t" \
		"LINE1:y2gps#$DRED:ADS-B\:\g" \
		"GPRINT:gps:MAX: %.0lf\c" \
		"LINE1:y2positions#$CYAN:Positions/s (RHS)\:\g" \
		"GPRINT:positions:MAX: %.0lf\c" \
		"LINE1:messages2#$DGREEN" \
		"LINE1:messages1#$BLUE" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

local_trailing_rate_graph() {
	$pre
	if ! [[ -f $2/dump1090_cpu-airspy.rrd ]] && [[ -f $2/dump1090_messages-strong_signals.rrd ]]; then
		strong1="AREA:strong#$RED:Messages > -3dBFS\g"
		strong2="GPRINT:strong_percent_vdef: (%1.1lf<span font='2'> </span>%% of messages)"
    else
        #rrdtool graph can't handle empty arguments, give it bogus stuff to do
        strong1="CDEF:fake1=messages"
        strong2="CDEF:fake2=messages"
    fi
	if [ $ul_message_rate ]; then upper="--rigid --upper-limit $ul_message_rate"; else upper=""; fi
	if [[ $max_messages_line == 1 ]]
	then
        maxline=("VDEF:peakmessages=messages,MAXIMUM" "LINE1:peakmessages#$BLUE:dashes=2,8")
	fi
	if [ -f $2/dump1090_messages-remote_accepted.rrd ]; then
        messages="CDEF:messages=messages1,messages2,ADDNAN"
	else
        messages="CDEF:messages=messages1"
	fi
	r_window=$((86400))
    WEEK=( \
        "DEF:a1=$(check $2/dump1090_messages-local_accepted.rrd):value:AVERAGE:end=now-86400:start=end-$r_window" \
		"DEF:b1=$(check $2/dump1090_messages-local_accepted.rrd):value:AVERAGE:end=now-172800:start=end-$r_window" \
		"DEF:c1=$(check $2/dump1090_messages-local_accepted.rrd):value:AVERAGE:end=now-259200:start=end-$r_window" \
		"DEF:d1=$(check $2/dump1090_messages-local_accepted.rrd):value:AVERAGE:end=now-345600:start=end-$r_window" \
		"DEF:e1=$(check $2/dump1090_messages-local_accepted.rrd):value:AVERAGE:end=now-432000:start=end-$r_window" \
		"DEF:f1=$(check $2/dump1090_messages-local_accepted.rrd):value:AVERAGE:end=now-518400:start=end-$r_window" \
		"DEF:g1=$(check $2/dump1090_messages-local_accepted.rrd):value:AVERAGE:end=now-604800:start=end-$r_window" \
		"DEF:amin1=$(check $2/dump1090_messages-local_accepted.rrd):value:MIN:end=now-86400:start=end-$r_window" \
		"DEF:bmin1=$(check $2/dump1090_messages-local_accepted.rrd):value:MIN:end=now-172800:start=end-$r_window" \
		"DEF:cmin1=$(check $2/dump1090_messages-local_accepted.rrd):value:MIN:end=now-259200:start=end-$r_window" \
		"DEF:dmin1=$(check $2/dump1090_messages-local_accepted.rrd):value:MIN:end=now-345600:start=end-$r_window" \
		"DEF:emin1=$(check $2/dump1090_messages-local_accepted.rrd):value:MIN:end=now-432000:start=end-$r_window" \
		"DEF:fmin1=$(check $2/dump1090_messages-local_accepted.rrd):value:MIN:end=now-518400:start=end-$r_window" \
		"DEF:gmin1=$(check $2/dump1090_messages-local_accepted.rrd):value:MIN:end=now-604800:start=end-$r_window" \
		"DEF:amax1=$(check $2/dump1090_messages-local_accepted.rrd):value:MAX:end=now-86400:start=end-$r_window" \
		"DEF:bmax1=$(check $2/dump1090_messages-local_accepted.rrd):value:MAX:end=now-172800:start=end-$r_window" \
		"DEF:cmax1=$(check $2/dump1090_messages-local_accepted.rrd):value:MAX:end=now-259200:start=end-$r_window" \
		"DEF:dmax1=$(check $2/dump1090_messages-local_accepted.rrd):value:MAX:end=now-345600:start=end-$r_window" \
		"DEF:emax1=$(check $2/dump1090_messages-local_accepted.rrd):value:MAX:end=now-432000:start=end-$r_window" \
		"DEF:fmax1=$(check $2/dump1090_messages-local_accepted.rrd):value:MAX:end=now-518400:start=end-$r_window" \
		"DEF:gmax1=$(check $2/dump1090_messages-local_accepted.rrd):value:MAX:end=now-604800:start=end-$r_window" \
		"DEF:a2=$(check $2/dump1090_messages-remote_accepted.rrd):value:AVERAGE:end=now-86400:start=end-$r_window" \
		"DEF:b2=$(check $2/dump1090_messages-remote_accepted.rrd):value:AVERAGE:end=now-172800:start=end-$r_window" \
		"DEF:c2=$(check $2/dump1090_messages-remote_accepted.rrd):value:AVERAGE:end=now-259200:start=end-$r_window" \
		"DEF:d2=$(check $2/dump1090_messages-remote_accepted.rrd):value:AVERAGE:end=now-345600:start=end-$r_window" \
		"DEF:e2=$(check $2/dump1090_messages-remote_accepted.rrd):value:AVERAGE:end=now-432000:start=end-$r_window" \
		"DEF:f2=$(check $2/dump1090_messages-remote_accepted.rrd):value:AVERAGE:end=now-518400:start=end-$r_window" \
		"DEF:g2=$(check $2/dump1090_messages-remote_accepted.rrd):value:AVERAGE:end=now-604800:start=end-$r_window" \
		"DEF:amin2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MIN:end=now-86400:start=end-$r_window" \
		"DEF:bmin2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MIN:end=now-172800:start=end-$r_window" \
		"DEF:cmin2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MIN:end=now-259200:start=end-$r_window" \
		"DEF:dmin2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MIN:end=now-345600:start=end-$r_window" \
		"DEF:emin2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MIN:end=now-432000:start=end-$r_window" \
		"DEF:fmin2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MIN:end=now-518400:start=end-$r_window" \
		"DEF:gmin2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MIN:end=now-604800:start=end-$r_window" \
		"DEF:amax2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MAX:end=now-86400:start=end-$r_window" \
		"DEF:bmax2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MAX:end=now-172800:start=end-$r_window" \
		"DEF:cmax2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MAX:end=now-259200:start=end-$r_window" \
		"DEF:dmax2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MAX:end=now-345600:start=end-$r_window" \
		"DEF:emax2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MAX:end=now-432000:start=end-$r_window" \
		"DEF:fmax2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MAX:end=now-518400:start=end-$r_window" \
		"DEF:gmax2=$(check $2/dump1090_messages-remote_accepted.rrd):value:MAX:end=now-604800:start=end-$r_window" \
		"CDEF:a=a1,a2,ADDNAN" \
		"CDEF:b=b1,b2,ADDNAN" \
		"CDEF:c=c1,c2,ADDNAN" \
		"CDEF:d=d1,d2,ADDNAN" \
		"CDEF:e=e1,e2,ADDNAN" \
		"CDEF:f=f1,f2,ADDNAN" \
		"CDEF:g=g1,g2,ADDNAN" \
		"CDEF:amin=amin1,amin2,ADDNAN" \
		"CDEF:bmin=bmin1,bmin2,ADDNAN" \
		"CDEF:cmin=cmin1,cmin2,ADDNAN" \
		"CDEF:dmin=dmin1,dmin2,ADDNAN" \
		"CDEF:emin=emin1,emin2,ADDNAN" \
		"CDEF:fmin=fmin1,fmin2,ADDNAN" \
		"CDEF:gmin=gmin1,gmin2,ADDNAN" \
		"CDEF:amax=amax1,amax2,ADDNAN" \
		"CDEF:bmax=bmax1,bmax2,ADDNAN" \
		"CDEF:cmax=cmax1,cmax2,ADDNAN" \
		"CDEF:dmax=dmax1,dmax2,ADDNAN" \
		"CDEF:emax=emax1,emax2,ADDNAN" \
		"CDEF:fmax=fmax1,fmax2,ADDNAN" \
		"CDEF:gmax=gmax1,gmax2,ADDNAN" \
		"CDEF:a3=a,UN,0,a,IF" \
		"CDEF:b3=b,UN,0,b,IF" \
		"CDEF:c3=c,UN,0,c,IF" \
		"CDEF:d3=d,UN,0,d,IF" \
		"CDEF:e3=e,UN,0,e,IF" \
		"CDEF:f3=f,UN,0,f,IF" \
		"CDEF:g3=g,UN,0,g,IF" \
		"SHIFT:a3:86400" \
		"SHIFT:b3:172800" \
		"SHIFT:c3:259200" \
		"SHIFT:d3:345600" \
		"SHIFT:e3:432000" \
		"SHIFT:f3:518400" \
		"SHIFT:g3:604800" \
		"SHIFT:amin:86400" \
		"SHIFT:bmin:172800" \
		"SHIFT:cmin:259200" \
		"SHIFT:dmin:345600" \
		"SHIFT:emin:432000" \
		"SHIFT:fmin:518400" \
		"SHIFT:gmin:604800" \
		"SHIFT:amax:86400" \
		"SHIFT:bmax:172800" \
		"SHIFT:cmax:259200" \
		"SHIFT:dmax:345600" \
		"SHIFT:emax:432000" \
		"SHIFT:fmax:518400" \
		"SHIFT:gmax:604800" \
		"CDEF:7dayaverage=a3,b3,c3,d3,e3,f3,g3,+,+,+,+,+,+,7,/" \
		"CDEF:min1=amin,bmin,MINNAN" \
		"CDEF:min2=cmin,dmin,MINNAN" \
		"CDEF:min3=emin,fmin,MINNAN" \
		"CDEF:min4=min1,min2,MINNAN" \
		"CDEF:min5=min3,gmin,MINNAN" \
		"CDEF:min=min4,min5,MINNAN" \
		"CDEF:max1=amax,bmax,MAXNAN" \
		"CDEF:max2=cmax,dmax,MAXNAN" \
		"CDEF:max3=emax,fmax,MAXNAN" \
		"CDEF:max4=max1,max2,MAXNAN" \
		"CDEF:max5=max3,gmax,MAXNAN" \
		"CDEF:max=max4,max5,MAXNAN" \
		"CDEF:maxarea=max,min,-" \
		"LINE1:min#$LIGHTYELLOW" \
		"AREA:maxarea#$LIGHTYELLOW:Min/Max:STACK" \
		"LINE1:7dayaverage#$DGREEN:7 Day Average" \
    )
    if [[ ${4: -1} != "h" ]]; then
        WEEK=()
    fi
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$big \
		--slope-mode \
		--title "$3 Message Rate" \
		--vertical-label "Messages/Second" \
		--lower-limit 0  \
		$upper \
		--right-axis $position_scaling:0 \
		--units-exponent 0 \
		--pango-markup \
		"TEXTALIGN:center" \
		"DEF:messages1=$(check $2/dump1090_messages-local_accepted.rrd):value:AVERAGE" \
		"DEF:messages2=$(check $2/dump1090_messages-remote_accepted.rrd):value:AVERAGE" \
		$messages \
		"DEF:strong=$(check $2/dump1090_messages-strong_signals.rrd):value:AVERAGE" \
		"DEF:positions=$(check $2/dump1090_messages-positions.rrd):value:AVERAGE" \
		"CDEF:y2positions=positions,$position_scaling,/" \
		"VDEF:strong_total=strong,TOTAL" \
		"VDEF:messages_total=messages,TOTAL" \
		"CDEF:hundred=messages,UN,100,100,IF" \
		"CDEF:strong_percent=strong_total,hundred,*,messages_total,/" \
		"VDEF:strong_percent_vdef=strong_percent,LAST" \
		"LINE0.01:messages#$BLUE:Messages Received" \
        "${WEEK[@]}" \
		"LINE1:messages#$BLUE" \
		"${maxline[@]}" \
        "$strong1" "$strong2" \
		"LINE1:y2positions#$CYAN:Positions/s (RHS)\c" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

range_graph(){
	$pre
	label="Nautical Miles"
	unitconv=0.000539956803
	if [[ $range == "statute" ]]; then
		unitconv=0.000621371
		label="Statute Miles"
	fi
	if [[ $range == "metric" ]]; then
		unitconv=0.001
		label="Kilometers"
	fi
	raxis=1
	if [[ $range2 == "metric" ]]; then
		raxis=$(div 0.001 $unitconv)
	fi
	if [[ $range2 == "statute" ]]; then
		raxis=$(div 0.000621371 $unitconv)
	fi
	if [[ $range2 == "nautical" ]]; then
		raxis=$(div 0.000539956803 $unitconv)
	fi
	if [[ $3 == "UAT" ]]; then
		if [ $ul_range_uat ]; then upper="--rigid --upper-limit $ul_range_uat"; else upper=""; fi
		defines=( \
			"-y 20:1" \
			"DEF:drange=$(check $2/dump1090_range-max_range_978.rrd):value:MAX" \
			"DEF:drange_a=$(check $2/dump1090_range-max_range_978.rrd):value:AVERAGE" \
			"DEF:dmin=$(check $2/dump1090_range-minimum_978.rrd):value:MIN" \
			"DEF:dquart1=$(check $2/dump1090_range-quart1_978.rrd):value:AVERAGE" \
			"DEF:dquart3=$(check $2/dump1090_range-quart3_978.rrd):value:AVERAGE" \
			"DEF:dmedian=$(check $2/dump1090_range-median_978.rrd):value:AVERAGE" \
		)
	else
		if [ $ul_range ]; then upper="--rigid --upper-limit $ul_range"; else upper=""; fi
		defines=( \
			"-y 40:1" \
			"DEF:drange=$(check $2/dump1090_range-max_range.rrd):value:MAX" \
			"DEF:drange_a=$(check $2/dump1090_range-max_range.rrd):value:AVERAGE" \
			"DEF:dmin=$(check $2/dump1090_range-minimum.rrd):value:MIN" \
			"DEF:dquart1=$(check $2/dump1090_range-quart1.rrd):value:AVERAGE" \
			"DEF:dquart3=$(check $2/dump1090_range-quart3.rrd):value:AVERAGE" \
			"DEF:dmedian=$(check $2/dump1090_range-median.rrd):value:AVERAGE" \
			)
	fi

	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "$3 Range" \
		--vertical-label "$label" \
		--units-exponent 0 \
		-M \
		--lower-limit 0 \
		$upper \
		--right-axis $raxis:0 \
		${defines[*]} \
		"CDEF:range=drange,$unitconv,*" \
		"CDEF:range_a=drange_a,$unitconv,*" \
		"CDEF:min=dmin,$unitconv,*" \
		"CDEF:quart1=dquart1,$unitconv,*" \
		"CDEF:quart3=dquart3,$unitconv,*" \
		"CDEF:median=dmedian,$unitconv,*" \
		"AREA:quart3#$GREEN:1st to 3rd Quartile" \
		"AREA:quart1#$CANVAS" \
		"LINE1:range#$BLUE:Max Range" \
		"VDEF:avgrange=range_a,AVERAGE" \
		"LINE1:avgrange#666666:Avg Max Range\\::dashes" \
		"VDEF:peakrange=range,MAXIMUM" \
		"GPRINT:avgrange:%1.1lf\c" \
		"LINE1:min#$CYAN:Closest\:" \
		"GPRINT:min:MIN:%4.1lf" \
		"LINE1:median#444444:Median Distance\:" \
		"GPRINT:median:AVERAGE:%4.1lf (avg)" \
		"LINE1:peakrange#$BLUE:Peak Range\\:" \
		"GPRINT:peakrange:%1.1lf\c" \
		"LINE1:range#$BLUE" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}


signal_graph() {
	$pre
    #rrdtool graph can't handle empty arguments, give it bogus stuff to do
    noise1="CDEF:fake1=signal"
	if [[ $3 == "UAT" ]]; then
		defines=( \
		"DEF:signal=$(check $2/dump1090_dbfs-median_978.rrd):value:AVERAGE" \
		"DEF:min=$(check $2/dump1090_dbfs-min_signal_978.rrd):value:MIN" \
		"DEF:quart1=$(check $2/dump1090_dbfs-quart1_978.rrd):value:AVERAGE" \
		"DEF:quart3=$(check $2/dump1090_dbfs-quart3_978.rrd):value:AVERAGE" \
		"DEF:median=$(check $2/dump1090_dbfs-median_978.rrd):value:AVERAGE" \
		"DEF:peak=$(check $2/dump1090_dbfs-peak_signal_978.rrd):value:MAX" \
		)
	else
		defines=( \
		"DEF:signal=$(check $2/dump1090_dbfs-signal.rrd):value:AVERAGE" \
		"DEF:min=$(check $2/dump1090_dbfs-min_signal.rrd):value:MIN" \
		"DEF:quart1=$(check $2/dump1090_dbfs-quart1.rrd):value:AVERAGE" \
		"DEF:quart3=$(check $2/dump1090_dbfs-quart3.rrd):value:AVERAGE" \
		"DEF:median=$(check $2/dump1090_dbfs-median.rrd):value:AVERAGE" \
		"DEF:peak=$(check $2/dump1090_dbfs-peak_signal.rrd):value:MAX" \
		)
        if [[ -f $2/dump1090_dbfs-noise.rrd ]]; then
            noise1="LINE1:noise#$DGREEN:Noise"
        fi
	fi
    if [ $ll_signal ]; then lower="$ll_signal"; else lower="-45"; fi
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "$3 Signal Level" \
		--vertical-label "dBFS" \
		--right-axis 1:0 \
		-y 6:1 \
		--left-axis-format "%.0lf" \
		--right-axis-format "%.0lf" \
		--units-exponent 0 \
		--upper-limit 1    \
		--lower-limit "$lower" \
		--rigid \
		${defines[*]} \
		"DEF:noise=$(check $2/dump1090_dbfs-noise.rrd):value:AVERAGE" \
		"TEXTALIGN:center" \
		"CDEF:mes=median,UN,signal,median,IF" \
		"AREA:quart1#$GREEN:1st to 3rd Quartile" \
		"AREA:quart3#$CANVAS" \
		"LINE1:mes#444444:Mean Median Level\:" \
		"GPRINT:mes:AVERAGE:%4.1lf\c" \
		"LINE1:min#$CYAN:Weakest\:" \
		"GPRINT:min:MIN:%4.1lf" \
        "$noise1" \
		"LINE1:peak#$BLUE:Peak Level\:" \
		"GPRINT:peak:MAX:%4.1lf\c" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}

dump1090_misc() {
	$pre
    defines=( \
        "DEF:gain=$(check $2/dump1090_misc-gain_db.rrd):value:AVERAGE" \
    )
	if [[ -n "$ul_dump1090_misc" ]]; then upper="--rigid --upper-limit $ul_dump1090_misc"; else upper=""; fi
    TITLE="Misc"
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "$TITLE" \
		--right-axis 1:0 \
		--vertical-label "misc" \
		--left-axis-format "%.0lf" \
		--right-axis-format "%.0lf" \
		--units-exponent 0 \
		-y 3:1 \
        $upper \
		--lower-limit 4  \
		${defines[*]} \
		"TEXTALIGN:center" \
		"LINE2:gain#$DRED:Gain\:" \
		"GPRINT:gain:LAST:%2.1lf" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}
df_counts() {
	$pre
	DF=(0 4 5 11 16 17 18 19 21)
	colors=($GREEN $BLUE $DBLUE $ABLUE $RED $DRED $DGREEN $CYAN $LRED)
	defines=()
	graphs=()
	for i in $(seq 0 8); do
		df="${DF[i]}"
		defines+=("DEF:df_min${df}=$(check $2/df_count_minute-$df.rrd):value:AVERAGE")
		if [[ $df == 11 ]]; then
			defines+=("CDEF:df${df}=df_min${df},120,/")
			graphs+=("LINE1.5:df${df}#${colors[$i]}:DF${df} halfed")
			graphs+=("GPRINT:df${df}:LAST:%4.1lf")
		else
			defines+=("CDEF:df${df}=df_min${df},60,/")
			graphs+=("LINE1.5:df${df}#${colors[$i]}:DF${df}")
			graphs+=("GPRINT:df${df}:LAST:%4.1lf")
		fi
		#echo "${defines[$i]}"
		#echo "${graphs[$i]}"
	done
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "DF counts" \
		--vertical-label "per second" \
		--right-axis 1:0 \
		--left-axis-format "%.0lf" \
		--right-axis-format "%.0lf" \
		--units-exponent 0 \
		"${defines[@]}" \
		"TEXTALIGN:center" \
		"${graphs[@]}" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}
signal_airspy() {
	$pre
    defines=( \
        "DEF:min=$(check $2/airspy_$3-min.rrd):value:MIN" \
        "DEF:p5=$(check $2/airspy_$3-p5.rrd):value:AVERAGE" \
        "DEF:quart1=$(check $2/airspy_$3-q1.rrd):value:AVERAGE" \
        "DEF:median=$(check $2/airspy_$3-median.rrd):value:AVERAGE" \
        "DEF:quart3=$(check $2/airspy_$3-q3.rrd):value:AVERAGE" \
        "DEF:p95=$(check $2/airspy_$3-p95.rrd):value:AVERAGE" \
        "DEF:peak=$(check $2/airspy_$3-max.rrd):value:MAX" \
    )
    if [[ $3 == snr ]]; then
        UL="--upper-limit 45"
        LL="--lower-limit 0"
    else
        UL="--upper-limit 75"
        LL="--lower-limit 0"
    fi
    TITLE="Airspy ${3^^}"
    if [[ $3 == "noise" ]]; then TITLE="Airspy Noise"; fi
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "$TITLE" \
		--vertical-label "dB" \
		--right-axis 1:0 \
		-y 6:1 \
		--left-axis-format "%.0lf" \
		--right-axis-format "%.0lf" \
		--units-exponent 0 \
        --rigid \
		$UL \
		$LL \
		${defines[*]} \
		"TEXTALIGN:center" \
		"AREA:peak#$LCYAN:Peak Level\:" \
		"GPRINT:peak:MAX:%4.1lf" \
		"AREA:p95#$LBLUE:5th to 95th Percentile\c" \
		"AREA:quart3#$LGREEN:1st to 3rd Quartile" \
		"AREA:quart1#$LBLUE" \
		"AREA:p5#$LCYAN" \
		"AREA:min#$CANVAS" \
		"LINE1:median#444444:Mean Median Level\:" \
		"GPRINT:median:AVERAGE:%4.1lf" \
		"LINE1:min#$LCYAN:Weakest\:" \
		"GPRINT:min:MIN:%4.1lf" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}
misc_airspy() {
	$pre
    defines=( \
        "DEF:lost_buffers=$(check $2/airspy_lost-lost_buffers.rrd):value:AVERAGE" \
        "DEF:aircraft_count=$(check $2/airspy_aircraft-max_aircraft_count.rrd):value:AVERAGE" \
        "DEF:gain=$(check $2/airspy_misc-gain.rrd):value:AVERAGE" \
        "DEF:preamble_filter=$(check $2/airspy_misc-preamble_filter.rrd):value:AVERAGE" \
        "DEF:samplerate=$(check $2/airspy_misc-samplerate.rrd):value:AVERAGE" \
    )
	if [[ -n "$ul_airspy_misc" ]]; then upper="--rigid --upper-limit $ul_airspy_misc"; else upper=""; fi
    TITLE="Airspy Misc"
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "$TITLE" \
		--right-axis 1:0 \
		--vertical-label "misc" \
		--left-axis-format "%.0lf" \
		--right-axis-format "%.0lf" \
		--units-exponent 0 \
		-y 3:1 \
        $upper \
		--lower-limit 0  \
		${defines[*]} \
		"TEXTALIGN:center" \
		"LINE2:gain#$DRED:Gain\:" \
		"GPRINT:gain:LAST:%0.0lf" \
		"LINE2:samplerate#$DBLUE:Samplerate\:" \
		"GPRINT:samplerate:LAST:%0.0lf" \
		"LINE2:preamble_filter#$DGREEN:Preamble Filter\:" \
		"GPRINT:preamble_filter:LAST:%0.1lf\c" \
		"CDEF:lost_buffers_min=lost_buffers,60,*" \
		"LINE2:lost_buffers_min#$RED:Lost Buffers per minute" \
		"VDEF:total_lost=lost_buffers,TOTAL" \
		"GPRINT:total_lost:Total Lost Buffers\: %0.0lf%s\c" \
		"VDEF:avgac=aircraft_count,AVERAGE" \
		"GPRINT:avgac:Average Aircraft Count\: %3.0lf" \
		"VDEF:maxac=aircraft_count,MAXIMUM" \
		"GPRINT:maxac:Highest Aircraft Count\: %3.0lf" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}


978_aircraft() {
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "UAT Aircraft Seen / Tracked" \
		--vertical-label "Aircraft" \
		--right-axis 1:0 \
		--lower-limit 0 \
		--right-axis-format "%.1lf" \
		--left-axis-format "%.1lf" \
        --units-exponent 0 \
		"TEXTALIGN:center" \
		"DEF:all=$2/dump1090_aircraft-recent_978.rrd:total:AVERAGE" \
		"DEF:pos=$2/dump1090_aircraft-recent_978.rrd:positions:AVERAGE" \
		"DEF:tisb=$(check $2/dump1090_tisb-recent_978.rrd):value:AVERAGE" \
		"DEF:rgps=$(check $2/dump1090_gps-recent_978.rrd):value:AVERAGE" \
		"CDEF:noloc=all,pos,-" \
		"CDEF:tisb0=tisb,UN,0,tisb,IF" \
		"CDEF:cgps=pos,tisb0,-" \
		"CDEF:gps=rgps,UN,cgps,rgps,IF" \
		"VDEF:avgac=all,AVERAGE" \
		"VDEF:maxac=all,MAXIMUM" \
		"AREA:all#$GREEN:Aircraft Seen / Tracked,   " \
		"GPRINT:avgac:Average\:%3.0lf     " \
		"GPRINT:maxac:Maximum\:%3.0lf\c" \
		"LINE1:gps#$BLUE:w/ ADS-B pos." \
		"LINE1:tisb#DD8800:w/ TIS-B pos." \
		"LINE1:noloc#$RED:w/o pos." \
		"LINE1:gps#$BLUE:" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}


978_messages() {
	$pre
	rrdtool graph \
		"$1.tmp" \
		--end "$END_TIME" \
		--start end-$4 \
		$small \
		--title "UAT Message Rate" \
		--vertical-label "Messages/Second" \
		--right-axis 1:0 \
		--lower-limit 0  \
		--right-axis-format "%.1lf" \
		--left-axis-format "%.1lf" \
        --units-exponent 0 \
		"DEF:messages=$2/dump1090_messages-messages_978.rrd:value:AVERAGE" \
		"LINE1:messages#$BLUE:Messages\c" \
		"COMMENT: \n" \
		--watermark "Drawn: $nowlit";
	mv "$1.tmp" "$1"
	}


dump1090_graphs() {
	aircraft_graph ${DOCUMENTROOT}/dump1090-$2-aircraft-$4.png ${DB}/$1/dump1090-$2 "$3" "$4" "$5"
	aircraft_message_rate_graph ${DOCUMENTROOT}/dump1090-$2-aircraft_message_rate-$4.png ${DB}/$1/dump1090-$2 "$3" "$4" "$5"
	cpu_graph_dump1090 ${DOCUMENTROOT}/dump1090-$2-cpu-$4.png ${DB}/$1/dump1090-$2 "$3" "$4" "$5"
	tracks_graph ${DOCUMENTROOT}/dump1090-$2-tracks-$4.png ${DB}/$1/dump1090-$2 "$3" "$4" "$5" 
	local_rate_graph ${DOCUMENTROOT}/dump1090-$2-local_rate-$4.png ${DB}/$1/dump1090-$2 "$3" "$4" "$5"
	local_trailing_rate_graph ${DOCUMENTROOT}/dump1090-$2-local_trailing_rate-$4.png ${DB}/$1/dump1090-$2 "$3" "$4" "$5"

	range_graph ${DOCUMENTROOT}/dump1090-$2-range-$4.png ${DB}/$1/dump1090-$2 "$3" "$4" "$5"

	signal_graph ${DOCUMENTROOT}/dump1090-$2-signal-$4.png ${DB}/$1/dump1090-$2 "$3" "$4" "$5"
	if [ -f ${DB}/$1/dump1090-$2/dump1090_messages-messages_978.rrd ]
	then
        if grep -qs -e 'style="display:none"> <!-- dump978 -->' /usr/share/graphs1090/html/index.html; then
            sed -i -e 's/ style="display:none"> <!-- dump978 -->/> <!-- dump978 -->/' /usr/share/graphs1090/html/index.html
        fi
		range_graph ${DOCUMENTROOT}/dump1090-$2-range_978-$4.png ${DB}/$1/dump1090-$2 "UAT" "$4" "$5"
		978_aircraft ${DOCUMENTROOT}/dump1090-$2-aircraft_978-$4.png ${DB}/$1/dump1090-$2 "UAT" "$4" "$5"
		978_messages ${DOCUMENTROOT}/dump1090-$2-messages_978-$4.png ${DB}/$1/dump1090-$2 "UAT" "$4" "$5"
		signal_graph ${DOCUMENTROOT}/dump1090-$2-signal_978-$4.png ${DB}/$1/dump1090-$2 "UAT" "$4" "$5"
	fi
	if [[ -f ${DB}/$1/dump1090-$2/df_count_minute-17.rrd ]]; then
		df_counts ${DOCUMENTROOT}/df_counts-$2-$4.png ${DB}/$1/dump1090-$2 "df_counts" "$4" "$5"
	fi
    if [[ -f /run/airspy_adsb/stats.json ]]; then
        if grep -qs -e 'style="display:none"> <!-- airspy -->' /usr/share/graphs1090/html/index.html; then
            sed -i -e 's/ style="display:none"> <!-- airspy -->/> <!-- airspy -->/' /usr/share/graphs1090/html/index.html
        fi
        signal_airspy ${DOCUMENTROOT}/airspy-$2-rssi-$4.png ${DB}/$1/dump1090-$2 "rssi" "$4" "$5"
        signal_airspy ${DOCUMENTROOT}/airspy-$2-snr-$4.png ${DB}/$1/dump1090-$2 "snr" "$4" "$5"
        signal_airspy ${DOCUMENTROOT}/airspy-$2-noise-$4.png ${DB}/$1/dump1090-$2 "noise" "$4" "$5"
        misc_airspy ${DOCUMENTROOT}/airspy-$2-misc-$4.png ${DB}/$1/dump1090-$2 "misc" "$4" "$5"
    fi
    if [[ -f ${DB}/$1/dump1090-$2/dump1090_misc-gain_db.rrd ]]; then
        dump1090_misc ${DOCUMENTROOT}/dump1090-$2-misc-$4.png ${DB}/$1/dump1090-$2 "misc" "$4" "$5"
    fi
}

system_graphs() {
	cpu_graph ${DOCUMENTROOT}/system-$2-cpu-$4.png ${DB}/$1/aggregation-cpu-average "$3" "$4" "$5"
	df_root_graph ${DOCUMENTROOT}/system-$2-df_root-$4.png ${DB}/$1/df-root "$3" "$4" "$5"
	disk_io_iops_graph ${DOCUMENTROOT}/system-$2-disk_io_iops-$4.png ${DB}/$1/$disk "$3" "$4" "$5"
	disk_io_octets_graph ${DOCUMENTROOT}/system-$2-disk_io_octets-$4.png ${DB}/$1/$disk "$3" "$4" "$5"
	memory_graph ${DOCUMENTROOT}/system-$2-memory-$4.png ${DB}/$1/system_stats "$3" "$4" "$5"
	network_graph ${DOCUMENTROOT}/system-$2-network_bandwidth-$4.png ${DB}/$1 "$3" "$4" "$5"
	if [[ $farenheit == 1 ]]
	then
		temp_graph_imperial ${DOCUMENTROOT}/system-$2-temperature-$4.png ${DB}/$1/table-$2 "$3" "$4" "$5"
	else
		temp_graph_metric ${DOCUMENTROOT}/system-$2-temperature-$4.png ${DB}/$1/table-$2 "$3" "$4" "$5"
	fi
	#eth0_graph ${DOCUMENTROOT}/system-$2-eth0_bandwidth-$4.png ${DB}/$1/$ether "$3" "$4" "$5"
	#wlan0_graph ${DOCUMENTROOT}/system-$2-wlan0_bandwidth-$4.png ${DB}/$1/$wifi "$3" "$4" "$5"
}

dump1090_receiver_graphs() {
	dump1090_graphs "$1" "$2" "$3" "$4" "$5"
	system_graphs "$1" "$2" "$3" "$4" "$5"
}


period="$1"
step="$3"
END_TIME=$(date -d -1min '+%H:%M')
nowlit=$(date -d "$END_TIME" '+%Y-%m-%d %H:%M %Z')

# Changing the following two variables means you need to change the names in html/graph.js as well so that the graphs are correctly displayed
dump1090_instance="localhost"
collectd_hostname="localhost"

if [ -z $1 ]
then
	dump1090_receiver_graphs $collectd_hostname $dump1090_instance "ADS-B" "24h" "$step"
else
	dump1090_receiver_graphs $collectd_hostname $dump1090_instance "ADS-B" "$period" "$step"
fi
