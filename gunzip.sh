#!/bin/bash
find /var/lib/collectd/rrd/localhost -name '*.gz' -exec gunzip '{}' \+
