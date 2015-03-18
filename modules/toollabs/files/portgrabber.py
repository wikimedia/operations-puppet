import socket

# We need to pass the sockets to the proxies on to the child process,
# so we must have a place to store them.
socks = []

def getProxies():
    """Return the list of proxies to register with."""
    return ['tools-webproxy-01', 'tools-webproxy-02']

def register(port):
    """Register with the proxies."""
    for proxy in getProxies():
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.connect((proxy, 8282))
        sock.sendall(".*\nhttp://%s:%s\n" % (socket.getfqdn(), port))
        socks.append(sock)
