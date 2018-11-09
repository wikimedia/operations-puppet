import json
import subprocess
import logging


log = logging.getLogger(__name__)


class MtailMetricStore(object):
    def __init__(self, progs, logs):
        self._store = {}
        self._progs = progs
        self._logs = logs
        self.parse_metric_store(*self.run_mtail())

    def run_mtail(self):
        mtail_cmd = ['mtail', '-one_shot', '-one_shot_metrics', '-logtostderr',
                     '-progs', self._progs, '-logs', self._logs]
        process = subprocess.Popen(mtail_cmd, stderr=subprocess.PIPE, stdout=subprocess.PIPE)
        stdout, stderr = process.communicate()
        return stdout, stderr

    def parse_metric_store(self, stdout, stderr):
        metrics_store = []

        in_json = False
        for line in stdout.splitlines():
            if in_json:
                metrics_store.append(line)
            if line.startswith('Metrics store:{'):
                in_json = True
                metrics_store.append('{')

        try:
            self._store = json.loads(''.join(metrics_store))
        except ValueError as e:
            log.warn(subprocess.check_output(['dpkg-query', '-W', 'mtail']))
            log.warn(stderr)
            raise ValueError('Error parsing metric store: %r' % e)

    def get_samples(self, name):
        """Return all samples for metric name as a list of samples.
           Each sample is in this form: ("k1=v1,k2=v2", value)"""
        samples = []
        if name not in self._store:
            raise ValueError('metric %s not found in store' % name)
        for metric in self._store[name][0]['LabelValues']:
            label_names = self._store[name][0].get('Keys', [])
            label_values = metric.get('Labels', [])
            value = metric['Value']['Value']
            labelpairs = ["%s=%s" % (k, v) for k, v in zip(label_names, label_values)]
            samples.append((','.join(labelpairs), value))
        return samples
