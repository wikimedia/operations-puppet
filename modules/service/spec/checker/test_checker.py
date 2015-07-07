import checker
import unittest
import mock
import json
import os
import urllib3
import copy


class TestTemplateUrl(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.t = checker.TemplateUrl(
            'https://example.org/test/{where}{/what}{/+why}')

    def test_init(self):
        """
        Test initialization of the template url
        """
        origs = [el.original for el in self.t.tokens]
        self.assertEquals(origs, ['{where}', '{/what}', '{/+why}'])
        self.assertEquals(self.t.tokens[0].types, ['simple'])
        self.assertEquals(self.t.tokens[1].types, ['simple', 'optional'])

    def test_realize(self):
        """
        Test Realization
        """
        params = {'where': 'Rome', 'what': 'Eat', 'why': ['I', 'am', 'hungry']}
        self.assertEquals(self.t.realize(params),
                          'https://example.org/test/Rome/Eat/I/am/hungry')

        params['what'] = 'Eat:pasta'
        self.assertEquals(
            self.t.realize(params),
            'https://example.org/test/Rome/Eat%3Apasta/I/am/hungry')
        params1 = {'where': 'Rome'}
        self.assertEquals(self.t.realize(params1),
                          'https://example.org/test/Rome')

        del params['why']
        self.assertEquals(self.t.realize(params),
                          'https://example.org/test/Rome/Eat%3Apasta')


class TestEndpointRequest(unittest.TestCase):

    def mock_response(self, d):
        r = mock.create_autospec(urllib3.response.HTTPResponse)
        r.status = d['status']
        r.data = json.dumps(d['body']).encode('utf-8')

        def getheader(key):
            return d['headers'].get(key, None)
        r.getheader = mock.MagicMock(side_effect=getheader)
        checker.fetch_url = mock.MagicMock(return_value=r)

    def setUp(self):
        self.resp = {
            'body': {
                'items': [
                    {
                        'comment': '/.*/',
                        'rev': '/\\d+/',
                        'tid': '/^[0-9a-fA-F]{4}-[0-9a-fA-F]{4}$/',
                        'title': 'Foobar'
                    }
                ]
            },
            'headers': {
                'content-type': 'application/json',
                'etag': '/.+/'
            },
            'status': 200
        }

        self.ep = checker.EndpointRequest(
            "a Test endpoint",
            "http://127.0.0.1/baseurl",
            "/an/endpoint/{revision}",
            {"http_host": 'example.org', 'params': {'revision': 1}},
            copy.deepcopy(self.resp)
        )
        self.resp["body"]["items"] = [
            {"title": "Foobar",
             "comment": "blabla",
             "rev": 1,
             "tid": "00AA-abcd"}
        ]
        self.resp["headers"]["etag"] = "Imtrackingyou"

    def test_init(self):
        """
        Test initialization
        """
        self.assertEquals(self.ep.title, "a Test endpoint")
        self.assertEquals(self.ep.tpl_url._url_string,
                          "http://127.0.0.1/baseurl/an/endpoint/{revision}")
        self.assertEquals(self.ep.request_headers, {'Host': 'example.org'})
        self.assertEquals(self.ep.url_parameters, {'revision': 1})
        self.assertEquals(self.ep.resp_status, 200)
        self.assertTrue(self.ep.headers["content-type"]('application/json'))

    def test_run_ok(self):
        """
        Test a successful run
        """
        self.mock_response(self.resp)
        self.ep.run(urllib3.PoolManager())
        self.assertEquals(self.ep.status, 'OK')

    def test_run_bad_status(self):
        """
        Test an unexpected HTTP status
        """
        self.resp['status'] = 301
        self.mock_response(self.resp)
        self.ep.run(urllib3.PoolManager())
        self.assertEquals(self.ep.status, 'CRITICAL')
        self.assertEquals("Test a Test endpoint returned "
                          "the unexpected status 301 (expecting: 200)",
                          self.ep.msg)

    def test_run_bad_header(self):
        """
        Test an unexpected HTTP Header
        """
        self.resp['headers']['etag'] = ""
        self.mock_response(self.resp)
        self.ep.run(urllib3.PoolManager())
        self.assertEquals(self.ep.status, 'CRITICAL')
        self.assertEquals("Test a Test endpoint had an unexpected value "
                          "for header etag: ", self.ep.msg)

    def test_run_missing_header(self):
        """
        Test a missing HTTP header
        """
        del self.resp['headers']['etag']
        self.mock_response(self.resp)
        self.ep.run(urllib3.PoolManager())
        self.assertEquals(self.ep.status, 'CRITICAL')
        self.assertEquals("Test a Test endpoint had an unexpected value "
                          "for header etag: None", self.ep.msg)

    def test_run_bad_body(self):
        """
        Test unexpected value in body
        """
        self.resp['body']['items'][0]['tid'] = 12
        self.mock_response(self.resp)
        self.ep.run(urllib3.PoolManager())
        self.assertEquals(self.ep.status, 'WARNING')
        self.assertEquals("Test a Test endpoint responds with unexpected "
                          "body: /items[0]/tid => 12", self.ep.msg)

    def test_run_missing_body(self):
        """
        Test missing value in body
        """
        del self.resp['body']['items'][0]['tid']
        self.mock_response(self.resp)
        self.ep.run(urllib3.PoolManager())
        self.assertEquals(self.ep.status, 'WARNING')
        self.assertEquals("Test a Test endpoint responds with unexpected "
                          "body: /items[0]/tid => None", self.ep.msg)

    def test_default_response(self):
        """
        Test a simple endpoint
        """
        ep = checker.EndpointRequest(
            "simple test",
            "http://127.0.0.1:7321",
            "/test",
            {'http_host': "example.org"},
            {'status': 200},
        )
        self.mock_response(
            {"status": 200,
             "body": "Hello, World!",
             "headers": {"content-length": 3240}})
        ep.run(urllib3.PoolManager())
        self.assertEquals(self.ep.status, 'OK')


class TestCheckService(unittest.TestCase):
    routes = {}

    def add_mock_response(self, route, d):
        r = mock.create_autospec(urllib3.response.HTTPResponse)
        r.status = d['status']
        r.data = json.dumps(d['body']).encode('utf-8')

        def getheader(key):
            return d['headers'].get(key, None)
        r.getheader = mock.MagicMock(side_effect=getheader)
        self.routes[route] = r

    def router(self, client, route, **kw):
        r = route.replace(self.cs._url, '')
        return self.routes.get(r, None)

    def mock_routes(self):
        checker.fetch_url = mock.MagicMock(side_effect=self.router)

    def setUp(self):
        self.cs = checker.CheckService('127.0.0.1', 'http://example.org/api')
        fn = os.path.join(os.path.dirname(__file__), 'test.json')
        with open(fn, 'rb') as f:
            data = f.read().encode('utf-8')
        self.add_mock_response(
            '/?spec', {'status': 200, 'body': json.loads(data)})

    def test_initialize(self):
        """
        Test initialization
        """
        self.assertEquals(self.cs.host_ip, '127.0.0.1')
        self.assertEquals(self.cs._timeout, 5)
        self.assertEquals(self.cs.port, '80')
        self.assertEquals(self.cs.http_host, 'example.org')
        self.assertEquals(self.cs._url, 'http://127.0.0.1:80/api')

    def test_get_endpoints(self):
        """
        Test list of endpoints is returned
        """
        self.mock_routes()
        l = [el for el, data in self.cs.get_endpoints()]
        self.assertEquals(l, [u'/simple', u'/{who}/{verb}'])

    def test_get_ep_invalid_spec(self):
        """
        Test what endpoints are returned with incorrect specs
        """
        fn = os.path.join(os.path.dirname(__file__), 'test_error_spec.json')
        with open(fn, 'rb') as f:
            data = f.read().encode('utf-8')
        self.add_mock_response(
            '/?spec', {'status': 200, 'body': json.loads(data)})
        self.mock_routes()
        l = [el for el, _ in self.cs.get_endpoints()]
        self.assertEquals(l, [u'/{who}/{verb}'])

    def test_run(self):
        """
        Test a successful run
        """
        self.add_mock_response('/simple', {'status': 200, 'body': 'hi'})
        self.add_mock_response(
            '/joe/rulez', {'status': 200, 'body': 'For sure!'})
        self.mock_routes()
        with self.assertRaises(SystemExit) as e:
            self.cs.run()
        self.assertEquals(e.exception.code, 0)

    def test_endpoint_critical(self):
        """
        Test a critical exit
        """
        self.add_mock_response('/simple', {'status': 200, 'body': 'hi'})
        self.add_mock_response('/joe/rulez', {'status': 301, 'body': ''})
        self.mock_routes()
        with self.assertRaises(SystemExit) as e:
            self.cs.run()
        self.assertEquals(e.exception.code, 2)

    def test_endpoint_warning(self):
        """
        Test a warning exit
        """
        self.add_mock_response('/simple', {'status': 200, 'body': 'hi'})
        self.add_mock_response(
            '/joe/rulez', {'status': 200, 'body': 'For sure?'})
        self.mock_routes()
        with self.assertRaises(SystemExit) as e:
            self.cs.run()
        self.assertEquals(e.exception.code, 1)
