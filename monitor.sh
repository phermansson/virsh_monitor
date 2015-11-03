#!/bin/bash

#-----------------------------------------------------------------------------#

APP_PATH="/home/nox/packages/virsh_monitor"

RUNNING="running"
STOPPED="shut"
ACTION_START="on_start"
ACTION_STOP="on_stop"

VM_STATE_DAT="vm_state.dat"
VM_STATE_DAT_OLD="vm_state_old.dat"
VM_PROFILES=$APP_PATH/profiles
TIMEOUT=1

#-----------------------------------------------------------------------------#

function log {
    echo "[$(date)]: $*"
}

function virsh_state_to_action() {
    local STATE=$1

    if [ "$STATE" = "$RUNNING" ]; then
        echo "$ACTION_START"
    elif [ "$STATE" = "$STOPPED" ]; then
        echo "$ACTION_STOP"
    fi
}
#-----------------------------------------------------------------------------#

function update_vm_state() {
    if [ -f $VM_STATE_DAT ]; then
        mv $VM_STATE_DAT $VM_STATE_DAT_OLD
    fi
    virsh list --all | sed 1,2d | head -n -1 | awk '{print " "$1 " "$2 " "$3 ""}' > $VM_STATE_DAT
}

#-----------------------------------------------------------------------------#

function run_scripts() {
    local INSTANCE=$1
    local ACTION=$2
    local DIR=$VM_PROFILES/$ACTION/$INSTANCE
    log $DIR
    for script in $DIR/*.sh; do
        log "running $DIR/$script"
        bash $script;
    done
}

#-----------------------------------------------------------------------------#

function handle_state_change() {
    local INSTANCE=$1
    local STATE=$2
    if [ "$STATE" = "$RUNNING" ]; then
        log "state change, $INSTANCE moved to started"
        run_script $STATE $INSTANCE
    elif [ "$STATE = $STOPPING" ]; then
        log "state change, $INSTANCE moved to stopped"
        run_scripts $STATE $INSTANCE
    fi;
}

#-----------------------------------------------------------------------------#

function check_state_change() {
    if [ -f $VM_STATE_DAT_OLD ]; then
        while read id name state; do
            while read old_id old_name old_state; do
                if [ "$name" = "$old_name" ]; then
                    if [ "$state" != "$old_state" ]; then
                        local $action=virsh_state_to_action $state
                        handle_state_change $name $action
                    fi;
                fi;
            done < $VM_STATE_DAT_OLD
        done < $VM_STATE_DAT;
    fi
}

#-----------------------------------------------------------------------------#

function init_fs() {
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

function worker() {
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

function cleanup() {
    rm $VM_STATE_DAT
    rm $VM_STATE_DAT_OLD
}

function main() {
    trap cleanup EXIT
    log "Starting virsh monitor worker, timeout: $TIMEOUT"
    worker
}

main
