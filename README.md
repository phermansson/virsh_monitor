# virsh_monitor

### Description 
virsh monitor is a small bash application that makes it possible to run arbitrary shell script
on certain vm events. Currently vm shutdown, vm startup, vm nic down, and vm nic up is supported.

### Installation
Modify config parameters in monitor.sh to suit your environment.

### Startup
./monitor.sh

The application will on startup create a filesystem in the directory profiles.
Within profiles four action, on_startup, on_shutdown, on_nic_down, on_nic_up is created and within these
a directory for each vm that the script has found. Within the vm specifc directories
arbitrary shell script can be placed. These scripts will be run when the given event occurs
