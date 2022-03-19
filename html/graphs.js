//*** BEGIN USER DEFINED VARIABLES ***//

// Set the default time frame to use when loading images when the page is first accessed.
// Can be set to 2h, 8h, 24h, 7d, 30d, or 365d.
$timeFrame = '24h';

// Set this to the hostname of the system which is running dump1090.
$hostName = 'localhost';

// Set the page refresh interval in milliseconds.
$refreshInterval = 60000

//*** END USER DEFINED VARIABLES ***//


//*** DO NOT EDIT BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING ***//

$(document).ready(function () {
    // Display the images for the supplied time frame.
    switchView($timeFrame);

    // Refresh images contained within the page every X milliseconds.
    window.setInterval(function() {
        switchView($timeFrame)
    }, $refreshInterval);
});

function switchView(newTimeFrame) {
    // Set the the $timeFrame variable to the one selected.
    $timeFrame = newTimeFrame;

    // Set the timestamp variable to be used in querystring.
    $timestamp = Math.round(new Date().getTime() / 1000 / 15) * 15;

    // Display images for the requested time frame and create links to full sized images for the requested time frame.
    var element;
    $("#dump1090-local_trailing_rate-image").attr("src", "graphs/dump1090-" + $hostName + "-local_trailing_rate-" + $timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-local_trailing_rate-link").attr("href", "graphs/dump1090-" + $hostName + "-local_trailing_rate-" + $timeFrame + ".png?time=" + $timestamp);

    $("#dump1090-local_rate-image").attr("src", "graphs/dump1090-" + $hostName + "-local_rate-" + $timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-local_rate-link").attr("href", "graphs/dump1090-" + $hostName + "-local_rate-" + $timeFrame + ".png?time=" + $timestamp);

    $("#dump1090-aircraft_message_rate-image").attr("src", "graphs/dump1090-" + $hostName + "-aircraft_message_rate-" + $timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-aircraft_message_rate-link").attr("href", "graphs/dump1090-" + $hostName + "-aircraft_message_rate-" + $timeFrame + ".png?time=" + $timestamp);

    $("#dump1090-aircraft-image").attr("src", "graphs/dump1090-" + $hostName + "-aircraft-" + $timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-aircraft-link").attr("href", "graphs/dump1090-" + $hostName + "-aircraft-" + $timeFrame + ".png?time=" + $timestamp);

    $("#dump1090-tracks-image").attr("src", "graphs/dump1090-" + $hostName + "-tracks-" + $timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-tracks-link").attr("href", "graphs/dump1090-" + $hostName + "-tracks-" + $timeFrame + ".png?time=" + $timestamp);

    element =  document.getElementById('dump1090-range-image');
    if (typeof(element) != 'undefined' && element != null) {
        $("#dump1090-range-image").attr("src", "graphs/dump1090-" + $hostName + "-range-" + $timeFrame + ".png?time=" + $timestamp);
        $("#dump1090-range-link").attr("href", "graphs/dump1090-" + $hostName + "-range-" + $timeFrame + ".png?time=" + $timestamp);
    }

    element =  document.getElementById('dump1090-range_imperial_statute-image');
    if (typeof(element) != 'undefined' && element != null) {
        $("#dump1090-range_imperial_statute-image").attr("src", "graphs/dump1090-" + $hostName + "-range_imperial_statute-" + $timeFrame + ".png?time=" + $timestamp);
        $("#dump1090-range_imperial_statute-link").attr("href", "graphs/dump1090-" + $hostName + "-range_imperial_statute-" + $timeFrame + ".png?time=" + $timestamp);
    }

    element =  document.getElementById('dump1090-range_metric-image');
    if (typeof(element) != 'undefined' && element != null) {
        $("#dump1090-range_metric-image").attr("src", "graphs/dump1090-" + $hostName + "-range_metric-" + $timeFrame + ".png?time=" + $timestamp);
        $("#dump1090-range_metric-link").attr("href", "graphs/dump1090-" + $hostName + "-range_metric-" + $timeFrame + ".png?time=" + $timestamp);
    }

    $("#dump1090-signal-image").attr("src", "graphs/dump1090-" + $hostName + "-signal-" + $timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-signal-link").attr("href", "graphs/dump1090-" + $hostName + "-signal-" + $timeFrame + ".png?time=" + $timestamp);

    $("#dump1090-cpu-image").attr("src", "graphs/dump1090-" + $hostName + "-cpu-" + $timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-cpu-link").attr("href", "graphs/dump1090-" + $hostName + "-cpu-" + $timeFrame + ".png?time=" + $timestamp);

    $("#dump1090-misc-image").attr("src", "graphs/dump1090-" + $hostName + "-misc-" + $timeFrame + ".png?time=" + $timestamp);
    $("#dump1090-misc-link").attr("href", "graphs/dump1090-" + $hostName + "-misc-" + $timeFrame + ".png?time=" + $timestamp);

    if ($("#panel_airspy").css("display") !== "none") {
        $("#airspy-rssi-image").attr("src", "graphs/airspy-" + $hostName + "-rssi-" + $timeFrame + ".png?time=" + $timestamp);
        $("#airspy-rssi-link").attr("href", "graphs/airspy-" + $hostName + "-rssi-" + $timeFrame + ".png?time=" + $timestamp);

        $("#airspy-snr-image").attr("src", "graphs/airspy-" + $hostName + "-snr-" + $timeFrame + ".png?time=" + $timestamp);
        $("#airspy-snr-link").attr("href", "graphs/airspy-" + $hostName + "-snr-" + $timeFrame + ".png?time=" + $timestamp);

        $("#airspy-noise-image").attr("src", "graphs/airspy-" + $hostName + "-noise-" + $timeFrame + ".png?time=" + $timestamp);
        $("#airspy-noise-link").attr("href", "graphs/airspy-" + $hostName + "-noise-" + $timeFrame + ".png?time=" + $timestamp);

        $("#airspy-misc-image").attr("src", "graphs/airspy-" + $hostName + "-misc-" + $timeFrame + ".png?time=" + $timestamp);
        $("#airspy-misc-link").attr("href", "graphs/airspy-" + $hostName + "-misc-" + $timeFrame + ".png?time=" + $timestamp);

        $("#df_counts-image").attr("src", "graphs/df_counts-" + $hostName + "-" + $timeFrame + ".png?time=" + $timestamp);
        $("#df_counts-link").attr("href", "graphs/df_counts-" + $hostName + "-" + $timeFrame + ".png?time=" + $timestamp);
    }

	if ($("#panel_978").css("display") !== "none") {
		$("#dump1090-aircraft_978-image").attr("src", "graphs/dump1090-" + $hostName + "-aircraft_978-" + $timeFrame + ".png?time=" + $timestamp);
		$("#dump1090-aircraft_978-link").attr("href", "graphs/dump1090-" + $hostName + "-aircraft_978-" + $timeFrame + ".png?time=" + $timestamp);

		$("#dump1090-range_978-image").attr("src", "graphs/dump1090-" + $hostName + "-range_978-" + $timeFrame + ".png?time=" + $timestamp);
		$("#dump1090-range_978-link").attr("href", "graphs/dump1090-" + $hostName + "-range_978-" + $timeFrame + ".png?time=" + $timestamp);

		$("#dump1090-messages_978-image").attr("src", "graphs/dump1090-" + $hostName + "-messages_978-" + $timeFrame + ".png?time=" + $timestamp);
		$("#dump1090-messages_978-link").attr("href", "graphs/dump1090-" + $hostName + "-messages_978-" + $timeFrame + ".png?time=" + $timestamp);

		$("#dump1090-signal_978-image").attr("src", "graphs/dump1090-" + $hostName + "-signal_978-" + $timeFrame + ".png?time=" + $timestamp);
		$("#dump1090-signal_978-link").attr("href", "graphs/dump1090-" + $hostName + "-signal_978-" + $timeFrame + ".png?time=" + $timestamp);
	}

    $("#system-cpu-image").attr("src", "graphs/system-" + $hostName + "-cpu-" + $timeFrame + ".png?time=" + $timestamp);
    $("#system-cpu-link").attr("href", "graphs/system-" + $hostName + "-cpu-" + $timeFrame + ".png?time=" + $timestamp);

    element =  document.getElementById('system-eth0_bandwidth-image');
    if (typeof(element) != 'undefined' && element != null) {
        $("#system-eth0_bandwidth-image").attr("src", "graphs/system-" + $hostName + "-eth0_bandwidth-" + $timeFrame + ".png?time=" + $timestamp);
        $("#system-eth0_bandwidth-link").attr("href", "graphs/system-" + $hostName + "-eth0_bandwidth-" + $timeFrame + ".png?time=" + $timestamp);
    }
    element =  document.getElementById('system-network_bandwidth-image');
    if (typeof(element) != 'undefined' && element != null) {
        $("#system-network_bandwidth-image").attr("src", "graphs/system-" + $hostName + "-network_bandwidth-" + $timeFrame + ".png?time=" + $timestamp);
        $("#system-network_bandwidth-link").attr("href", "graphs/system-" + $hostName + "-network_bandwidth-" + $timeFrame + ".png?time=" + $timestamp);
    }
    
    $("#system-memory-image").attr("src", "graphs/system-" + $hostName + "-memory-" + $timeFrame + ".png?time=" + $timestamp);
    $("#system-memory-link").attr("href", "graphs/system-" + $hostName + "-memory-" + $timeFrame + ".png?time=" + $timestamp);

    element =  document.getElementById('system-temperature_imperial-image');
    if (typeof(element) != 'undefined' && element != null) {
        $("#system-temperature_imperial-image").attr("src", "graphs/system-" + $hostName + "-temperature_imperial-" + $timeFrame + ".png?time=" + $timestamp);
        $("#system-temperature_imperial-link").attr("href", "graphs/system-" + $hostName + "-temperature_imperial-" + $timeFrame + ".png?time=" + $timestamp);
    }
    element =  document.getElementById('system-temperature-image');
    if (typeof(element) != 'undefined' && element != null) {
        $("#system-temperature-image").attr("src", "graphs/system-" + $hostName + "-temperature-" + $timeFrame + ".png?time=" + $timestamp);
        $("#system-temperature-link").attr("href", "graphs/system-" + $hostName + "-temperature-" + $timeFrame + ".png?time=" + $timestamp);
    }

    $("#system-df_root-image").attr("src", "graphs/system-" + $hostName + "-df_root-" + $timeFrame + ".png?time=" + $timestamp);
    $("#system-df_root-link").attr("href", "graphs/system-" + $hostName + "-df_root-" + $timeFrame + ".png?time=" + $timestamp);

    $("#system-disk_io_iops-image").attr("src", "graphs/system-" + $hostName + "-disk_io_iops-" + $timeFrame + ".png?time=" + $timestamp);
    $("#system-disk_io_iops-link").attr("href", "graphs/system-" + $hostName + "-disk_io_iops-" + $timeFrame + ".png?time=" + $timestamp);

    $("#system-disk_io_octets-image").attr("src", "graphs/system-" + $hostName + "-disk_io_octets-" + $timeFrame + ".png?time=" + $timestamp);
    $("#system-disk_io_octets-link").attr("href", "graphs/system-" + $hostName + "-disk_io_octets-" + $timeFrame + ".png?time=" + $timestamp);

	// Set the button related to the selected time frame to active.
    $("#btn-2h").removeClass('active');
    $("#btn-8h").removeClass('active');
    $("#btn-24h").removeClass('active');
    $("#btn-48h").removeClass('active');
    $("#btn-7d").removeClass('active');
    $("#btn-14d").removeClass('active');
    $("#btn-30d").removeClass('active');
    $("#btn-90d").removeClass('active');
    $("#btn-180d").removeClass('active');
    $("#btn-365d").removeClass('active');
    $("#btn-730d").removeClass('active');
    $("#btn-1095d").removeClass('active');
    $("#btn-1825d").removeClass('active');
    $("#btn-3650d").removeClass('active');
    $("#btn-" + $timeFrame).addClass('active');
}
