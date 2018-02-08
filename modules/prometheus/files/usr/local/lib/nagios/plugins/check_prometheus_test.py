import unittest
import time

from check_prometheus import PrometheusCheck, PREDICATE
from check_prometheus import EX_OK, EX_CRITICAL, EX_WARNING, EX_UNKNOWN


class PrometheusCheckTest(unittest.TestCase):
    def setUp(self):
        self.c = PrometheusCheck('localhost')

    def _build_scalar(self, value):
        return [time.time(), '{}'.format(value)]

    def _check_scalar(self, value, warning, critical, predicate='ge', nan_ok=False):
        status, text = self.c._check_scalar(
                [time.time(), '{}'.format(value)],
                PREDICATE.get(predicate), warning, critical, nan_ok)
        return status

    def testScalarThreshold(self):
        self.assertEquals(EX_OK, self._check_scalar(5, 10, 20))
        self.assertEquals(EX_OK, self._check_scalar(9, 10, 20))
        self.assertEquals(EX_WARNING, self._check_scalar(10, 10, 20))
        self.assertEquals(EX_WARNING, self._check_scalar(15, 10, 20))
        self.assertEquals(EX_CRITICAL, self._check_scalar(20, 10, 20))
        self.assertEquals(EX_CRITICAL, self._check_scalar(21, 10, 20))
        self.assertEquals(EX_UNKNOWN, self._check_scalar('NaN', 10, 20))


if __name__ == '__main__':
    unittest.main()
