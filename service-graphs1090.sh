#!/bin/bash

/usr/share/graphs1090/boot.sh 0.4

graphs() {
	/usr/share/graphs1090/graphs1090.sh $1 0.9
}

while sleep 10; do
	if [ $(date +%S) -gt 10 ]; then continue; fi

	m=$(date +%M)
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
		if [[ $h == 1 ]]; then
			graphs 365d
		elif [[ $h == 2 ]]; then
			graphs 730d
		elif [[ $h == 3 ]]; then
			graphs 1095d
		fi
	fi
done
