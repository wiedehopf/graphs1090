#!/bin/bash

echo "Generating all graphs"
/usr/share/graphs1090/boot.sh 0.4 &>/dev/null

graphs() {
	echo "Generating $1 graphs"
	/usr/share/graphs1090/graphs1090.sh $1 0.7 &>/dev/null
}
counter=0
hour_done=0

while sleep 5; do
	counter=$((counter+1))
	if [[ $((counter%10)) != 0 ]]; then
		continue
	fi
	m=$(((counter/10)%80))

	minutes=$(date +%M | sed 's/0\([0-9]\)/\1/')
	h=$(date +%H)

	if [[ $counter == 1000 ]]; then
		counter=0
	fi

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
	elif [[ $m == 10 ]] || [[ $m == 40 ]] || [[ $m == 70 ]]; then
		graphs 7d
	elif [[ $m == 20 ]]; then
		graphs 14d
	elif [[ $m == 30 ]]; then
		graphs 30d
	elif [[ $m == 50 ]]; then
		graphs 90d
	elif [[ $m == 60 ]]; then
		graphs 180d
	fi

	if [[ $minutes == 8 ]] && [[ $hour_done == 0 ]]; then
		hour_done=1
		if [[ $h == 01 ]]; then
			graphs 365d
		elif [[ $h == 02 ]]; then
			graphs 730d
		elif [[ $h == 03 ]]; then
			graphs 1095d
		elif [[ $h == 00 ]]; then
			/usr/share/graphs1090/scatter.sh
		fi
	fi
	if [[ $minutes == 0 ]]; then
		hour_done=0
	fi

done
