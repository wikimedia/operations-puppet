import argparse
import logging
import os
import re
import subprocess
import sys

import psutil

log = logging.getLogger(__name__)


# shim compatibility class for python-psutil < 2.0.0 (precise/trusty)
# note this covers only the attributes we're using
class CompatProcess(psutil.Process):
    def __init__(self, *args, **kwargs):
        super(CompatProcess, self).__init__(*args, **kwargs)
        for attr in ('children', 'num_threads', 'cpu_times', 'memory_percent',
                     'cpu_percent'):
            if not hasattr(self, attr):
                setattr(self, attr, getattr(self, 'get_' + attr))


class ServiceStats(object):
    """Gather system-level statistics for a given systemd/upstart service."""

    CPU_SAMPLE_INTERVAL = 0.2

    def _processes(self, name):
        raise NotImplementedError

    def stats(self, name):
        """Return a dict name -> value for stats."""
        procs = self._processes(name)
        if not procs:
            log.error('unable to find processes for service %s', name)
            return None

        return ServiceStats._collect_stats(procs)

    @staticmethod
    def from_pid(*pids):
        procs = []
        for pid in pids:
            try:
                procs.append(CompatProcess(pid))
            except psutil.NoSuchProcess, e:
                log.exception(e)
                continue

        if not procs:
            log.warn('unable to find processes for pids %r', pids)
            return None

        return ServiceStats._collect_stats(procs)

    @staticmethod
    def _collect_stats(procs):
        stats = {}
        for proc in procs:
            proc_stats = ServiceStats._proc_stats(proc)
            stats = ServiceStats._merge_stats(stats, proc_stats)
        return stats

    @staticmethod
    def _proc_stats(process):
        proc_attrs = ['create_time', 'num_threads', 'cpu_times',
                      'memory_percent']
        pinfo = process.as_dict(proc_attrs, ad_value=None)
        user_time, system_time = pinfo['cpu_times']
        del pinfo['cpu_times']
        pinfo['system_time'] = system_time
        pinfo['user_time'] = user_time

        # There's two ways to calculate cpu_percent, ps doesn't sample and
        # does something like this:
        #   pinfo['cpu_percent'] = 100 * \
        #     (user_time + system_time) / (time.time() - pinfo['create_time'])
        # but that gets skewed right after a process has restarted.
        # Let's sample for CPU_SAMPLE_INTERVAL seconds instead:
        pinfo['cpu_percent'] = process.cpu_percent(
            ServiceStats.CPU_SAMPLE_INTERVAL)
        return pinfo

    @staticmethod
    def _merge_stats(stats, child_stats):
        r = stats.copy()
        for stat_name in child_stats:
            # report the earliest create_time
            if stat_name == 'create_time':
                r['create_time'] = min(r.get('create_time', sys.maxint),
                                       child_stats['create_time'])
            else:
                r[stat_name] = r.get(stat_name, 0) + child_stats[stat_name]
        return r


class SystemdService(ServiceStats):
    @staticmethod
    def _processes(name):
        try:
            out = subprocess.check_output([
                '/bin/systemctl', '-p', 'ControlGroup,LoadState',
                'show', name])
        except subprocess.CalledProcessError, e:
            log.exception(e)
            return None

        out_dict = dict([l.strip().split('=', 1)
                        for l in out.split('\n') if l])
        service_cg = out_dict.get('ControlGroup', None)
        load_state = out_dict.get('LoadState', None)

        if not load_state or load_state != 'loaded':
            log.warn('invalid LoadState %s for %s', load_state, name)
            return None
        if not service_cg:
            log.warn('unable to find control group for %s', name)
            return None

        service_procs = os.path.join('/sys/fs/cgroup/systemd/',
                                     service_cg.strip('/'), 'cgroup.procs')
        log.debug('inspecting %s for %s processes', service_procs, name)
        with open(service_procs, 'r') as f:
            procs = [int(x.strip()) for x in f.readlines()]

        try:
            return [CompatProcess(x) for x in procs]
        except psutil.NoSuchProcess, e:
            log.exception(e)
            return None


class UpstartService(ServiceStats):
    PID_RE = re.compile('^.+?, process (\d+).*?$')

    @staticmethod
    def _processes(name):
        try:
            out = subprocess.check_output(['/sbin/initctl', 'status', name],
                                          env={'LANG': 'C'})
            m = UpstartService.PID_RE.match(out.strip())
            if not m:
                return None
            main_pid = int(m.group(1))
        except subprocess.CalledProcessError, e:
            log.exception(e)
            return None
        except ValueError, e:
            log.exception(e)
            return None

        try:
            procs = []
            main_proc = CompatProcess(main_pid)
            procs.append(main_proc)
            children = main_proc.children()
            procs.extend([CompatProcess(x.pid) for x in children])
            log.debug('processes found for %s: %r',
                      name, [x.pid for x in procs])
            return procs
        except psutil.NoSuchProcess, e:
            log.exception(e)
            return None


def main():
    logging.basicConfig(level=logging.DEBUG)

    parser = argparse.ArgumentParser()
    parser.add_argument('--service', default=None, action='append')
    args = parser.parse_args()

    if args.service is None:
        args.service = ['ssh', 'rsyslog']

    # lame autodetection, used only for integration testing
    try:
        if os.readlink('/sbin/init').endswith('systemd'):
            p = SystemdService()
    except OSError, e:
        if e.errno == 22:
            p = UpstartService()
        else:
            raise e

    for name in args.service:
        print '%s stats: %r' % (name, p.stats(name))


if __name__ == '__main__':
    sys.exit(main())
