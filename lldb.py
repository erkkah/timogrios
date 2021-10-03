import time
import os
import sys
import lldb

def connect_command(debugger, command, result, internal_dict):
    connect_url = internal_dict['connect_url']
    error = lldb.SBError()
    
    listener = lldb.SBListener('iosdeploy_listener')
    listener.StartListeningForEventClass(debugger,
                                            lldb.SBTarget.GetBroadcasterClassName(),
                                            lldb.SBProcess.eBroadcastBitStateChanged)
    
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
    device_app = internal_dict['device_app']
    debugger.GetSelectedTarget().modules[0].SetPlatformFileSpec(lldb.SBFileSpec(device_app))
    launchInfo = lldb.SBLaunchInfo([])
    launchInfo.SetEnvironmentEntries(['OS_ACTIVITY_DT_MODE=enable'], True)
    startup_error = lldb.SBError()
    debugger.GetSelectedTarget().Launch(launchInfo, startup_error)
