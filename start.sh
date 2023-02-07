#! /bin/bash

# Config file moves transferred from Dockerfile to support
# binding /etc/apcupsd to user-specified host directory

cp /opt/apcupsd/apcupsd /etc/default/apcupsd

# Check if /etc/apcupsd files exist, and copy them from /opt/apcupsd if they don't
files=( apcupsd.conf hosts.conf doshutdown apccontrol changeme commfailure commok killpower multimon.conf offbattery onbattery ups-monitor )

for i in "${files[@]}"
  do
    if [ ! -f /etc/apcupsd/$i ]; then
      cp /opt/apcupsd/$i /etc/apcupsd/$i \
      && echo "No existing $i found"
    else
      echo "Existing $i found, and will be used"
    fi
  done

# First, add an extra # to the second UPSNAME used for EPROM updates
sed -i 's/^#UPSNAME UPS_IDEN/##UPSNAME UPS_IDEN/' /etc/apcupsd/apcupsd.conf

# Check if environment variables are set, and if so update apcupsd.conf
settings=( "UPSNAME" "UPSCABLE" "UPSTYPE" "DEVICE" "POLLTIME" "NETSERVER" "NISIP" "NISPORT" "ONBATTERYDELAY" "BATTERYLEVEL" "MINUTES" "TIMEOUT" "SELFTEST" )

for i in ${settings[@]}
  do
    if [ ! -z ${!i} ]; then
      sed -i -r 's/(^'"$i"'.*|^#'"$i"'.*)/'"$i"' '"${!i}"'/' /etc/apcupsd/apcupsd.conf \
      && awk '$1 ~ /^'"$i"'/' /etc/apcupsd/apcupsd.conf
    fi
  done

/sbin/apcupsd -b
