![Screenshot](https://raw.githubusercontent.com/wiedehopf/graphs1090/screenshots/screenshot1.png)
![Screenshot](https://raw.githubusercontent.com/wiedehopf/graphs1090/screenshots/screenshot2.png)

# graphs1090
![Screenshot](https://raw.githubusercontent.com/wiedehopf/graphs1090/screenshots/messages_24h.png)
Graphs for readsb (wiedehopf fork) and dump1090-fa (based on dump1090-tools by mutability)

Also works for other dump1090 variants supplying stats.json

## Installation / Update to current version:
```
sudo bash -c "$(curl -L -o - https://github.com/wiedehopf/graphs1090/raw/master/install.sh)"
```

Note on data loss: When removing or losing power you will lose graph data generated after 23:42 of the previous day.
To avoid that issue `sudo shutdown now` before unplugging the pi. See the section on reducing writes for more detail.

## Configuration (optional):
Edit the configuration file to change graph layout options, for example size:
```
sudo nano /etc/default/graphs1090
```
Ctrl-x to exit, y (yes) and enter to save.

Reset configuration to defaults:
```
sudo cp /usr/share/graphs1090/default-config /etc/default/graphs1090
```


## View the graphs:

Click the following URL and replace the IP address with the IP address of the Raspberry Pi you installed combine1090 on.

http://192.168.x.yy/graphs1090

or

http://192.168.x.yy/perf

### Adjusting gain

The fine tuning is up to taste but quite a few setups are using way too much gain (AGC is maximum gain it does not work as intended for ADS-B).
Thus i'll link some guidelines on how to set your gain: https://github.com/wiedehopf/adsb-scripts/wiki/Optimizing-gain
If you can't be bothered and would rather use something automatic: https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-gain-optimization-for-readsb-and-dump1090-fa

### Range graph isn't working

You need to configure the location in your decoder (dump1090-fa / readsb).

My install scripts for either of them provide a handy command line utility:
 - https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-installation-for-readsb
 - https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-installation-for-dump1090-fa

Otherwise you'll have to configure the location by editing /etc/default/dump1090-fa or /etc/default/readsb.
For the adsbx image the location is configured in /boot/adsb-config.txt.
For the piaware image you'll need to configure the location on the online FA stats page.

### Reducing writes to the sd-card (enabled by default)

To reduce writes to the sd-card, data is only written to the sd-card every 24h.
Note on data loss: When removing or losing power you will lose graph data generated after 23:42 of the previous day.
To avoid that issue `sudo shutdown now` before unplugging the pi. See the section on reducing writes for more detail.
Reboots or shutdowns are not an issue and don't cause data loss.

If you want to change how often the data is written to disk, edit `/etc/cron.d/collectd_to_disk` and replace the content with one of the following options:
(updating / running the graphs1090 install script will overwrite this to the default)
```

# every day at 23:42
42 23 * * * root /bin/systemctl restart collectd

# every Sunday
42 23 * * 0 root /bin/systemctl restart collectd

# every 6 hours
42 */6 * * * root /bin/systemctl restart collectd
```

To disable this behaviour use this command:
```
sudo bash /usr/share/graphs1090/git/stopMalarky.sh
```

To re-enable the behavrious use this command:
```
sudo bash /usr/share/graphs1090/git/malarky.sh
```

Explanation on how the above works:
The configuration of the systemd service is changed so it manages the graph data in /run (memory) and only writes it to disk every night.
On reboot / shutdown it's written to disk and the data loaded to /run again when the system boots back up.
Up to 24h of data is lost when there is a power loss.

This has been working well and i have made it the default as many people are concerned about wearing out sd-cards.

### Reducing writes to the sd-card (in case you have the above disabled, works system wide)

The rrd databases get written to every minute, this adds up to around 100 Megabytes written per hour.
While most modern SD-cards should handle this for 10 or more years easily, you can reduce the amount written if you want to.
Per default linux writes data to disk after a maximum of 30 seconds in the cache.
Increasing this to 10 minutes reduces actual disk writes to around 10 Megabytes per hour.

Don't change this if you handle data on the Raspberry Pi which you don't want to lose the last 10 minutes of.

Increasing this write delay to 10 minutes can be done like this (takes effect after reboot):
```
sudo tee /etc/sysctl.d/07-dirty.conf <<EOF
vm.dirty_ratio = 40
vm.dirty_background_ratio = 30
vm.dirty_expire_centisecs = 60000
EOF
```

Because i don't mind losing data on my Raspberry Pi when it loses power, i have set this to one hour:
```
sudo tee /etc/sysctl.d/07-dirty.conf <<EOF
vm.dirty_ratio = 40
vm.dirty_background_ratio = 30
vm.dirty_expire_centisecs = 360000
EOF
```


### Non-standard configuration:

If your local map is not reachable at /dump1090-fa or /dump1090, you can edit the following the file to input the URL of your local map:

```/etc/collectd/collectd.conf```

Find this section:

```
<Plugin python>
        ModulePath "/usr/share/graphs1090"
        LogTraces true
        Import "dump1090"
        <Module dump1090>
                <Instance localhost>
                        URL "http://localhost/dump1090-fa"
                </Instance>
        </Module>
</Plugin>
```
And change the URL to where your dump1090 webinterface is located.
After changing the URL, restart collectd:
```
sudo systemctl restart collectd
```

### Resetting the database format

This might be a good idea if you changed from the adsb receiver project graphs and kept the data.
Also if you upgraded at a somewhen July 15th to July 16th 2019. Had a bad setting removing maximum data keeping for some part of the data.

```
sudo bash -c "$(curl -L -o - https://github.com/wiedehopf/graphs1090/raw/master/install.sh)"
sudo apt update
sudo apt install -y screen
sudo screen /usr/share/graphs1090/new-format.sh
```

### Reporting issues:

Please include the output for the following commands in error reports:
```
sudo systemctl restart collectd
sudo journalctl --no-pager -u collectd | tail -n40
sudo /usr/share/graphs1090/graphs1090.sh
sudo systemctl restart graphs1090
```
Paste the output into a pastebin: https://pastebin.com/
Then include the link and be sure to also describe the issue and also mention your system (debian / ubuntu / raspbian and RPi vs x86).

For errors like 404 or the pages not being available in the browser, do the same pastebin stuff for the output of these commands:
```
sudo systemctl restart lighttpd
sudo journalctl --no-pager -u lighttpd
ls /etc/lighttpd/conf-enabled
```


### Known bugs:

##### disk graphs with kernel >= 4.19 don't work due to a collectd bug
https://github.com/collectd/collectd/issues/2951

possible sollution: install new collectd version (only on Raspberry pi, if you are using another architecture, this package won't work)
```
wget -O /tmp/collectd.deb http://raspbian.raspberrypi.org/raspbian/pool/main/c/collectd/collectd-core_5.8.1-1.3_armhf.deb
sudo dpkg -i /tmp/collectd.deb
```


### Deinstallation:
```
sudo bash /usr/share/graphs1090/uninstall.sh
```

### nginx configuration:

Add the following line
```
include /usr/share/graphs1090/nginx-graphs1090.conf;
```
in the server { } section of either `/etc/nginx/sites-enabled/default` or `/etc/nginx/conf.d/default.conf` depending on your system configuration.

Don't forget to restart the nginx service.

### Removing 978 graphs + data

```
sudo systemctl stop collectd
sudo rm /var/lib/collectd/rrd/localhost/dump1090-localhost/*978*
sudo systemctl restart collectd graphs1090
```

### Hiding / showing 1090 graphs

(might only work after an update to the version this was introduced (December 2020))

```
# Hide:
sudo sed -i -e 's/id="panel_1090" style="display:block"/id="panel_1090" style="display:none"/' /usr/share/graphs1090/html/index.html
# Show:
sudo sed -i -e 's/id="panel_1090" style="display:none"/id="panel_1090" style="display:block"/' /usr/share/graphs1090/html/index.html
```


### no http config

in collectd.conf:
```
  URL "file:///usr/local/share/dump1090-data"
```
commands:
```
sudo mkdir -p /usr/local/share/dump1090-data
sudo ln -s /run/dump1090-fa /usr/local/share/dump1090-data/data
```


### Backup and Restore (same architecture)

```
cd /var/lib/collectd/rrd
sudo /usr/share/graphs1090/gunzip.sh /var/lib/collectd/rrd/localhost
sudo tar cf rrd.tar localhost
cp rrd.tar /tmp
```
Backup this file:
```
/tmp/rrd.tar
```

I'm not exactly sure how you would do that on Windows.
Probably with FileZilla using the SSH/SCP protocol.

Install graphs1090 if you haven't already.

On the new card copy the file to /tmp using FileZilla again.

Then copy it back to its place like this:
```
sudo mkdir -p /var/lib/collectd/rrd/
cd /var/lib/collectd/rrd
sudo cp /tmp/rrd.tar /var/lib/collectd/rrd/
sudo systemctl stop collectd
sudo /usr/share/graphs1090/gunzip.sh /var/lib/collectd/rrd/localhost
sudo tar xf rrd.tar
sudo systemctl restart collectd graphs1090
```

This should be all that is required, no guarantees though!

### Backup and Restore (different architecture, for example moving from RPi to x86 or the other way around)

Basically the same procedure as above, but with this difference:

Before doing the backup, run this command:

```
sudo /usr/share/graphs1090/rrd-dump.sh /var/lib/collectd/rrd/localhost/
```

This creates XML files from the database files in the same directory which can be later restored to database files on the target system.

Complete the process described above (backup the folder, then copy it back to its place on the new card).
Now run this command:

```
sudo /usr/share/graphs1090/rrd-restore.sh /var/lib/collectd/rrd/localhost/
```

Again no guarantees, but this should work.

### Issues with some collectd versions

Symptom: collectd doesn't work, error looks something like this in the syslog:
```
collectd[16507]: Traceback (most recent call last):
collectd[16507]: File "/usr/lib/python2.7/site.py", line 554, in <module>
```

Possible solution:

```
echo "LD_PRELOAD=/usr/lib/python3.8/config-3.8-x86_64-linux-gnu/libpython3.8.so" | sudo tee -a /etc/default/collectd
sudo systemctl restart collectd
```

Undoing the solution if the logs still show failure or when the issue has been fixed in the package provided by your distribution.
```
sudo sed -i -e 's#LD_PRELOAD=/usr/lib/python3.8.*##' /etc/default/collectd
sudo systemctl restart collectd
```


### Wipe the database (delete ALL DATA !!! be certain you want this)

```
sudo systemctl stop collectd
sudo rm /var/lib/collectd/rrd/localhost -rf
sudo systemctl restart collectd graphs1090
```
