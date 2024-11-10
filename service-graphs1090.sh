#!/bin/bash

trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR
trap "pkill -P $$ || true; exit 0" SIGTERM SIGINT SIGHUP SIGQUIT

# make sure we're nice :)
renice 20 $$ || true

DB=/var/lib/collectd/rrd

source /etc/default/graphs1090

# autodetect and use /run/collectd as DB folder if it exists and has localhost
# folder having it automatically changed in /etc/default/graphs1090 causes
# issues for example when the user replaces his configuration with the default
# which is a valid approach
if [[ -d /run/collectd/localhost ]]; then
    DB=/run/collectd
fi


if [[ -z $DRAW_INTERVAL ]]; then
    DRAW_INTERVAL=60
fi

DRAW_INTERVAL=$(cut -d '.' -f1 <<< $DRAW_INTERVAL)
DRAW_INTERVAL=$(( 10#$DRAW_INTERVAL ))

if (( DRAW_INTERVAL < 1 )); then
    DRAW_INTERVAL=1
fi

if (( DRAW_INTERVAL < 20 )); then
    GRAPH_DELAY=0
else
    GRAPH_DELAY=0
fi

# use zero delay for the first generation of graphs to speed it up
/usr/share/graphs1090/boot.sh 0 &
wait || true;

graphs() {
	#echo "Generating $1 graphs"
	/usr/share/graphs1090/graphs1090.sh $1 $GRAPH_DELAY &>/dev/null
}

counter=0
hour_done=0

# load bash sleep builtin if available
[[ -f /usr/lib/bash/sleep ]] && enable -f /usr/lib/bash/sleep sleep || true

while wait;
do
    SEC=$(( 10#$(date -u +%s) ))
    EARLY=$(( DRAW_INTERVAL * 3 / 4 - (SEC % DRAW_INTERVAL) ))
    #echo $(( SEC % DRAW_INTERVAL )) $EARLY $(( DRAW_INTERVAL + EARLY - 1))
    if (( EARLY < -1 )); then
        sleep $(( DRAW_INTERVAL + EARLY - 1))
        continue
    elif (( EARLY > 0 )); then
        sleep $EARLY
    fi
    if (( EARLY == -1 )); then
        sleep $(( $DRAW_INTERVAL - 1 )) & # wait in the while condition
    else
        sleep $DRAW_INTERVAL & # wait in the while condition
    fi

    m=$(( SEC / DRAW_INTERVAL))

    if   (( m % 2 == 1 )); then          graphs 2h
    elif (( m % 4 == 2 )); then          graphs 8h
    elif (( m % 8 == 4 )); then          graphs 24h
    elif (( m % 16 == 8 )); then         graphs 48h
    elif (( m % 32 == 16 )); then        graphs 7d
    elif (( m % 64 == 32 )); then        graphs 14d
    elif (( m % 128 == 64 )); then       graphs 30d
    elif (( m % 256 == 128 )); then      graphs 90d
    elif (( m % 512 == 256 )); then      graphs 180d
    elif (( m % 1024 == 512 )); then     graphs 365d
    elif (( m % 2048 == 1024 )); then    graphs 730d
    elif (( m % 4096 == 2048 )); then    graphs 1095d
    elif (( m % 8192 == 4096 )); then    graphs 1825d
    else                                 graphs 3650d
    fi

    if [[ $(date +%H:%M) == 00:07 ]]; then
        echo running scatter.sh
        /usr/share/graphs1090/scatter.sh
    fi
done &
wait || true;
