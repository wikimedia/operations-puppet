import ConfigParser
import socket

# We need to pass the sockets to the proxies on to the child process,
# so we must have a place to store them.
socks = []


def getProxies():
    """Return the list of proxies to register with."""
    config = ConfigParser.RawConfigParser()
    config.read('/etc/portgrabber.conf')

    return config.get('portgrabber', 'proxies').split()


def register(port):
    """Register with the proxies."""
    for proxy in getProxies():
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((proxy, 8282))
        sock.sendall(".*\nhttp://%s:%u\n" % (socket.getfqdn(), port))
        socks.append(sock)
