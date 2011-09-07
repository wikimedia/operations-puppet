#!/usr/bin/env python
#
# htcpseqcheck.py
# measure HTCP multicast packet loss
# Written on 2011/08/05 by Mark Bergsma <mark@wikimedia.org>
#
# $Id$

import util
import socket, getopt, sys, pwd, grp, struct, threading

from util import debug
    
from datetime import datetime, timedelta
from collections import deque

try:
    from collections import Counter
except ImportError:
    from compat import Counter
    
# Globals

sourcebuf = {}
totalcounts, slidingcounts = Counter(), Counter()
slidingdeque = deque()
stats_lock = threading.Lock()

class RingBuffer(deque):
    """
    Implements TCP window like behavior
    """
    
    def __init__(self, iterable=[], maxlen=None, buffersize=timedelta(seconds=5)):
        self.counts = Counter()
        self.buffersize = buffersize
        
        try:
            deque.__init__(self, iterable, maxlen)
        except TypeError:
            deque.__init__(self, iterable)
    
    def add(self, seqnr):
        """
        Expects a sequence nr and adds it to the ringbuffer
        """
        
        ts = datetime.utcnow()
        counts = Counter()
        try:
            headseq, tailseq = self[0][0], self[-1][0]
        except IndexError:
            headseq, tailseq = seqnr-1, seqnr-1
        
        try:
            if seqnr == tailseq + 1:
                # Normal case, in-order arrival
                self.append((seqnr, ts, True))
                debug("Appended seqnr %d, timestamp %s" % (seqnr, ts))
            elif seqnr > tailseq + 1:
                # Packet(s) missing, fill the gap
                for seq in range(tailseq+1, seqnr):
                    self.append((seq, ts, False))
                self.append((seqnr, ts, True))
                debug("Filled gap of %d packets before new packet seqnr %d, timestamp %s" % (seqnr-tailseq-1, seqnr, ts))
            elif seqnr < headseq:
                counts['ancient'] += 1
            elif seqnr <= tailseq:
                # Late packet
                assert self[seqnr-headseq][0] == seqnr          # Incorrect seqnr?
                
                if self[seqnr-headseq][2]:
                    counts['dups'] += 1  # Already exists
                    debug("Duplicate packet %d" % seqnr)
                else:
                    # Store with original timestamp
                    self[seqnr-headseq] = (seqnr, self[seqnr-headseq][1], True)
                    counts['outoforder'] += 1
                    debug("Inserted late packet %d, timestamp %s" % (seqnr, ts))
        except:
            raise
        else:
            counts['received'] += 1
            # Purge old packets    
            self.deque(ts, counts)
            return counts
        
    def deque(self, now=datetime.utcnow(), counts=Counter()):
        while self and self[0][1] < now - self.buffersize:
            packet = self.popleft()
            counts['dequeued'] += 1
            debug("Dequeued packet id %d, timestamp %s, received %s" % packet)
            if not packet[2]:
                counts['lost'] += 1
        
        self.counts.update(counts)        

def receive_htcp(sock):
    portnr = sock.getsockname()[1];

    while 1:
        diagram, srcaddr = sock.recvfrom(2**14)
        if not diagram: break

        checkhtcpseq(diagram, srcaddr[0])

def update_sliding_counts(counts, maxlen=10000):
    "Implements a sliding window of counts"
    global slidingdeque, slidingcounts
    
    slidingcounts += counts
    slidingdeque.append(counts)
    
    if len(slidingdeque) > maxlen:
        slidingcounts -= slidingdeque.popleft()   

def checkhtcpseq(diagram, srcaddr):
    global sourcebuf, totalcounts, slidingcounts, stats_lock

    transid = struct.unpack('!I', diagram[8:12])[0]

    with stats_lock:    # Critical section
        sb = sourcebuf.setdefault(srcaddr, RingBuffer())
        try:
            counts = sb.add(transid)
        except IndexError:
            pass
        else:
            totalcounts.update(counts)
            update_sliding_counts(counts)
            
            # Don't bother printing stats if sys.stdout is set to None
            if not sys.stdout: return
            
            if counts['lost']:
                # Lost packets
                print "%d lost packet(s) from %s, last id %d" % (counts['lost'], srcaddr, transid)
            elif counts['ancient']:
                print "Ancient packet from %s, id %d" % (srcaddr, transid)
            
            if counts['lost'] and sb.counts['dequeued']:
                print "%d/%d losses (%.2f%%), %d out-of-order, %d dups, %d ancient, %d received from %s" % (
                    sb.counts['lost'],
                    sb.counts['dequeued'],
                    float(sb.counts['lost'])*100/sb.counts['dequeued'],
                    sb.counts['outoforder'],
                    sb.counts['dups'],
                    sb.counts['ancient'],
                    sb.counts['received'],
                    srcaddr)
                print "Totals: %d/%d losses (%.2f%%), %d out-of-order, %d dups, %d ancient, %d received from %d sources" % (
                    slidingcounts['lost'],
                    slidingcounts['dequeued'],
                    float(slidingcounts['lost'])*100/slidingcounts['dequeued'],
                    totalcounts['outoforder'],
                    totalcounts['dups'],
                    totalcounts['ancient'],
                    totalcounts['received'],
                    len(sourcebuf.keys()))

def print_help():
    print 'Usage:\n\thtcpseqcheck [ options ]\n'
    print 'Options:'
    print '\t-d\t\tFork into the background (become a daemon)'
    print '\t-p {portnr}\tUDP port number to listen on (default is 4827)'
    print '\t-j {mcast addr}\tMulticast group to join on startup'
    print '\t-u {username}\tChange uid'
    print '\t-g {group}\tChange group'
    print '\t-v\t\tBe more verbose'

if __name__ == '__main__':
    host = '0.0.0.0'
    portnr = 4827
    multicast_group = None
    daemon = False
    user = group = None
    opts = 'dhj:p:vu:g:'

    # Parse options
    options, arguments = getopt.getopt(sys.argv[1:], opts)
    for option, value in options:
        if option == '-j':
            multicast_group = value
        elif option == '-p':
            portnr = int(value)
        elif option == '-h':
            print_help()
            sys.exit()
        elif option == '-d':
            daemon = True
        elif option == '-u':
            user = value
        elif option == '-g':
            group = value
        elif option == '-v':
            util.debugging = True

    try:
        # Change uid and gid
        try:
            if group: os.setgid(grp.getgrnam(group).gr_gid)
            if user: os.setuid(pwd.getpwnam(user).pw_uid)
        except:
            print "Error: Could not change uid or gid."
            sys.exit(-1)

        # Become a daemon
        if daemon:
            util.createDaemon()

        sock = util.open_htcp_socket(host, portnr)
        
        # Join a multicast group if requested
        if multicast_group is not None:
            debug('Joining multicast group ' + multicast_group)
            util.join_multicast_group(sock, multicast_group)

        # Start receiving HTCP packets
        receive_htcp(sock)
    except socket.error, msg:
        print msg[1];
    except KeyboardInterrupt:
        pass


# Ganglia gmond module support
try:
    from htcpseqcheck_ganglia import metric_init, metric_cleanup
except ImportError:
    pass