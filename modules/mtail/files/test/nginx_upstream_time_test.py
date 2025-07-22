#!/usr/bin/python3
# SPDX-License-Identifier: Apache-2.0
import os
import unittest
import mtail_store

test_dir = os.path.dirname(__file__)


class NginxTests(unittest.TestCase):
    def setUp(self):
        self.store = mtail_store.MtailMetricStore(
            os.path.join(test_dir, '../programs/nginx_upstream_time.mtail'),
            os.path.join(test_dir, 'logs/nginx_upstream_time.test')
        )

    def test_requests_total(self):
        s = self.store.get_samples('nginx_http_requests_total')
        self.assertIn(('method=GET,status_code=200', 2), s)
        self.assertIn(('method=POST,status_code=401', 1), s)
        self.assertIn(('method=PUT,status_code=201', 1), s)
        self.assertIn(('method=DELETE,status_code=500', 1), s)

    def test_http_request_duration(self):
        s = self.store.get_samples('nginx_http_request_duration_seconds')
        s_dict = dict(s)

        response = 'method=GET,status_code=200'
        self.assertEqual(s_dict[response]['count'], 2)
        self.assertEqual(s_dict[response]['sum'], 0.33)
        self.assertEqual(s_dict[response]['buckets']['0.1'], 1)
        self.assertEqual(s_dict[response]['buckets']['0.25'], 1)

        response = 'method=POST,status_code=401'
        self.assertEqual(s_dict[response]['count'], 1)
        self.assertEqual(s_dict[response]['sum'], 0.15)
        self.assertEqual(s_dict[response]['buckets']['0.25'], 1)

    def test_upstream_connect_time(self):
        s = self.store.get_samples('nginx_upstream_connect_time_seconds')
        s_dict = dict(s)

        response = 'method=PUT,status_code=201'
        self.assertEqual(s_dict[response]['count'], 1)
        self.assertEqual(s_dict[response]['sum'], 0.035)
        self.assertEqual(s_dict[response]['buckets']['0.05'], 1)

    def test_upstream_header_time(self):
        s = self.store.get_samples('nginx_upstream_header_time_seconds')
        s_dict = dict(s)

        response = 'method=DELETE,status_code=500'
        self.assertEqual(s_dict[response]['count'], 1)
        self.assertEqual(s_dict[response]['sum'], 0.2)
        self.assertEqual(s_dict[response]['buckets']['0.25'], 1)

    def test_upstream_response_time(self):
        s = self.store.get_samples('nginx_upstream_response_time_seconds')
        s_dict = dict(s)

        response = 'method=DELETE,status_code=500'
        self.assertEqual(s_dict[response]['count'], 1)
        self.assertEqual(s_dict[response]['sum'], 1.2)
        self.assertEqual(s_dict[response]['buckets']['+Inf'], 0)
