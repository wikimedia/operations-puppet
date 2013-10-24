# -*- coding: utf-8 -*-
"""
Listen for wfDebug()s on UDP; forward to Ganglia using Gmetric.
Usage: wfdebug-ganglia.py UDP_LISTEN_PORT

"""
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

import threading
import socket
import subprocess
import time


REPORTING_INTERVAL = 5  # In seconds.
UDP_BUFSIZE = 65536  # Udp2LogConfig::BLOCK_SIZE
METRIC_FORMAT = 'mediaWiki.wfDebug.%s'  # Format string for metric name

try:
    port = int(sys.argv[1])
except (IndexError, ValueError):
    print __doc__.strip()
    sys.exit(1)

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(('0.0.0.0', port))

counts = {}
lock = threading.Lock()
defaults = {
    'group': 'wfDebug',
    'slope': 'positive',
    'spoof': 'mediaWiki:mediaWiki',
    'tmax': REPORTING_INTERVAL,
    'type': 'uint32',
    'units': 'messages',
}


def listen(port):
    while 1:
        dgram = sock.recv(UDP_BUFSIZE)
        seq_id, log_name, rest = dgram.split(' ', 2)
        with lock:
            counts[log_name] = counts.get(log_name, 0) + 1


def send_with_gmetric(metric):
    command = ['gmetric']
    args = sorted('--%s=%s' % (k, v) for k, v in metric.items())
    command.extend(args)
    subprocess.call(command)


def dispatch_stats():
    """Send metrics to Ganglia by shelling out to gmetric."""
    with lock:
        stats = counts.copy()
    for log_name, count in stats.items():
        metric = dict(defaults, name=METRIC_FORMAT % log_name, value=count)
        send_with_gmetric(metric)


# Start listener
listener = threading.Thread(target=listen, args=(port,))
listener.daemon = True
listener.start()

# Report stats
while 1:
    start = time.time()
    dispatch_stats()
    elapsed = time.time() - start
    time.sleep(REPORTING_INTERVAL - elapsed)
