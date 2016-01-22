# coding=utf-8

"""
Emulate iostat for NFS mount points using /proc/self/mountstats

Port of the sysstat utility nfsiostat to a
diamond context.  I have tried to keep things the same
where possible to avoid reinventing the wheel on future updates.

Modified 2016, Chase Pettet
Copyright (C) 2005, Chuck Lever <cel@netapp.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
MA 02110-1301 USA
"""

from __future__ import print_function
import sys
import os
import time
from optparse import OptionParser, OptionGroup
import diamond.collector

Iostats_version = '0.2'

NfsEventCounters = [
    'inoderevalidates',
    'dentryrevalidates',
    'datainvalidates',
    'attrinvalidates',
    'vfsopen',
    'vfslookup',
    'vfspermission',
    'vfsupdatepage',
    'vfsreadpage',
    'vfsreadpages',
    'vfswritepage',
    'vfswritepages',
    'vfsreaddir',
    'vfssetattr',
    'vfsflush',
    'vfsfsync',
    'vfslock',
    'vfsrelease',
    'congestionwait',
    'setattrtrunc',
    'extendwrite',
    'sillyrenames',
    'shortreads',
    'shortwrites',
    'delay'
]

NfsByteCounters = [
    'normalreadbytes',
    'normalwritebytes',
    'directreadbytes',
    'directwritebytes',
    'serverreadbytes',
    'serverwritebytes',
    'readpages',
    'writepages'
]


class DeviceData:
    """DeviceData objects provide methods for parsing and displaying
    data for a single mount grabbed from /proc/self/mountstats
    """
    def __init__(self):
        self.__nfs_data = dict()
        self.__rpc_data = dict()
        self.__rpc_data['ops'] = []

    def __parse_nfs_line(self, words):
        if words[0] == 'device':
            self.__nfs_data['export'] = words[1]
            self.__nfs_data['mountpoint'] = words[4]
            self.__nfs_data['fstype'] = words[7]
            if words[7] == 'nfs':
                self.__nfs_data['statvers'] = words[8]
        elif 'nfs' in words or 'nfs4' in words:
            self.__nfs_data['export'] = words[0]
            self.__nfs_data['mountpoint'] = words[3]
            self.__nfs_data['fstype'] = words[6]
            if words[6] == 'nfs':
                self.__nfs_data['statvers'] = words[7]
        elif words[0] == 'age:':
            self.__nfs_data['age'] = long(words[1])
        elif words[0] == 'opts:':
            self.__nfs_data['mountoptions'] = ''.join(words[1:]).split(',')
        elif words[0] == 'caps:':
            self.__nfs_data['servercap'] = ''.join(words[1:]).split(',')
        elif words[0] == 'nfsv4:':
            self.__nfs_data['nfsv4flags'] = ''.join(words[1:]).split(',')
        elif words[0] == 'sec:':
            keys = ''.join(words[1:]).split(',')
            self.__nfs_data['flavor'] = int(keys[0].split('=')[1])
            self.__nfs_data['pseudoflavor'] = 0
            if self.__nfs_data['flavor'] == 6:
                self.__nfs_data['pseudoflavor'] = int(keys[1].split('=')[1])
        elif words[0] == 'events:':
            i = 1
            for key in NfsEventCounters:
                self.__nfs_data[key] = int(words[i])
                i += 1
        elif words[0] == 'bytes:':
            i = 1
            for key in NfsByteCounters:
                self.__nfs_data[key] = long(words[i])
                i += 1

    def __parse_rpc_line(self, words):
        if words[0] == 'RPC':
            self.__rpc_data['statsvers'] = float(words[3])
            self.__rpc_data['programversion'] = words[5]
        elif words[0] == 'xprt:':
            self.__rpc_data['protocol'] = words[1]
            if words[1] == 'udp':
                self.__rpc_data['port'] = int(words[2])
                self.__rpc_data['bind_count'] = int(words[3])
                self.__rpc_data['rpcsends'] = int(words[4])
                self.__rpc_data['rpcreceives'] = int(words[5])
                self.__rpc_data['badxids'] = int(words[6])
                self.__rpc_data['inflightsends'] = long(words[7])
                self.__rpc_data['backlogutil'] = long(words[8])
            elif words[1] == 'tcp':
                self.__rpc_data['port'] = words[2]
                self.__rpc_data['bind_count'] = int(words[3])
                self.__rpc_data['connect_count'] = int(words[4])
                self.__rpc_data['connect_time'] = int(words[5])
                self.__rpc_data['idle_time'] = int(words[6])
                self.__rpc_data['rpcsends'] = int(words[7])
                self.__rpc_data['rpcreceives'] = int(words[8])
                self.__rpc_data['badxids'] = int(words[9])
                self.__rpc_data['inflightsends'] = long(words[10])
                self.__rpc_data['backlogutil'] = long(words[11])
            elif words[1] == 'rdma':
                self.__rpc_data['port'] = words[2]
                self.__rpc_data['bind_count'] = int(words[3])
                self.__rpc_data['connect_count'] = int(words[4])
                self.__rpc_data['connect_time'] = int(words[5])
                self.__rpc_data['idle_time'] = int(words[6])
                self.__rpc_data['rpcsends'] = int(words[7])
                self.__rpc_data['rpcreceives'] = int(words[8])
                self.__rpc_data['badxids'] = int(words[9])
                self.__rpc_data['backlogutil'] = int(words[10])
                self.__rpc_data['read_chunks'] = int(words[11])
                self.__rpc_data['write_chunks'] = int(words[12])
                self.__rpc_data['reply_chunks'] = int(words[13])
                self.__rpc_data['total_rdma_req'] = int(words[14])
                self.__rpc_data['total_rdma_rep'] = int(words[15])
                self.__rpc_data['pullup'] = int(words[16])
                self.__rpc_data['fixup'] = int(words[17])
                self.__rpc_data['hardway'] = int(words[18])
                self.__rpc_data['failed_marshal'] = int(words[19])
                self.__rpc_data['bad_reply'] = int(words[20])
        elif words[0] == 'per-op':
            self.__rpc_data['per-op'] = words
        else:
            op = words[0][:-1]
            self.__rpc_data['ops'] += [op]
            self.__rpc_data[op] = [long(word) for word in words[1:]]

    def parse_stats(self, lines):
        """Turn a list of lines from a mount stat file into a
        dictionary full of stats, keyed by name
        """
        found = False
        for line in lines:
            words = line.split()
            if len(words) == 0:
                continue
            if (not found and words[0] != 'RPC'):
                self.__parse_nfs_line(words)
                continue

            found = True
            self.__parse_rpc_line(words)

    def is_nfs_mountpoint(self):
        """Return True if this is an NFS or NFSv4 mountpoint,
        otherwise return False
        """
        if self.__nfs_data['fstype'] == 'nfs':
            return True
        elif self.__nfs_data['fstype'] == 'nfs4':
            return True
        return False

    def __data_cache_stats(self):
        """the data cache hit rate
        """
        data = {}
        nfs_stats = self.__nfs_data
        data['normalreadbytes'] = float(nfs_stats['normalreadbytes'])
        data['serverreadbytes'] = float(nfs_stats['serverreadbytes'])
        data['directreadbytes'] = nfs_stats['directreadbytes']
        return data

    def __attr_cache_stats(self):
        """attribute cache efficiency stats
        """
        nfs_stats = self.__nfs_data
        getattr_stats = self.__rpc_data['GETATTR']

        if nfs_stats['inoderevalidates'] != 0:
            getattr_ops = float(getattr_stats[1])
            opens = float(nfs_stats['vfsopen'])
            revalidates = float(nfs_stats['inoderevalidates']) - opens
            if revalidates != 0:
                ratio = ((revalidates - getattr_ops) * 100) / revalidates
            else:
                ratio = 0.0

            data_invalidates = float(nfs_stats['datainvalidates'])
            attr_invalidates = float(nfs_stats['attrinvalidates'])

            data = {}

            # data['inode_revalidations'] = revalidates
            # data['inode_revalidations_cache_hit_pcnt'] = ratio

            data['open_operations'] = opens
            return data

    def dir_cache_stats(self):
        """directory stats
        """
        nfs_stats = self.__nfs_data
        lookup_ops = self.__rpc_data['LOOKUP'][0]
        readdir_ops = self.__rpc_data['READDIR'][0]
        if 'READDIRPLUS' in self.__rpc_data:
            readdir_ops += self.__rpc_data['READDIRPLUS'][0]

        data = {}
        data['dentry_revals'] = nfs_stats['dentryrevalidates']
        data['opens'] = nfs_stats['vfsopen']
        data['lookups'] = nfs_stats['vfslookup']
        data['getdents'] = nfs_stats['vfsreaddir']
        data['readdir'] = readdir_ops
        return data

    def page_stats(self):
        """page cache stats
        """
        nfs_stats = self.__nfs_data

        data = {}

        # Excluded until needed
        # data['vfsreadpage'] = nfs_stats['vfsreadpage']
        # data['vfsreadpages'] = nfs_stats['vfsreadpages']
        # data['vfswritepage'] = nfs_stats['vfswritepage']
        # data['vfswritepages'] = nfs_stats['vfswritepages']
        # data['nfs_updatepage'] = nfs_stats['vfsupdatepage']

        data['pages_read'] = nfs_stats['readpages']
        data['pages_written'] = nfs_stats['writepages']
        data['congestion_waits'] = nfs_stats['congestionwait']
        return data

    def rpc_op_stats(self, op):
        """generic stats for one RPC op
        """

        if op not in self.__rpc_data:
            return {}

        rpc_stats = self.__rpc_data[op]
        ops = float(rpc_stats[0])
        retrans = float(rpc_stats[1] - rpc_stats[0])
        kilobytes = float(rpc_stats[3] + rpc_stats[4]) / 1024
        rtt = float(rpc_stats[6])
        exe = float(rpc_stats[7])

        if ops == 0:
            kb_per_op = 0.0
            retrans_percent = 0.0
            rtt_per_op = 0.0
            exe_per_op = 0.0

        data = {}

        # data['kilobytes_per_op'] = kb_per_op
        # data['retrans_percent'] = retrans_percent

        data['ops'] = ops
        data['kilobytes'] = kilobytes
        data['retrans'] = retrans
        data['rtt_ms'] = rtt
        data['exe_ms'] = exe
        return data

    def get_iostats(self):
        """NFS and RPC stats
        """

        sends = float(self.__rpc_data['rpcsends'])

        data = {}

        data['export'] = self.__nfs_data['export']
        data['mountpoint'] = self.__nfs_data['mountpoint']

        data['ops'] = sends
        # to calculate further if sends != 0
        # backlog = (float(self.__rpc_data['backlogutil']) / sends)
        data['backlog'] = self.__rpc_data['backlogutil']

        data['read'] = self.rpc_op_stats('READ')
        data['write'] = self.rpc_op_stats('WRITE')

        data['getattr'] = self.rpc_op_stats('GETATTR')
        data['lookup'] = self.rpc_op_stats('LOOKUP')
        data['access'] = self.rpc_op_stats('access')
        data['readdir'] = self.rpc_op_stats('readdir')

        data['attr'] = self.__attr_cache_stats()
        data['dir_cache'] = self.dir_cache_stats()
        data['page_stats'] = self.page_stats()
        data['data_cache'] = self.__data_cache_stats()
        return data


def parse_stats_file(filename):
    """pop the contents of a mountstats file into a dictionary,
    keyed by mount point.  each value object is a list of the
    lines in the mountstats file corresponding to the mount
    point named in the key.
    """
    ms_dict = dict()
    key = ''

    f = open(filename)
    for line in f.readlines():
        words = line.split()
        if len(words) == 0:
            continue
        if words[0] == 'device':
            key = words[4]
            new = [line.strip()]
        elif 'nfs' in words or 'nfs4' in words:
            key = words[3]
            new = [line.strip()]
        else:
            new += [line.strip()]
        ms_dict[key] = new
    f.close

    return ms_dict


def nfs_iostat(new, devices):
    stats = {}
    diff_stats = {}
    devicelist = devices

    for device in devicelist:
        stats[device] = DeviceData()
        stats[device].parse_stats(new[device])

    iostat = {}
    for device in devicelist:
        iostat[device] = stats[device].get_iostats()
    return iostat


def list_nfs_mounts(mountstats):
    """return a list of NFS mounts
    """
    list = []
    for device, descr in mountstats.items():
        stats = DeviceData()
        stats.parse_stats(descr)
        if stats.is_nfs_mountpoint():
            list += [device]
    return list


class NfsiostatCollector(diamond.collector.Collector):

    def get_default_config_help(self):
        config_help = super(NfsiostatCollector, self).get_default_config_help()
        config_help.update({
        })
        return config_help

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(NfsiostatCollector, self).get_default_config()
        config.update({
            'enabled':  False,
            'path':     'nfsiostat',
            'devices': ['/home',
                        '/public/dumps',
                        '/data/scratch',
                        '/data/project'],
            'attributes': ['attr',
                           'read',
                           'write',
                           'getattr',
                           'lookup',
                           'dir_cache',
                           'page_stats']
        })
        return config

    def delta(self, name, new, instance=None):
        """ figure the delta between last and current
        :param name: string
        :param new: string
        :instance: string or Falsy value
        :returns: int
        """

        path = self.get_metric_path(name, instance=instance)
        if path in self.last_values:
            old = self.last_values[path]
            delta = new - old
            if delta < 0:
                self.log.error("nfsio is reporting negative values")
                out = 0
            else:
                out = delta

        else:
            # standard diamond behavior is not to log a value
            # when a derivative or delta is expected if this is
            # first pass
            out = 0

        self.last_values[path] = new
        return out

    def collect(self):
        mountstats = parse_stats_file('/proc/self/mountstats')

        # make certain devices contains only NFS mount points
        devices = list_nfs_mounts(mountstats) or []
        adevices = [d for d in devices if d in self.config['devices']]

        if len(devices) == 0:
            self.log.error('No NFS mount points were found')
            return

        metrics = {}
        stats = nfs_iostat(mountstats, adevices)

        nfs_ops = {}
        # ops are reported by mount point but this is disingenuous as
        # they are actually tracked per server.  untangle here
        for mount, info in stats.iteritems():
            nfs_server = info['export'].split(':')[0].split('.')[0].strip()
            nfs_server_ops = round(float(info['ops']), 2)
            nfs_server_ops_name = '%s' % (nfs_server,)
            nfs_ops[nfs_server_ops_name] = nfs_server_ops

        for name, value in nfs_ops.iteritems():
            nfs_server_dops = self.delta(name, value)
            metrics[name + '.ops'] = nfs_server_dops
            ops_rate = nfs_server_dops / float(self.config['interval'])
            metrics[name + '.ops_per_sec'] = ops_rate

        for mount, info in stats.iteritems():
            mount = mount.lstrip('/').replace('/', '_')

            spec_attr = ['rtt_ms', 'exe_ms']
            for a in self.config['attributes']:
                for k, v in info[a].iteritems():

                    # handle with ops for rate
                    if k in spec_attr:
                        pass

                    name = "%s.%s.%s" % (mount, a, k)
                    value = round(float(v), 2)
                    dvalue = self.delta(name, value)

                    # when figuring ops for an attribute
                    # handle some special values as a per op value
                    if k == 'ops':
                        for sa in spec_attr:
                            sa_name = '%s_%s_avg' % (name, sa)
                            if dvalue == 0:
                                sa_per = 0
                            else:
                                sa_delta = self.delta(sa_name, info[a][sa])
                                sa_per = sa_delta / dvalue
                            metrics[sa_name] = sa_per

                    metrics[name] = dvalue

        for name, value in metrics.iteritems():
            self.publish(name, value)
