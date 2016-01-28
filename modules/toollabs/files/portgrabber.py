import json
import os
import pwd
import requests
import socket
import sys


def get_active_proxy():
    """Return the active master proxy to register with"""
    with open('/etc/active-proxy', 'r') as f:
        return f.read().strip()


def get_open_port():
    """Tries to get a random open port to listen on

    It does this by starting to listen on a socket, letting the kernel
    determine the open port. It then immediately closes it and returns the
    port."""
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(('', 0))
    port = s.getsockname()[1]
    s.close()
    return port


def get_tool_name():
    """Return the tool part of the current user name."""
    with open('/etc/wmflabs-project', 'r') as f:
        tools_prefix = f.read().rstrip('\n') + '.'
    user_name = pwd.getpwuid(os.getuid()).pw_name
    if user_name[0:len(tools_prefix)] != tools_prefix:
        raise ValueError(user_name, ' does not start with ', tools_prefix)
    return user_name[len(tools_prefix):]


def get_proxy_forward_entry_manage_url():
    """Return the URL to manage proxy forward entry."""
    return 'http://%s:8081/v1/proxy-forwards/%s' % (get_active_proxy(), get_tool_name())


def register(port):
    """Register with the master proxy."""
    r = requests.put(get_proxy_forward_entry_manage_url(),
                     data=json.dumps({'.*': 'http://%s:%u' % (socket.getfqdn(), port)}))
    r.raise_for_status()


def unregister():
    """Unregister with the master proxy."""
    r = requests.delete(get_proxy_forward_entry_manage_url())
    r.raise_for_status()
