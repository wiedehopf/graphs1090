#!/bin/bash
set -e

GTMP=/var/lib/collectd/rrd/graphs1090-writeback-tmp
TARGET=/var/lib/collectd/rrd/localhost
BACKUP1=/var/lib/collectd/rrd/graphs1090-writeback-backup1
BACKUP2=/var/lib/collectd/rrd/graphs1090-writeback-backup2

cp -afT /run/collectd/localhost "$GTMP"
rm -rf "$BACKUP2"

sync

mv -T "$BACKUP1" "$BACKUP2" || true
mv -T "$TARGET" "$BACKUP1"
mv -T "$GTMP" "$TARGET"

sync
