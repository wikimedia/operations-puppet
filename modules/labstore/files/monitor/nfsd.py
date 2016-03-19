# coding=utf-8

"""
collect nfsd utilization

#### Dependencies

 * /proc/net/rpc/nfsd
 * /proc/fs/nfsd/pool_stats

https://www.kernel.org/doc/Documentation/filesystems/nfs/knfsd-stats.txt
"""

import diamond.collector
import subprocess


def runBash(cmd):
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    out = p.stdout.read().strip()
    return out


class NfsdCollector(diamond.collector.Collector):

    PROC1 = '/proc/fs/nfsd/pool_stats'
    PROC2 = '/proc/net/rpc/nfsd'

    def get_default_config_help(self):
        config_help = super(NfsdCollector, self).get_default_config_help()
        config_help.update({
        })
        return config_help

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(NfsdCollector, self).get_default_config()
        config.update({
            'enabled':  False,
            'path':     'nfsd'
        })
        return config

    def collect(self):
        """
        Collect stats
        """

        results = {}

        ss = '/bin/ss -t -n -o state established'
        ss_filter = "'( dport = :2049 or sport = :2049 )'"
        try:
            ss_clients = runBash("%s %s" % (ss, ss_filter))

            # extract the unique list of client IP's
            client_tcb = ss_clients.splitlines()[1::]
            client_socket = [c.split()[3] for c in client_tcb]
            client_ip = [c.split(':')[0] for c in client_socket]
            self.publish('clients', len(set(client_ip)))
        except:
            self.log.error("Failed to publish client count")

        try:
            with open(self.PROC1, 'r') as f:
                proc1_stats = f.readlines()

            with open(self.PROC2, 'r') as f:
                proc2_stats = f.readlines()
        except:
            self.log.error("Failed to open PROC")
            return False

        # Example
        # \# pool packets-arrived \
        # sockets-enqueued threads-woken threads-timedout
        # 0 174986041 56322 174930501 93
        values = proc1_stats[1].split()
        results['pool_stats.pool'] = values[0]
        results['pool_stats.packets_arrived'] = values[1]
        results['pool_stats.sockets_enqueued'] = values[2]
        results['pool_stats.threads-woken'] = values[3]
        results['pool_stats.threads-timedout'] = values[4]

        for line in proc2_stats:
            line = line.split()

            if line[0] == 'rc':
                results['reply_cache.hits'] = line[1]
                results['reply_cache.misses'] = line[2]
                results['reply_cache.nocache'] = line[3]
            elif line[0] == 'fh':
                results['filehandle.stale'] = line[1]
                results['filehandle.total-lookups'] = line[2]
                results['filehandle.anonlookups'] = line[3]
                results['filehandle.dir-not-in-cache'] = line[4]
                results['filehandle.nodir-not-in-cache'] = line[5]
            elif line[0] == 'io':
                results['input_output.bytes-read'] = line[1]
                results['input_output.bytes-written'] = line[2]
            elif line[0] == 'th':
                results['threads.threads'] = line[1]
                results['threads.fullcnt'] = line[2]
                results['threads.10-20-pct'] = line[3]
                results['threads.20-30-pct'] = line[4]
                results['threads.30-40-pct'] = line[5]
                results['threads.40-50-pct'] = line[6]
                results['threads.50-60-pct'] = line[7]
                results['threads.60-70-pct'] = line[8]
                results['threads.70-80-pct'] = line[9]
                results['threads.80-90-pct'] = line[10]
                results['threads.90-100-pct'] = line[11]
                results['threads.100-pct'] = line[12]
            elif line[0] == 'ra':
                results['read-ahead.cache-size'] = line[1]
                results['read-ahead.10-pct'] = line[2]
                results['read-ahead.20-pct'] = line[3]
                results['read-ahead.30-pct'] = line[4]
                results['read-ahead.40-pct'] = line[5]
                results['read-ahead.50-pct'] = line[6]
                results['read-ahead.60-pct'] = line[7]
                results['read-ahead.70-pct'] = line[8]
                results['read-ahead.80-pct'] = line[9]
                results['read-ahead.90-pct'] = line[10]
                results['read-ahead.100-pct'] = line[11]
                results['read-ahead.not-found'] = line[12]
            elif line[0] == 'net':
                results['net.cnt'] = line[1]
                results['net.udpcnt'] = line[2]
                results['net.tcpcnt'] = line[3]
                results['net.tcpconn'] = line[4]
            elif line[0] == 'rpc':
                results['rpc.cnt'] = line[1]
                results['rpc.badfmt'] = line[2]
                results['rpc.badauth'] = line[3]
                results['rpc.badclnt'] = line[4]
            elif line[0] == 'proc4':
                results['v4.unknown'] = line[1]
                results['v4.null'] = line[2]
                results['v4.compound'] = line[3]
            elif line[0] == 'proc4ops':
                results['v4.ops.unknown'] = line[1]
                results['v4.ops.op0-unused'] = line[2]
                results['v4.ops.op1-unused'] = line[3]
                results['v4.ops.op2-future'] = line[4]
                results['v4.ops.access'] = line[5]
                results['v4.ops.close'] = line[6]
                results['v4.ops.commit'] = line[7]
                results['v4.ops.create'] = line[8]
                results['v4.ops.delegpurge'] = line[9]
                results['v4.ops.delegreturn'] = line[10]
                results['v4.ops.getattr'] = line[11]
                results['v4.ops.getfh'] = line[12]
                results['v4.ops.link'] = line[13]
                results['v4.ops.lock'] = line[14]
                results['v4.ops.lockt'] = line[15]
                results['v4.ops.locku'] = line[16]
                results['v4.ops.lookup'] = line[17]
                results['v4.ops.lookup_root'] = line[18]
                results['v4.ops.nverify'] = line[19]
                results['v4.ops.open'] = line[20]
                results['v4.ops.openattr'] = line[21]
                results['v4.ops.open_conf'] = line[22]
                results['v4.ops.open_dgrd'] = line[23]
                results['v4.ops.putfh'] = line[24]
                results['v4.ops.putpubfh'] = line[25]
                results['v4.ops.putrootfh'] = line[26]
                results['v4.ops.read'] = line[27]
                results['v4.ops.readdir'] = line[28]
                results['v4.ops.readlink'] = line[29]
                results['v4.ops.remove'] = line[30]
                results['v4.ops.rename'] = line[31]
                results['v4.ops.renew'] = line[32]
                results['v4.ops.restorefh'] = line[33]
                results['v4.ops.savefh'] = line[34]
                results['v4.ops.secinfo'] = line[35]
                results['v4.ops.setattr'] = line[36]
                results['v4.ops.setcltid'] = line[37]
                results['v4.ops.setcltidconf'] = line[38]
                results['v4.ops.verify'] = line[39]
                results['v4.ops.write'] = line[40]
                results['v4.ops.rellockowner'] = line[41]

            for metric, value in results.iteritems():
                dvalue = self.derivative(metric, float(value))
                self.publish(metric, dvalue)

            return True

        return False
