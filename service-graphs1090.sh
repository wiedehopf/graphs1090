#!/bin/bash

echo "Generating all graphs"
/usr/share/graphs1090/boot.sh 0.4 &>/dev/null

graphs() {
	echo "Generating $1 graphs"
	/usr/share/graphs1090/graphs1090.sh $1 0.7 &>/dev/null
}

while sleep 10; do
	sec=$(date +%S)
	if [ $sec -lt 30 ] || [ $sec -gt 40 ]; then continue; fi

	m=$(date +%M | sed 's/0\([0-9]\)/\1/')
	h=$(date +%H)

	if [[ $(($m%4)) == 1 ]]; then
		graphs 1h
	elif [[ $(($m%4)) == 2 ]]; then
		graphs 6h
	elif [[ $(($m%4)) == 3 ]]; then
		graphs 24h
	elif [[ $(($m%8)) == 4 ]]; then
		graphs 48h
	elif [[ $m == 16 ]] || [[ $m == 48 ]]; then
		graphs 7d
	elif [[ $m == 24 ]]; then
		graphs 14d
	elif [[ $m == 32 ]]; then
		graphs 30d
	elif [[ $m == 40 ]]; then
		graphs 90d
	elif [[ $m == 56 ]]; then
		graphs 180d
	elif [[ $m == 0 ]]; then
		if [[ $h == 01 ]]; then
			graphs 365d
		elif [[ $h == 02 ]]; then
			graphs 730d
		elif [[ $h == 03 ]]; then
			graphs 1095d
		fi
	elif [[ $m == 8 ]]; then
		if [[ $h == 00 ]]; then
			/usr/share/graphs1090/scatter.sh
		fi
	fi
done
