import json
import subprocess


class MtailMetricStore(object):
    def __init__(self, progs, logs):
        self._store = {}
        self._progs = progs
        self._logs = logs
        self.parse_metric_store(self.run_mtail()[0])

    def run_mtail(self):
        stdout, stderr = subprocess.Popen(
                ['mtail', '-one_shot', '-one_shot_metrics', '-logtostderr',
                 '-progs', self._progs, '-logs', self._logs], stderr=subprocess.PIPE,
                stdout=subprocess.PIPE).communicate()
        return stdout, stderr

    def parse_metric_store(self, output):
        metrics_store = []

        in_json = False
        for line in output.splitlines():
            if in_json:
                metrics_store.append(line)
            if line.startswith('Metrics store:{'):
                in_json = True
                metrics_store.append('{')

        self._store = json.loads(''.join(metrics_store))

    def get_metric(self, name):
        if name not in self._store:
            raise ValueError('metric %s not found in store', name)
        return MtailMetric(self._store[name][0].get('Keys', []),
                           self._store[name][0]['LabelValues'][0].get('Labels', []),
                           self._store[name][0]['LabelValues'][0]['Value']['Value'])

    def get_labels_dict(self, name):
        if name not in self._store:
            raise ValueError('metric %s not found in store', name)

        ret = {}
        for label in self._store[name][0]['LabelValues']:
            key = label['Labels'][0]
            value = label['Value']['Value']
            ret[key] = value

        return ret


class MtailMetric(object):
    def __init__(self, keys, labels, value):
        self._keys = keys
        self._labels = labels
        self._value = value
        self._labelpairs = self.get_labelpairs(keys, labels)

    def get_labelpairs(self, keys, labels):
        res = []
        for k, v in zip(keys, labels):
            res.append('%s=%s' % (k, v))
        return res
