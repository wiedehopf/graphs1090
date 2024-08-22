#!/usr/bin/python3
import sys

limit = None
if len(sys.argv) == 2:
    limit = float(sys.argv[1])

if limit is None:
    sys.stderr.write('Syntax: ' + sys.argv[0] + ' <prune limit> (reads rrdtool dump xml from stdin, outputs to stdout)\n')
    sys.exit(1)

pruneCount = 0

while line := sys.stdin.readline():
    #<!-- 2024-08-20 17:26:00 CEST / 1724167560 --> <row><v>3.5751600000e+05</v></row>
    prefix = '<row><v>'
    postfix = '</v></row>'
    prefixStart = line.find(prefix)
    end = line.find(postfix)
    if prefixStart != -1 and end != -1:
        start = prefixStart + len(prefix)
        num = line[start : end]
        value = float(num)
        if (value > limit):
            pruneCount += 1
            line = line[0 : start] + 'NaN' + postfix + '\n'
    sys.stdout.write(line)


sys.stderr.write(f'pruned {pruneCount} values\n')
