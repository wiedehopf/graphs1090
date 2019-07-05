import collectd
import math
import time
import subprocess

def handle_config(root):

    collectd.register_read(callback=handle_read, name='system_stats')

V=collectd.Values(plugin='system_stats', time=0)


def handle_read():

    try:
        f=open("/proc/meminfo", "r")
        contents=f.read()
    except:
        collectd.warning(sys.exc_info()[0])
        return

    data = {}
    for line in contents.split('\n'):
        words = line.split()
        if len(words) > 1 :
            data[words[0].split(':')[0]] =  words[1]

    # getting some useful figures as described here https://stackoverflow.com/a/41251290
    # calculation like htop

    total = 1024 * int(data['MemTotal'])
    free = 1024 * int(data['MemFree'])
    buffers = 1024 * int(data['Buffers'])
    cached = 1024 * (int(data['Cached']) + int(data['SReclaimable']) - int(data['Shmem']))
    used = total - free - buffers - cached

    V.dispatch(type='memory',
               type_instance='used',
               time=time.time(),
               values = [used])
    V.dispatch(type='memory',
               type_instance='buffers',
               time=time.time(),
               values = [buffers])
    V.dispatch(type='memory',
               type_instance='cached',
               time=time.time(),
               values = [cached])
    V.dispatch(type='memory',
               type_instance='free',
               time=time.time(),
               values = [free])

    return

collectd.register_config(callback=handle_config, name='system_stats')
