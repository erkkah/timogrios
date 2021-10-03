import lldb

def launch(debugger, command, result, internal_dict):
    connect_url = internal_dict['connect_url']
    app_path = internal_dict['app_path']

    error = lldb.SBError()

    target = debugger.GetSelectedTarget()

    listener = lldb.SBListener('timogrios')
    listener.StartListeningForEventClass(debugger,
                                         lldb.SBTarget.GetBroadcasterClassName(),
                                         lldb.SBProcess.eBroadcastBitStateChanged)

    process = target.ConnectRemote(listener, connect_url, None, error)

    state = (process.GetState() or lldb.eStateInvalid)
    while state != lldb.eStateConnected:
        event = lldb.SBEvent()
        if listener.WaitForEvent(1, event):
            state = process.GetStateFromEvent(event)
        else:
            state = lldb.eStateInvalid

    target.modules[0].SetPlatformFileSpec(lldb.SBFileSpec(app_path))
    launch_info = lldb.SBLaunchInfo([])
    target.Launch(launch_info, error)
