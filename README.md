# virsh_monitor

### Description 
virsh monitor is a small bash application that makes it possible to run arbitrary shell script
on certain vm events. Currently vm shutdown and vm startup is supported.

### Installation
Modify config parameters in monitor.sh to suit your environment.

### Startup
./monitor.sh

The application will on startup create a filesystem in the directory profiles.
Within profiles two action, on_startup, on_shutdown is created and within these
a directory for each vm that the script has found. Within the vm specifc directories
arbitrary shell script can be placed.
