import socket

import yaml

# We need to pass the sockets to the proxies on to the child process,
# so we must have a place to store them.
socks = []


def get_proxies():
    """Return the list of proxies to register with."""
    with open('/etc/portgrabber.yaml', 'r') as f:
        config = yaml.safe_load(f)
        return config['proxies']


def get_open_port():
    """Tries to get a random open port to listen on

    It does this by starting to listen on a socket, letting the kernel determine
    the open port. It then immediately closes it and returns the port.
    """
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind(('', 0))
    port = s.getsockname()[1]
    s.close()
    return port


def register(port):
    """Register with the proxies."""
    for proxy in get_proxies():
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((proxy, 8282))
        sock.sendall(".*\nhttp://%s:%u\n" % (socket.getfqdn(), port))
        socks.append(sock)
