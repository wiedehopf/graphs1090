import collectd, sys
import json, math
from contextlib import closing
try:
    from urllib2 import urlopen, URLError
except ImportError:
    from urllib.request import urlopen, URLError
import time
import subprocess

if (sys.version_info > (3, 0)):
    def has_key(book, key):
        return (key in book)
else:
    def has_key(book, key):
        return book.has_key(key)


def handle_config(root):
    for child in root.children:
        instance_name = None

        if child.key == 'Instance':
            instance_name = child.values[0]
            url = None
            url_978 = None
            url_airspy = 'file:///run/airspy_adsb'
            url_signal = None
            for ch2 in child.children:
                if ch2.key == 'URL':
                    url = ch2.values[0]
                if ch2.key == 'URL_978':
                    url_978 = ch2.values[0]
                if ch2.key == 'URL_AIRSPY':
                    url_airspy = ch2.values[0]
                if ch2.key == 'URL_1090_SIGNAL':
                    url_signal = ch2.values[0]
            if url:
                collectd.register_read(callback=read_1090,
                                       data=(instance_name, 'localhost', url, url_airspy, url_signal),
                                       name='dump1090.' + instance_name,
                                       interval=60)
            else:
                collectd.warning('No dump1090 URL defined in /etc/collectd/collectd.conf for ' + instance_name)

            if url_978:
                collectd.register_read(callback=read_978,
                                       data=(instance_name, 'localhost', url_978),
                                       name='dump978.' + instance_name,
                                       interval=60)
            else:
                pass
                # silence this warning ...
                # collectd.warning('No 978 URL defined in /etc/collectd/collectd.conf for ' + instance_name)

        else:
            collectd.warning('Ignored config entry: ' + child.key)
            return

V=collectd.Values(host='', plugin='dump1090', time=0)

def dispatch_df(data, stats, name):
    if not has_key(stats, name):
        return
    if not has_key(stats, 'now'):
        return
    instance_name,host,url = data

    now = stats['now']
    df_counts = stats[name]

    for df in [0, 4, 5, 11, 16, 17, 18, 19, 20, 21]:
        V.dispatch(plugin_instance = instance_name,
                host = host,
                type = 'df_count_minute',
                type_instance = str(df),
                time = now,
                values = [df_counts[df]],
                interval = 60)

def dispatch_misc(now, data, stats, name, dispatch_type):
    if not has_key(stats, name):
        return
    instance_name,host,url = data

    subject = stats[name]

    V.dispatch(plugin_instance = instance_name,
            host = host,
            type = dispatch_type ,
            type_instance = name,
            time = now,
            values = [subject],
            interval = 60)

def dispatch_quartiles(data, stats, name):
    if not has_key(stats, name):
        return
    if not has_key(stats, 'now'):
        return

    now = stats['now']
    quart = stats[name]

    instance_name,host,url = data
    for index in ['min', 'p5', 'q1', 'median', 'q3', 'p95', 'max']:
        if has_key(quart, index):
            #collectd.warning(index + str(quart[index]))
            V.dispatch(plugin_instance = instance_name,
                    host = host,
                    type = 'airspy_' + name,
                    type_instance = index,
                    time = now,
                    values = [quart[index]],
                    interval = 60)

def read_airspy(data):
    instance_name, host, url, url_airspy = data
    data = (instance_name, host, url)


    try:
        #airspy cpu usage
        cmdString = "PID=$(systemctl show -p MainPID airspy_adsb | cut -f 2 -d=); cat /proc/$PID/task/*/stat | cut -d ' ' -f 14,15 && getconf CLK_TCK"
        if (sys.version_info > (3, 0)):
            p = subprocess.Popen(cmdString, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, text=True)
        else:
            p = subprocess.Popen(cmdString, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)

        out, err = p.communicate()

        ptime=0

        if p.returncode == 0 :
            out, clk_tck, _ = out.rsplit('\n', 2)
            out = out.split('\n')
            biggest = 0
            cycles = []
            firstLine = out[0]
            otherLines = out[1:]
            for i in firstLine.split(' '):
                cycles.append(int(i))
            for line in otherLines:
                inc = 0
                for i in line.split(' '):
                    cycles[inc] += int(i)
                    inc += 1

            times = [int(i*1000/int(clk_tck)) for i in cycles]
            ptime = sum(times)
            utime = times[0]
            stime = times[1]

            V.dispatch(plugin_instance = instance_name,
                       host=host,
                       type='dump1090_cpu',
                       type_instance='airspy',
                       time=time.time(),
                       values = [ptime])
    except Exception as error:
        #collectd.warning(str(error))
        pass

    try:
        with closing(urlopen(url_airspy + '/stats.json', None, 5.0)) as stats_file:
            stats = json.load(stats_file)
    except Exception as error:
        #collectd.warning(str(error))
        return

    dispatch_quartiles(data, stats, 'rssi')
    dispatch_quartiles(data, stats, 'snr')
    dispatch_quartiles(data, stats, 'noise')

    if has_key(stats,'now'):
        now = stats['now']
        dispatch_misc(now, data, stats, 'preamble_filter', 'airspy_misc')
        dispatch_misc(now, data, stats, 'samplerate', 'airspy_misc')
        dispatch_misc(now, data, stats, 'gain', 'airspy_misc')
        dispatch_misc(now, data, stats, 'lost_buffers', 'airspy_lost')
        dispatch_misc(now, data, stats, 'max_aircraft_count', 'airspy_aircraft')

    dispatch_df(data, stats, 'df_counts')


def handle_signal_stuff(data, stats, aircraft_data):
    instance_name, host, url = data

    try:
        if has_key(stats['last1min'],'adaptive'):
            stuff = stats['last1min']['adaptive']
            dispatch_misc(stats['last1min']['end'], data, stuff, 'gain_db', 'dump1090_misc')
        elif has_key(stats['last1min'],'gain_db'):
            stuff = stats['last1min']
            dispatch_misc(stats['last1min']['end'], data, stuff, 'gain_db', 'dump1090_misc')
        elif has_key(stats, 'gain_db') and has_key(stats, 'now'):
            dispatch_misc(stats['now'], data, stats, 'gain_db', 'dump1090_misc')
        elif has_key(stats['last1min'],'local') and has_key(stats['last1min']['local'],'gain_db'):
            stuff = stats['last1min']['local']
            dispatch_misc(stats['last1min']['end'], data, stuff, 'gain_db', 'dump1090_misc')
    except:
        collectd.warning(str(error))
        pass

    # Signal measurements - from the 1 min bucket
    if has_key(stats['last1min'],'local'):
        if has_key(stats['last1min']['local'],'signal'):
          V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_dbfs',
                   type_instance='signal',
                   time=stats['last1min']['end'],
                   values = [stats['last1min']['local']['signal']],
                   interval = 60)

        if False and has_key(stats['last1min']['local'],'peak_signal'):
          V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_dbfs',
                   type_instance='peak_signal',
                   time=stats['last1min']['end'],
                   values = [stats['last1min']['local']['peak_signal']],
                   interval = 60)

        if False and has_key(stats['last1min']['local'],'min_signal'):
          V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_dbfs',
                   type_instance='min_signal',
                   time=stats['last1min']['end'],
                   values = [stats['last1min']['local']['min_signal']],
                   interval = 60)

        if has_key(stats['last1min']['local'],'noise'):
          V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_dbfs',
                   type_instance='noise',
                   time=stats['last1min']['end'],
                   values = [stats['last1min']['local']['noise']],
                   interval = 60)

    #Signal measurements from the aircraft table

    signals = []

    for a in aircraft_data['aircraft']:
        if has_key(a,'rssi') and a['messages'] > 4 and a['seen'] < 30 :
            rssi = a['rssi']
            source = a.get('type',"")
            if (
                rssi > -49.4
                and not source.startswith('tisb')
                and not source.startswith('adsr')
            ):
                signals.append(rssi)

    signals.sort()

    if len(signals) > 0 :
        minimum = signals[0]
        quart1 = perc(0.25, signals)
        median = perc(0.50, signals)
        quart3 = perc(0.75, signals)
        maximum = signals[-1]

        V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_dbfs',
               type_instance='quart1',
               time=aircraft_data['now'],
               values = [quart1],
               interval = 60)

        V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_dbfs',
               type_instance='median',
               time=aircraft_data['now'],
               values = [median],
               interval = 60)

        V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_dbfs',
               type_instance='quart3',
               time=aircraft_data['now'],
               values = [quart3],
               interval = 60)

        V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_dbfs',
               type_instance='peak_signal',
               time=aircraft_data['now'],
               values = [maximum],
               interval = 60)

        V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_dbfs',
               type_instance='min_signal',
               time=aircraft_data['now'],
               values = [minimum],
               interval = 60)


    if has_key(stats['total'],'local'):
        if has_key(stats['total']['local'],'strong_signals'):
            V.dispatch(plugin_instance = instance_name,
                       host=host,
                       type='dump1090_messages',
                       type_instance='strong_signals',
                       time=stats['total']['end'],
                       values = [stats['total']['local']['strong_signals']],
                       interval = 60)



def read_1090(data):
    instance_name, host, url, url_airspy, url_signal = data
    data = (instance_name, host, url)

    #NaN rrd
    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_dbfs',
               type_instance='NaN',
               time=time.time(),
               values = [1])

    try:
        read_airspy((instance_name, host, url, url_airspy))
    except Exception as error:
        collectd.warning(str(error))
        pass

    try:
        with closing(urlopen(url + '/data/stats.json', None, 5.0)) as stats_file:
            stats = json.load(stats_file)

        with closing(urlopen(url + '/data/receiver.json', None, 5.0)) as receiver_file:
            receiver = json.load(receiver_file)

        if has_key(receiver,'lat'):
            rlat = float(receiver['lat'])
            rlon = float(receiver['lon'])
        else:
            rlat = rlon = None

        with closing(urlopen(url + '/data/aircraft.json', None, 5.0)) as aircraft_file:
            aircraft_data = json.load(aircraft_file)

        stats_signal = None
        aircraft_data_signal = None
        if url_signal:
            try:
                with closing(urlopen(url_signal + '/data/stats.json', None, 5.0)) as stats_file:
                    stats_signal = json.load(stats_file)
                with closing(urlopen(url_signal + '/data/aircraft.json', None, 5.0)) as aircraft_file:
                    aircraft_data_signal = json.load(aircraft_file)
            except:
                collectd.warning("Could not get data from " + url_signal)
                pass

    except Exception as error:
        collectd.warning(str(error))
        return

    if stats_signal and aircraft_data_signal:
        handle_signal_stuff(data, stats_signal, aircraft_data_signal)
    else:
        handle_signal_stuff(data, stats, aircraft_data)

    # Local message counts
    if has_key(stats['total'],'local'):
        counts = stats['total']['local']['accepted']

        V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_messages',
                   type_instance='local_accepted',
                   time=stats['total']['end'],
                   values = [sum(counts)])

        for i in range(len(counts)):
            V.dispatch(plugin_instance = instance_name,
                       host=host,
                       type='dump1090_messages',
                       type_instance='local_accepted_%d' % i,
                       time=stats['total']['end'],
                       values = [counts[i]])

    # Remote message counts
    if has_key(stats['total'],'remote'):
        counts = stats['total']['remote']['accepted']
        remote_total = sum(counts)
        if has_key(stats['total']['remote'],'basestation'):
            remote_total += stats['total']['remote']['basestation']
        V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_messages',
                   type_instance='remote_accepted',
                   time=stats['total']['end'],
                   values = [remote_total])
        for i in range(len(counts)):
            V.dispatch(plugin_instance = instance_name,
                       host=host,
                       type='dump1090_messages',
                       type_instance='remote_accepted_%d' % i,
                       time=stats['total']['end'],
                       values = [counts[i]])

    # Position counts
    posCount = stats['total']['cpr']['global_ok'] + stats['total']['cpr']['local_ok']
    if posCount == 0 and has_key(stats['total'],'position_count_total'):
        posCount = stats['total']['position_count_total']

    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_messages',
               type_instance='positions',
               time=stats['total']['end'],
               values = [posCount])

    # Tracks
    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_tracks',
               type_instance='all',
               time=stats['total']['end'],
               values = [stats['total']['tracks']['all']])
    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_tracks',
               type_instance='single_message',
               time=stats['total']['end'],
               values = [stats['total']['tracks']['single_message']])

    # CPU
    for k in stats['total']['cpu'].keys():
        V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_cpu',
                   type_instance=k,
                   time=stats['total']['end'],
                   values = [stats['total']['cpu'][k]])


    total = 0
    with_pos = 0
    max_range = 0
    mlat = 0
    tisb = 0
    gps = 0

    ranges = []

    for a in aircraft_data['aircraft']:
        if a['seen'] < 60: total += 1
        if has_key(a,'seen_pos') and a['seen_pos'] < 60:
            with_pos += 1
            if rlat is not None:
                distance = greatcircle(rlat, rlon, a['lat'], a['lon'])
            else:
                distance = 0

            if 'lat' in a.get('mlat', ()):
                mlat += 1
            elif 'lat' in a.get('tisb', ()):
                tisb += 1
            elif a.get('type') in [ 'adsb_icao', 'adsr_icao' ]:
                # ADS-B or ADS-R (can be uat) position, include in range statistics
                gps += 1
                ranges.append(distance)

    ranges.sort()

    if len(ranges) > 0:
        minimum = ranges[0]
        quart1 = perc(0.25, ranges)
        median = perc(0.50, ranges)
        quart3 = perc(0.75, ranges)
        max_range = ranges[-1]

        V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_range',
                   type_instance='quart1',
                   time=aircraft_data['now'],
                   values = [quart1])

        V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_range',
                   type_instance='median',
                   time=aircraft_data['now'],
                   values = [median])

        V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_range',
                   type_instance='quart3',
                   time=aircraft_data['now'],
                   values = [quart3])

        V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_range',
                   type_instance='minimum',
                   time=aircraft_data['now'],
                   values = [minimum])

    if has_key(stats['last1min'],'max_distance'):
        max_range = stats['last1min']['max_distance'];
    # max range is always dispatched, even if zero
    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_range',
               type_instance='max_range',
               time=aircraft_data['now'],
               values = [max_range])

    # Aircraft numbers

    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_aircraft',
               type_instance='recent',
               time=aircraft_data['now'],
               values = [total, with_pos])

    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_mlat',
               type_instance='recent',
               time=aircraft_data['now'],
               values = [mlat])

    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_tisb',
               type_instance='recent',
               time=aircraft_data['now'],
               values = [tisb])

    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_gps',
               type_instance='recent',
               time=aircraft_data['now'],
               values = [gps])

def read_978(data):
    instance_name,host,url = data
    try:
        with closing(urlopen(url + '/data/receiver.json', None, 5.0)) as receiver_file:
            receiver = json.load(receiver_file)

        if has_key(receiver,'lat'):
            rlat = float(receiver['lat'])
            rlon = float(receiver['lon'])
        else:
            rlat = rlon = None

        with closing(urlopen(url + '/data/aircraft.json', None, 5.0)) as aircraft_file:
            aircraft_data = json.load(aircraft_file)

    except URLError as error:
        #collectd.warning(str(error))
        return
    except Exception as error:
        collectd.warning(str(error))
        return

    total = 0
    with_pos = 0
    max_range = 0
    tisb = 0
    gps = 0

    ranges = []

    for a in aircraft_data['aircraft']:
        if a['seen'] < 60: total += 1
        if has_key(a,'seen_pos') and a['seen_pos'] < 60:
            with_pos += 1
            if rlat is not None:
                distance = greatcircle(rlat, rlon, a['lat'], a['lon'])
            else:
                distance = 0

            if 'lat' in a.get('tisb', ()):
                tisb += 1
            # GPS position, include in range statistics
            else:
                gps += 1
                # limit 978 data collection to 350 nmi (1 nmi = 1852 m)
                if distance < 350 * 1852:
                    ranges.append(distance)

    # Aircraft numbers
    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_aircraft',
               type_instance='recent_978',
               time=aircraft_data['now'],
               values = [total, with_pos])

    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_tisb',
               type_instance='recent_978',
               time=aircraft_data['now'],
               values = [tisb])

    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_gps',
               type_instance='recent_978',
               time=aircraft_data['now'],
               values = [gps])

    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_messages',
               type_instance='messages_978',
               time=aircraft_data['now'],
               values = [aircraft_data['messages']])

    # Range statistics
    ranges.sort()

    if len(ranges) > 0:
        minimum = ranges[0]
        quart1 = perc(0.25, ranges)
        median = perc(0.50, ranges)
        quart3 = perc(0.75, ranges)
        max_range = ranges[-1]

        V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_range',
                   type_instance='quart1_978',
                   time=aircraft_data['now'],
                   values = [quart1])

        V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_range',
                   type_instance='median_978',
                   time=aircraft_data['now'],
                   values = [median])

        V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_range',
                   type_instance='quart3_978',
                   time=aircraft_data['now'],
                   values = [quart3])

        V.dispatch(plugin_instance = instance_name,
                   host=host,
                   type='dump1090_range',
                   type_instance='minimum_978',
                   time=aircraft_data['now'],
                   values = [minimum])

    V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_range',
               type_instance='max_range_978',
               time=aircraft_data['now'],
               values = [max_range])

    # Signal Statistics

    signals = []

    for a in aircraft_data['aircraft']:
        if has_key(a,'rssi') and a['messages'] > 2 and a['seen'] < 60 :
            rssi = a['rssi']
            if rssi > -49.4 and not 'lat' in a.get('tisb', ()):
                # clamp rssi to 0
                if rssi > 0:
                    rssi = 0
                signals.append(rssi)

    signals.sort()

    if len(signals) > 0 :
        minimum = signals[0]
        quart1 = perc(0.25, signals)
        median = perc(0.50, signals)
        quart3 = perc(0.75, signals)
        maximum = signals[-1]

        V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_dbfs',
               type_instance='quart1_978',
               time=aircraft_data['now'],
               values = [quart1],
               interval = 60)

        V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_dbfs',
               type_instance='median_978',
               time=aircraft_data['now'],
               values = [median],
               interval = 60)

        V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_dbfs',
               type_instance='quart3_978',
               time=aircraft_data['now'],
               values = [quart3],
               interval = 60)

        V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_dbfs',
               type_instance='peak_signal_978',
               time=aircraft_data['now'],
               values = [maximum],
               interval = 60)

        V.dispatch(plugin_instance = instance_name,
               host=host,
               type='dump1090_dbfs',
               type_instance='min_signal_978',
               time=aircraft_data['now'],
               values = [minimum],
               interval = 60)

def greatcircle(lat0, lon0, lat1, lon1):
    lat0 = lat0 * math.pi / 180.0;
    lon0 = lon0 * math.pi / 180.0;
    lat1 = lat1 * math.pi / 180.0;
    lon1 = lon1 * math.pi / 180.0;
    return 6371e3 * math.acos(math.sin(lat0) * math.sin(lat1) + math.cos(lat0) * math.cos(lat1) * math.cos(abs(lon0 - lon1)))

def T(provisional):
    now = time.time()
    if provisional <= now + 60: return provisional
    else: return now

def perc(p, values):
    l = len(values)
    x = p * (l-1)
    d = x - int(x)
    x = int(x)
    if x+1 < l:
        res = values[x] + d * (values[x+1] - values[x])
    else:
        res = values[x]
    return res

collectd.register_config(callback=handle_config, name='dump1090')
