import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class MediaWikiAccessLogTest(unittest.TestCase):
    def setUp(self):
        self._handler_codes = {
            'php7': 'proxy:unix:/run/php/fpm-www.sock|fcgi://localhost',
            'static': '-'
        }
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/mediawiki_access_log.mtail'),
                os.path.join(test_dir, 'logs/mediawiki_access_log.test'))

    def id_str(self, handler, method='GET', code=200):
        return "handler=%s,method=%s,code=%d" % (
            self._handler_codes[handler],
            method,
            code
        )

    def testByHandler(self):
        """Test requests are correctly divided by handler."""
        s = self.store.get_samples('mediawiki_http_requests_duration')
        for sample in s:
            if sample[0] == self.id_str('php7'):
                self.assertEqual(sample[1]['count'], 5)
            elif sample[0] == self.id_str('static', code=301):
                self.assertEqual(sample[1]['count'], 1)

    def testByBucket(self):
        """Tests requests are correctly divided by bucket."""
        s = self.store.get_samples('mediawiki_http_requests_duration')
        req_id = self.id_str('php7')
        my_sample = None
        # Find the sample with the correct labels
        for sample in s:
            if sample[0] == req_id:
                my_sample = sample
                break
        # verify the sample was found
        self.assertIsNotNone(my_sample)
        # now verify the distribution of requests in the histogram
        bucket = my_sample[1]['buckets']
        self.assertEqual(bucket['0.05'], 2)
        self.assertEqual(bucket['0.1'], 1)
        self.assertEqual(bucket['0.25'], 2)
        self.assertEqual(my_sample[1]['count'], 5)
