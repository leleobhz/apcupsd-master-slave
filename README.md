# apcupsd-master-slave
This is a simple Ubuntu base with <code>apcupsd</code> installed. It manages and monitors a USB Connected UPS Device, and has the ability to gracefully shut down the host computer in the event of a prolonged power outage.  This is done with no customization to the host whatsoever, there's no need for cron jobs on the host, or trigger files and scripts.  Everything is done within the container.

### Use Cases:
Use this image if your UPS is connected to your docker host by USB Cable and you don't want to run <code>apcupsd</code> in the physical host OS.

Equally, this container can be run on any other host (SLAVE) to monitor another instance of this container running on a host (MASTER) connected to the UPS for power status messages from the UPS, and take action to gracefully shut down the non-UPS connected host.

The purpose of this image is to containerise the APC UPS monitoring daemon so that it is separated from the OS, yet still has access to the UPS via USB Cable.  

### Configuration:

Very little configuration is currently required for this image to work, though you may be required to tweak the USB device that is passed through to your container by docker.

Portainer is the recommended tool here, and makes maintaining and updating this conatiner substantially easier -- particularly if you have multiple APC UPS units, and multiple other systems you wish to be shutdown when power is lost.

Below is the "full" annotated docker-compose for Portainer-Stacks, for use with either an apcupsd MASTER (i.e. connected to the UPS) or SLAVE (i.e. using input from another apcupsd daemon to determine shutdown). The healthcheck section is optional, but polls the status the UPS connection in the case of a standalone or MASTER connected system, or the status of the connection to the MASTER in the case of a SLAVE system.:

#### Fully annotated docker-compose for STANDALONE, MASTER or SLAVE use (Portainer-Stacks recommended):

```yml
version: '3.7'
services:
  apcupsd:
    image: bnhf/apcupsd:latest
    container_name: apcupsd
    devices:
      - /dev/usb/hiddev0 # This device needs to match what the APC UPS on your APCUPSD_MASTER system uses -- Comment out this section on APCUPSD_SLAVES
    ports:
      - 3551:3551
    environment:
      - UPSNAME=${UPSNAME} # Sets a name for the UPS (1 to 8 chars), that will be used by System Tray notifications, apcupsd-cgi and Grafana dashboards
#      - UPSCABLE=${UPSCABLE} # Usually doesn't need to be changed on system connected to UPS. (default=usb) On APCUPSD_SLAVES set the value to ether
#      - UPSTYPE=${UPSTYPE} # Usually doesn't need to be changed on system connected to UPS. (default=usb) On APCUPSD_SLAVES set the value to net
#      - DEVICE=${DEVICE} # Use this only on APCUPSD_SLAVES to set the hostname or IP address of the APCUPSD_MASTER with the listening port (:3551)
#      - POLLTIME=${POLLTIME} # Interval (in seconds) at which apcupsd polls the UPS for status (default=60)
#      - ONBATTERYDELAY=${ONBATTERYDELAY} # Sets the time in seconds from when a power failure is detected until an onbattery event is initiated (default=6)
#      - BATTERYLEVEL=${BATTERYLEVEL} # Sets the daemon to send the poweroff signal when the UPS reports a battery level of x% or less (default=5)
#      - MINUTES=${MINUTES} # Sets the daemon to send the poweroff signal when the UPS has x minutes or less remaining power (default=5)
#      - TIMEOUT=${TIMEOUT} # Sets the daemon to send the poweroff signal when the UPS has been ON battery power for x seconds (default=0)
#      - SELFTEST=${SELFTEST} # Sets the daemon to ask the UPS to perform a self test every x hours (default=336)
#      - APCUPSD_HOSTS=${APCUPSD_HOSTS} # If this is the MASTER, then enter the APUPSD_HOSTS list here, including this system (space separated)
#      - APCUPSD_NAMES=${APCUPSD_NAMES} # Match the order of this list one-to-one to APCUPSD_HOSTS list, including this system (space separated)
      - TZ=${TZ}
    healthcheck:
      test: ["CMD-SHELL", "apcaccess | grep -E 'ONLINE' >> /dev/null"] # Command to check health
      interval: 30s # Interval between health checks
      timeout: 5s # Timeout for each health check
      retries: 3 # How many times to retry
      start_period: 15s # Estimated time to boot
    volumes:
      - /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket # Required to support host shutdown from the container
      - /data/apcupsd:/etc/apcupsd # /etc/apcupsd can be bound to a directory or a docker volume
    restart: unless-stopped
# volumes: # Use this section for volume bindings only
#   config: # The name of the stack will be appended to the beginning of this volume name, if the volume doesn't already exist
#     external: true # Use this directive if you created the docker volume in advance
```
Environment variables can be hardcoded into the above docker-compose, or added in the environment section of Portainer. Switch to "Advanced Mode" in Portainer-Stacks in the "Environment variables" section, and paste in the below, to get all of the possible variables in place. Put in your values in place of ${whatever}, and delete any you don't choose to use:

```console
UPSNAME=${UPSNAME}
UPSCABLE=${UPSCABLE}
UPSTYPE=${UPSTYPE}
DEVICE=${DEVICE}
POLLTIME=${POLLTIME} 
ONBATTERYDELAY=${ONBATTERYDELAY}
BATTERYLEVEL=${BATTERYLEVEL}
MINUTES=${MINUTES}
TIMEOUT=${TIMEOUT}
SELFTEST=${SELFTEST} 
APCUPSD_HOSTS=${APCUPSD_HOSTS}
APCUPSD_NAMES=${APCUPSD_NAMES}
TZ=${TZ}
```

#### Suggested docker-compose for STANDALONE use:

```yml
version: '3.7'
services:
  apcupsd:
    image: bnhf/apcupsd:latest
    container_name: apcupsd
    devices:
      - /dev/usb/hiddev0 # This device needs to match what the APC UPS on your STANDALONE system uses
    ports:
      - 3551:3551
    environment:
      - UPSNAME=${UPSNAME} # Sets a name for the UPS (1 to 8 chars), that will be used by System Tray notifications, apcupsd-cgi and Grafana dashboards
      - TZ=${TZ}
    healthcheck:
      test: ["CMD-SHELL", "apcaccess | grep -E 'ONLINE' >> /dev/null"] # Command to check health of UPS connection
      interval: 30s # Interval between health checks
      timeout: 5s # Timeout for each health check
      retries: 3 # How many times to retry
      start_period: 15s # Estimated time to boot
    volumes:
      - /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket # Required to support host shutdown from the container
      - /data/apcupsd:/etc/apcupsd # /etc/apcupsd can be bound to a directory or a docker volume
    restart: unless-stopped
```

#### Suggested docker-compose for MASTER use:

```yml
version: '3.7'
services:
  apcupsd:
    image: bnhf/apcupsd:latest
    container_name: apcupsd
    devices:
      - /dev/usb/hiddev0 # This device needs to match what the APC UPS on your APCUPSD_MASTER system uses
    ports:
      - 3551:3551
    environment:
      - UPSNAME=${UPSNAME} # Sets a name for the UPS (1 to 8 chars), that will be used by System Tray notifications, apcupsd-cgi and Grafana dashboards
      - POLLTIME=${POLLTIME} # Interval (in seconds) at which apcupsd polls the UPS for status (default=60)
      - ONBATTERYDELAY=${ONBATTERYDELAY} # Sets the time in seconds from when a power failure is detected until an onbattery event is initiated (default=6)
      - BATTERYLEVEL=${BATTERYLEVEL} # Sets the daemon to send the poweroff signal when the UPS reports a battery level of x% or less (default=5)
      - MINUTES=${MINUTES} # Sets the daemon to send the poweroff signal when the UPS has x minutes or less remaining power (default=5)
      - TIMEOUT=${TIMEOUT} # Sets the daemon to send the poweroff signal when the UPS has been ON battery power for x seconds (default=0)
      - APCUPSD_HOSTS=${APCUPSD_HOSTS} # If this is the MASTER, then enter the APUPSD_HOSTS list here, including this system (space separated)
      - APCUPSD_NAMES=${APCUPSD_NAMES} # Match the order of this list one-to-one to APCUPSD_HOSTS list, including this system (space separated)
      - TZ=${TZ}
    healthcheck:
      test: ["CMD-SHELL", "apcaccess | grep -E 'ONLINE' >> /dev/null"] # Command to check health
      interval: 30s # Interval between health checks
      timeout: 5s # Timeout for each health check
      retries: 3 # How many times to retry
      start_period: 15s # Estimated time to boot
    volumes:
      - /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket # Required to support host shutdown from the container
      - /data/apcupsd:/etc/apcupsd # /etc/apcupsd can be bound to a directory or a docker volume
    restart: unless-stopped
```

#### Suggested docker-compose for SLAVE use:

```yml
version: '3.7'
services:
  apcupsd:
    image: bnhf/apcupsd:latest
    container_name: apcupsd
    ports:
      - 3551:3551
    environment:
      - UPSNAME=${UPSNAME} # Sets a name for the UPS (1 to 8 chars), that will be used by System Tray notifications, apcupsd-cgi and Grafana dashboards
      - UPSCABLE=${UPSCABLE} # Usually doesn't need to be changed on system connected to UPS. (default=usb) On APCUPSD_SLAVES set the value to ether
      - UPSTYPE=${UPSTYPE} # Usually doesn't need to be changed on system connected to UPS. (default=usb) On APCUPSD_SLAVES set the value to net
      - DEVICE=${DEVICE} # Use this only on APCUPSD_SLAVES to set the hostname or IP address of the APCUPSD_MASTER with the listening port (:3551)
      - POLLTIME=${POLLTIME} # Interval (in seconds) at which apcupsd polls the UPS for status (default=60)
      - ONBATTERYDELAY=${ONBATTERYDELAY} # Sets the time in seconds from when a power failure is detected until an onbattery event is initiated (default=6)
      - BATTERYLEVEL=${BATTERYLEVEL} # Sets the daemon to send the poweroff signal when the UPS reports a battery level of x% or less (default=5)
      - MINUTES=${MINUTES} # Sets the daemon to send the poweroff signal when the UPS has x minutes or less remaining power (default=5)
      - TIMEOUT=${TIMEOUT} # Sets the daemon to send the poweroff signal when the UPS has been ON battery power for x seconds (default=0)
#      - SELFTEST=${SELFTEST} # Sets the daemon to ask the UPS to perform a self test every x hours (default=336)
      - TZ=${TZ}
    healthcheck:
      test: ["CMD-SHELL", "apcaccess | grep -E 'ONLINE' >> /dev/null"] # Command to check health
      interval: 30s # Interval between health checks
      timeout: 5s # Timeout for each health check
      retries: 3 # How many times to retry
      start_period: 15s # Estimated time to boot
    volumes:
      - /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket # Required to support host shutdown from the container
      - /data/apcupsd:/etc/apcupsd # /etc/apcupsd can be bound to a directory or a docker volume
    restart: unless-stopped
```
