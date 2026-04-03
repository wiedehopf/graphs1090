//*** BEGIN USER DEFINED VARIABLES ***//

// Set the default time frame to use when loading images when the page is first accessed.
// Can be set to 2h, 8h, 24h, 7d, 30d, or 365d.
let timeFrame = '24h';

// Set the page refresh interval in milliseconds.
let refreshInterval = 60000

//*** END USER DEFINED VARIABLES ***//

// Set this to the hostName of the system which is running dump1090.
let hostName = 'localhost';

let usp;
try {
    // let's make this case insensitive
    usp = {
        params: new URLSearchParams(),
        has: function(s) {return this.params.has(s.toLowerCase());},
        get: function(s) {
            let val = this.params.get(s.toLowerCase());
            if (val) {
                // make XSS a bit harder
                val = val.replace(/[<>#&]/g, '');
            }
            return val;
        },
        getFloat: function(s) {
            if (!this.params.has(s.toLowerCase())) return null;
            const param = this.params.get(s.toLowerCase());
            if (!param) return null;
            const val = parseFloat(param);
            if (isNaN(val)) return null;
            return val;
        },
        getInt: function(s) {
            if (!this.params.has(s.toLowerCase())) return null;
            const param = this.params.get(s.toLowerCase());
            if (!param) return null;
            const val = parseInt(param, 10);
            if (isNaN(val)) return null;
            return val;
        }
    };
    const inputParams = new URLSearchParams(window.location.search);
    for (const [k, v] of inputParams) {
        usp.params.append(k.toLowerCase(), v);
    }
} catch (error) {
    console.error(error);
    usp = {
        has: function() {return false;},
        get: function() {return null;},
    }
}

if (usp.get('refreshInterval')) {
    refreshInterval = usp.get('refreshInterval') * 1000;
}

if (usp.get('timeframe')) {
    timeFrame = usp.get('timeframe');
}

//*** DO NOT EDIT BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING ***//

function setGraph(id, src) {
    const img = document.getElementById(id + '-image');
    const link = document.getElementById(id + '-link');
    if (img) img.src = src;
    if (link) link.href = src;
}

function switchView(newTimeFrame) {
    clearTimeout(refreshTimer);
    refreshTimer = setTimeout(switchView, refreshInterval);

    if (newTimeFrame) {
        timeFrame = newTimeFrame;
    }

    const timestamp = Math.round(new Date().getTime() / 1000 / 15) * 15;

    function graphUrl(source, metric) {
        return `graphs/${source}-${hostName}-${metric}-${timeFrame}.png?time=${timestamp}`;
    }

    setGraph('dump1090-local_trailing_rate', graphUrl('dump1090', 'local_trailing_rate'));
    setGraph('dump1090-local_rate',          graphUrl('dump1090', 'local_rate'));
    setGraph('dump1090-aircraft_message_rate', graphUrl('dump1090', 'aircraft_message_rate'));
    setGraph('dump1090-aircraft',            graphUrl('dump1090', 'aircraft'));
    setGraph('dump1090-tracks',              graphUrl('dump1090', 'tracks'));
    setGraph('dump1090-signal',              graphUrl('dump1090', 'signal'));
    setGraph('dump1090-cpu',                 graphUrl('dump1090', 'cpu'));
    setGraph('dump1090-misc',                graphUrl('dump1090', 'misc'));

    if (document.getElementById('dump1090-range-image'))
        setGraph('dump1090-range', graphUrl('dump1090', 'range'));
    if (document.getElementById('dump1090-range_imperial_statute-image'))
        setGraph('dump1090-range_imperial_statute', graphUrl('dump1090', 'range_imperial_statute'));
    if (document.getElementById('dump1090-range_metric-image'))
        setGraph('dump1090-range_metric', graphUrl('dump1090', 'range_metric'));

    const panelAirspy = document.getElementById('panel_airspy');
    if (panelAirspy && panelAirspy.style.display !== 'none') {
        setGraph('airspy-rssi',  graphUrl('airspy', 'rssi'));
        setGraph('airspy-snr',   graphUrl('airspy', 'snr'));
        setGraph('airspy-noise', graphUrl('airspy', 'noise'));
        setGraph('airspy-misc',  graphUrl('airspy', 'misc'));
        setGraph('df_counts', `graphs/df_counts-${hostName}-${timeFrame}.png?time=${timestamp}`);
    }

    const panel978 = document.getElementById('panel_978');
    if (panel978 && panel978.style.display !== 'none') {
        setGraph('dump1090-aircraft_978', graphUrl('dump1090', 'aircraft_978'));
        setGraph('dump1090-range_978',    graphUrl('dump1090', 'range_978'));
        setGraph('dump1090-messages_978', graphUrl('dump1090', 'messages_978'));
        setGraph('dump1090-signal_978',   graphUrl('dump1090', 'signal_978'));
    }

    const panelSystem = document.getElementById('panel_system');
    if (panelSystem && panelSystem.style.display !== 'none') {
        setGraph('system-cpu',             graphUrl('system', 'cpu'));
        setGraph('system-memory',          graphUrl('system', 'memory'));
        setGraph('system-df_root',         graphUrl('system', 'df_root'));
        setGraph('system-disk_io_iops',    graphUrl('system', 'disk_io_iops'));
        setGraph('system-disk_io_octets',  graphUrl('system', 'disk_io_octets'));

        if (document.getElementById('system-eth0_bandwidth-image'))
            setGraph('system-eth0_bandwidth', graphUrl('system', 'eth0_bandwidth'));
        if (document.getElementById('system-network_bandwidth-image'))
            setGraph('system-network_bandwidth', graphUrl('system', 'network_bandwidth'));
        if (document.getElementById('system-temperature_imperial-image'))
            setGraph('system-temperature_imperial', graphUrl('system', 'temperature_imperial'));
        if (document.getElementById('system-temperature-image'))
            setGraph('system-temperature', graphUrl('system', 'temperature'));
    }

    // Update active button
    document.querySelectorAll('.btn-group .btn').forEach(btn => btn.classList.remove('active'));
    document.getElementById('btn-' + timeFrame)?.classList.add('active');

    const pathName = window.location.pathname.replace(/\/+/, '/') || '/';
    window.history.replaceState(null, '', window.location.origin + pathName + '?timeframe=' + timeFrame);
}

let verbose = true;
let refreshTimer = null;
let timersActive = false;

function handleVisibilityChange() {
    if (document.hidden && timersActive) {
        verbose && console.log(new Date().toLocaleTimeString() + ' visibility change: stopping timers');
        clearTimeout(refreshTimer);
        timersActive = false;
    }
    if (!document.hidden && !timersActive) {
        verbose && console.log(new Date().toLocaleTimeString() + ' visibility change: starting timers');
        timersActive = true;
        switchView();
    }
}

if (typeof document.addEventListener === 'undefined' || document.hidden === undefined) {
    console.error('hidden tab handler requires a browser that supports the Page Visibility API.');
} else {
    document.addEventListener('visibilitychange', handleVisibilityChange, false);
}

handleVisibilityChange();

const cursorVT = document.querySelector('.vt');
const cursorHL = document.querySelector('.hl');

function crosshairListener(e) {
    cursorVT.style.left = e.clientX + 'px';
    cursorHL.style.top = e.clientY + 'px';
}

function isDarkTheme() {
    return document.documentElement.dataset.theme === 'dark';
}

function toggleTheme() {
    const next = isDarkTheme() ? 'light' : 'dark';
    document.documentElement.dataset.theme = next;
    localStorage.setItem('theme', next);
    updateThemeButton();
}

function updateThemeButton() {
    const btn = document.getElementById('theme-toggle');
    if (!btn) return;
    btn.textContent = isDarkTheme() ? '☀ Light' : '☾ Dark';
}

updateThemeButton();

function toggleCrosshair() {
    const crosshairEl = document.getElementById('crosshair');
    const show = crosshairEl.style.display === 'none';
    crosshairEl.style.display = show ? 'block' : 'none';
    if (show) {
        document.addEventListener('mousemove', crosshairListener);
    } else {
        document.removeEventListener('mousemove', crosshairListener);
    }
}
