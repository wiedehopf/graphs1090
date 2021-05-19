#!/bin/bash

echo "Generating all graphs"
/usr/share/graphs1090/boot.sh 0.4

graphs() {
	#echo "Generating $1 graphs"
	/usr/share/graphs1090/graphs1090.sh $1 0.7 &>/dev/null
}
counter=0
hour_done=0

while wait;
do
    SEC=$(( 10#$(date -u +%S) ))
    if (( SEC != 45 )); then
        sleep 0.9 &
        continue
    fi
    sleep 59.99 & # wait in the while condition

    m=$(( 10#$(date -u +%s) / 60))

	if [[ $((m%5)) == 1 ]]; then
		graphs 8h
	elif [[ $((m%5)) == 2 ]]; then
		graphs 24h
	elif [[ $((m%5)) == 3 ]]; then
		graphs 8h
	elif [[ $((m%5)) == 4 ]]; then
		graphs 2h
	elif [[ $((m%10)) == 5 ]]; then
		graphs 48h
	elif [[ $((m%80)) == 30 ]] || [[ $((m%80)) == 70 ]]; then
		graphs 7d
	elif [[ $((m%80)) == 20 ]]; then
		graphs 14d
	elif [[ $((m%80)) == 40 ]]; then
		graphs 30d
	elif [[ $((m%80)) == 50 ]]; then
		graphs 90d
	elif [[ $((m%80)) == 60 ]]; then
		graphs 180d
    elif [[ $((m%800)) == 10 ]]; then
        graphs 365d
    elif [[ $((m%800)) == 90 ]]; then
        graphs 730d
    elif [[ $((m%800)) == 170 ]]; then
        graphs 1095d
	fi

    if [[ $(date +%H:%M) == 00:07 ]]; then
        echo running scatter.sh
        /usr/share/graphs1090/scatter.sh
    fi
done
