#!/bin/bash

mkdir -p /run/graphs1090

sleep 15

for i in 1h 6h 24h 48h 7d 14d 30d 90d 180d 365d 730d 1095d
do
	/usr/share/graphs1090/graphs1090.sh $i
	sleep 2
done
