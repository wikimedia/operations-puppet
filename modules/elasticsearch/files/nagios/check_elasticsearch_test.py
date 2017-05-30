import unittest

from check_elasticsearch import Threshold


class ThresholdTest(unittest.TestCase):
    def testBasicThreshold(self):
        self.assertFalse(self._breach('>0', 0, 1))
        self.assertTrue(self._breach('0', 0, 1))
        self.assertFalse(self._breach('>=0.2', 0, 1))
        self.assertFalse(self._breach('0.2', 0, 1))

    def testInvalidThreshold(self):
        self.assertRaises(ValueError, self._breach, '')
        self.assertRaises(ValueError, self._breach, '>')
        self.assertRaises(ValueError, self._breach, '%123')
        self.assertRaises(ValueError, self._breach, '0.1%')
        self.assertRaises(ValueError, self._breach, '1.1')

    def testPercentThreshold(self):
        self.assertFalse(self._breach('>0', 0, 1))
        self.assertTrue(self._breach('>=0.34', 42, 123))
        self.assertFalse(self._breach('1', 1, 100))

    def _breach(self, threshold, *args):
        return Threshold(threshold).breach(*args)


if __name__ == '__main__':
    unittest.main()
