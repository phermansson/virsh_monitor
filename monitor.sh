#!/bin/bash

#-----------------------------------------------------------------------------#

# - APP_PATH: application path. The profile tree will be stored here.
readonly APP_PATH="/home/nox/packages/virsh_monitor"
readonly VM_PROFILES=$APP_PATH/profiles
# - log path for virsh monitor
readonly APP_LOG="$APP_PATH/virsh_monitor.log"
# - TIMEOUT: The interval between VM changes scan.
readonly TIMEOUT=1

#-----------------------------------------------------------------------------#

readonly RUNNING="running"
readonly STOPPED="shut"
readonly ACTION_START="on_start"
readonly ACTION_STOP="on_stop"
readonly VM_STATE_DAT="vm_state.dat"
readonly VM_STATE_DAT_OLD="vm_state_old.dat"

#-----------------------------------------------------------------------------#

log() {
    echo "[$(date)]: $*" > $APP_LOG
}

function virsh_state_to_action() {
    local STATE=$1
    local ACTION=""

    if [ "$STATE" = "$RUNNING" ]; then
        ACTION=$ACTION_START
    elif [ "$STATE" = "$STOPPED" ]; then
        ACTION=$ACTION_STOP
    fi
    echo $ACTION
}

#-----------------------------------------------------------------------------#

update_vm_state() {
    if [ -f $VM_STATE_DAT ]; then
        mv $VM_STATE_DAT $VM_STATE_DAT_OLD
    fi
    virsh list --all | \
        sed 1,2d | \
        head -n -1 | \
        awk '{print " "$1 " "$2 " "$3 ""}' > $VM_STATE_DAT
}

#-----------------------------------------------------------------------------#

run_scripts() {
    local INSTANCE=$1
    local ACTION=$2
    local DIR=$VM_PROFILES/$ACTION/$INSTANCE

    for script in $DIR/*.sh; do
        log "running $DIR/$script"
        bash $script;
    done
}

#-----------------------------------------------------------------------------#

handle_state_change() {
    local INSTANCE=$1
    local STATE=$2

    if [ "$STATE" = "$ACTION_START" ]; then
        log "state change, $INSTANCE moved to started"
        run_scripts $INSTANCE $STATE
    elif [ "$STATE" = "$ACTION_STOP" ]; then
        log "state change, $INSTANCE moved to stopped"
        run_scripts $INSTANCE $STATE
    fi;
}

#-----------------------------------------------------------------------------#

check_state_change() {
    if [ -f $VM_STATE_DAT_OLD ]; then
        while read id name state; do
            while read old_id old_name old_state; do
                if [ "$name" = "$old_name" ]; then
                    if [ "$state" != "$old_state" ]; then
                        local action=$(virsh_state_to_action $state)
                        handle_state_change $name $action
                    fi;
                fi;
            done < $VM_STATE_DAT_OLD
        done < $VM_STATE_DAT;
    fi
}

#-----------------------------------------------------------------------------#

init_fs() {
    log "Creating file system"
    mkdir -p $VM_PROFILES
    log "Creating $VM_PROFILES/$ACTION_START"
    mkdir -p $VM_PROFILES/$ACTION_START
    log "Creating $VM_PROFILES/$ACTION_STOP"
    mkdir -p $VM_PROFILES/$ACTION_STOP
    while read id name state; do
        log "Creating $VM_PROFILES/$ACTION_STOP/$name"
        mkdir -p $VM_PROFILES/$ACTION_STOP/$name
        log "Creating $VM_PROFILES/$ACTION_START/$name"
        mkdir -p $VM_PROFILES/$ACTION_START/$name
    done < $VM_STATE_DAT
}

#-----------------------------------------------------------------------------#

worker() {
    update_vm_state
    init_fs
    log "starting worker..."
    while true; do
        update_vm_state
        check_state_change
        sleep $TIMEOUT
    done;
}

#-----------------------------------------------------------------------------#

cleanup() {
    rm $VM_STATE_DAT
    rm $VM_STATE_DAT_OLD
}

function main() {
    trap cleanup EXIT
    log "Starting virsh monitor worker, timeout: $TIMEOUT"
    worker
}

main
