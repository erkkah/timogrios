import time
import os
import sys
import shlex
import lldb

listener = None
startup_error = lldb.SBError()

def connect_command(debugger, command, result, internal_dict):
    # These two are passed in by the script which loads us
    connect_url = internal_dict['fruitstrap_connect_url']
    error = lldb.SBError()
    
    # We create a new listener here and will use it for both target and the process.
    # It allows us to prevent data races when both our code and internal lldb code
    # try to process STDOUT/STDERR messages
    global listener
    listener = lldb.SBListener('iosdeploy_listener')
    
    listener.StartListeningForEventClass(debugger,
                                            lldb.SBTarget.GetBroadcasterClassName(),
                                            lldb.SBProcess.eBroadcastBitStateChanged | lldb.SBProcess.eBroadcastBitSTDOUT | lldb.SBProcess.eBroadcastBitSTDERR)
    
    process = debugger.GetSelectedTarget().ConnectRemote(listener, connect_url, None, error)

    # Wait for connection to succeed
    events = []
    state = (process.GetState() or lldb.eStateInvalid)
    while state != lldb.eStateConnected:
        event = lldb.SBEvent()
        if listener.WaitForEvent(1, event):
            state = process.GetStateFromEvent(event)
            events.append(event)
        else:
            state = lldb.eStateInvalid

    # Add events back to queue, otherwise lldb freezes
    for event in events:
        listener.AddEvent(event)

def run_command(debugger, command, result, internal_dict):
    device_app = internal_dict['fruitstrap_device_app']
    args = command.split('--',1)
    debugger.GetSelectedTarget().modules[0].SetPlatformFileSpec(lldb.SBFileSpec(device_app))
    args_arr = []
    if len(args) > 1:
        args_arr = shlex.split(args[1])
    args_arr = args_arr + shlex.split('')

    launchInfo = lldb.SBLaunchInfo(args_arr)
    global listener
    launchInfo.SetListener(listener)
    
    #This env variable makes NSLog, CFLog and os_log messages get mirrored to stderr
    #https://stackoverflow.com/a/39581193 
    launchInfo.SetEnvironmentEntries(['OS_ACTIVITY_DT_MODE=enable'], True)

    envs_arr = []
    if len(args) > 1:
        envs_arr = shlex.split(args[1])
    envs_arr = envs_arr + shlex.split('')
    launchInfo.SetEnvironmentEntries(envs_arr, True)
    
    debugger.GetSelectedTarget().Launch(launchInfo, startup_error)
    lockedstr = ': Locked'
    if lockedstr in str(startup_error):
       print('\nDevice Locked\n')
       os._exit(254)
    else:
       print(str(startup_error))

