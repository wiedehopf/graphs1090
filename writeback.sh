#!/bin/bash
set -e

GTMP=/var/lib/collectd/rrd/graphs1090-writeback-tmp
TARGET=/var/lib/collectd/rrd/localhost
BACKUP1=/var/lib/collectd/rrd/graphs1090-writeback-backup1
BACKUP2=/var/lib/collectd/rrd/graphs1090-writeback-backup2
RUNFOLDER=/run/collectd/localhost

echo "writing DB from $RUNFOLDER to disk"

find "$RUNFOLDER" -name '*.rrd' -exec gzip -f -1 '{}' '+'
cp -afT "$RUNFOLDER" "$GTMP"
rm -rf "$BACKUP2"

sync

mv -T "$BACKUP1" "$BACKUP2" || true
mv -T "$TARGET" "$BACKUP1"
mv -T "$GTMP" "$TARGET"

sync
