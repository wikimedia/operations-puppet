import unittest
import time

from check_prometheus import PrometheusCheck, PREDICATE
from check_prometheus import EX_OK, EX_CRITICAL, EX_WARNING, EX_UNKNOWN

from prometheus_client.parser import text_string_to_metric_families


class PrometheusCheckTest(unittest.TestCase):
    def setUp(self):
        self.c = PrometheusCheck('localhost')

    def _check_scalar(self, value, warning, critical, predicate='ge', nan_ok=False):
        status, text = self.c._check_scalar(
                [time.time(), '{}'.format(value)],
                PREDICATE.get(predicate), warning, critical, nan_ok)
        return status

    def _check_vector(self, metrics, warning, critical, predicate='ge', nan_ok=False):
        status, text = self.c._check_vector(
                [self._text_to_vector(x) for x in metrics],
                PREDICATE.get(predicate), warning, critical, nan_ok)
        return status

    def _text_to_vector(self, text):
        """Turn a metric from Prometheus text format (name{key="value"} number) into a metric
        dictionary like what's returned by Prometheus API."""

        result = {}
        # assume a single metric in 'text' and a single sample for that metric
        for metric in text_string_to_metric_families(text):
            # metric.samples will be [('metric name', {labels..}, value)]
            sample = metric.samples[0]
            result['value'] = [time.time(), sample[2]]
            result['metric'] = sample[1]
            result['metric']['__name__'] = sample[0]
        return result

    def testScalarThreshold(self):
        self.assertEqual(EX_OK, self._check_scalar(5, 10, 20))
        self.assertEqual(EX_OK, self._check_scalar(9, 10, 20))
        self.assertEqual(EX_WARNING, self._check_scalar(10, 10, 20))
        self.assertEqual(EX_WARNING, self._check_scalar(15, 10, 20))
        self.assertEqual(EX_CRITICAL, self._check_scalar(20, 10, 20))
        self.assertEqual(EX_CRITICAL, self._check_scalar(21, 10, 20))
        self.assertEqual(EX_UNKNOWN, self._check_scalar('NaN', 10, 20))

    def testVectorThreshold(self):
        self.assertEqual(EX_OK, self._check_vector(['up{foo="bar"} 0', 'up{foo="baz"} 1'], 10, 20))
        self.assertEqual(EX_WARNING, self._check_vector(['up{foo="bar"} 11', 'up{foo="baz"} 1'], 10, 20))
        self.assertEqual(EX_CRITICAL, self._check_vector(['up{foo="bar"} 21', 'up{foo="baz"} 1'], 10, 20))

    def testGroupAllLabels(self):
        self.assertEqual(['foo={bar,baz}', 'meh=zomg'],
                         self.c._group_all_labels([{'foo': 'bar', 'meh': 'zomg'}, {'foo': 'baz'}]))


if __name__ == '__main__':
    unittest.main()
