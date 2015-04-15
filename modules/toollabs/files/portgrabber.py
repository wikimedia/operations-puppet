import socket

import yaml


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
        try:
            sock.connect((proxy, 8282))
            sock.sendall("register\n.*\nhttp://%s:%u\n" % (socket.getfqdn(), port))
            res = sock.recv(1024)
            if res != 'ok':
                sys.stderr.write('port registration failed!')
                sys.exit(-1)
        finally:
            sock.close()


def unregister():
    """Unregister with the proxies."""
    for proxy in get_proxies():
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.connect((proxy, 8282))
            sock.sendall("unregister\n.*\n")
            res = sock.recv(1024)
            if res != 'ok':
                sys.stderr.write('port unregistration failed!')
                sys.exit(-1)
        finally:
            sock.close()
