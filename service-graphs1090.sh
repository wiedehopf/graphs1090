#!/bin/bash

echo "Generating all graphs"
/usr/share/graphs1090/boot.sh 0.33

graphs() {
	#echo "Generating $1 graphs"
	/usr/share/graphs1090/graphs1090.sh $1 0.33 &>/dev/null
}
counter=0
hour_done=0

# load bash sleep builtin if available
[[ -f /usr/lib/bash/sleep ]] && enable -f /usr/lib/bash/sleep sleep || true

while wait;
do
    SEC=$(( 10#$(date -u +%S) ))
    if (( SEC != 45 )); then
        sleep 0.9 &
        continue
    fi
    sleep 59.9 & # wait in the while condition

    m=$(( 10#$(date -u +%s) / 60))

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
    else                                 graphs 1095d
    fi

    if [[ $(date +%H:%M) == 00:07 ]]; then
        echo running scatter.sh
        /usr/share/graphs1090/scatter.sh
    fi
done
