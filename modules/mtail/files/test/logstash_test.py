# SPDX-License-Identifier: Apache-2.0
import mtail_store
import unittest
import os

test_dir = os.path.join(os.path.dirname(__file__))


class LogstashTest(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
                os.path.join(test_dir, '../programs/logstash.mtail'),
                os.path.join(test_dir, 'logs/logstash.test'))

    def testIndexFailure(self):
        s = self.store.get_samples('logstash_elasticsearch_index_failure_total')
        self.assertIn(('', 2), s)

        s = self.store.get_samples('logstash_elasticsearch_index_errors_total')
        self.assertIn(('error=mapper_parsing_exception', 2), s)

    def testErrors(self):
        s = self.store.get_samples('logstash_log_level_total')
        self.assertIn(('level=INFO', 1), s)
        self.assertIn(('level=WARN', 2), s)
