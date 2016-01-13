#!/usr/bin/python
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

try:
    import urlparse
except ImportError:
    import urllib.parse as urlparse
import json
import urllib3
import sys
import argparse
import re
import urllib
from collections import namedtuple


class CheckServiceError(Exception):

    """
    Generic Exception used as a catchall
    """
    pass


def fetch_url(client, url, **kw):
    """
    Standalone function to fetch an url.

    Args:
        client (urllib3.Poolmanager):
                                 The HTTP client we want to use
        url (str): The URL to fetch

        kw: any keyword arguments we want to pass to
            urllib3.request.RequestMethods.request
    """
    if 'method' in kw:
        method = kw['method'].upper()
        del kw['method']
    else:
        method = 'GET'
    try:
        if method == 'GET':
            return client.request(
                method,
                url,
                **kw
            )
        elif method == 'POST':
            try:
                headers = kw.get('headers', {})
                content_type = headers.get('Content-Type')
            except:
                content_type = ''

            # Handle json-encoded requests
            if content_type.lower() == 'application/json':
                kw['body'] = json.dumps(kw['fields'])
                del kw['fields']
                return client.urlopen(
                    method,
                    url,
                    **kw
                )

            return client.request_encode_body(
                method,
                url,
                encode_multipart=False,
                **kw
            )
    except urllib3.exceptions.SSLError:
        raise CheckServiceError("Invalid certificate")
    except (urllib3.exceptions.ConnectTimeoutError,
            urllib3.exceptions.TimeoutError,
            # urllib3.exceptions.ConnectionError, # commented out until we can
            # remove trusty (aka urllib3 1.7.1) support
            urllib3.exceptions.ReadTimeoutError):
        raise CheckServiceError("Timeout on connection while "
                                "downloading {}".format(url))
    except Exception as e:
        raise CheckServiceError("Generic connection error: {}".format(e))


class CheckService(object):

    """
    Shell class for checking services
    """
    nagios_codes = ['OK', 'WARNING', 'CRITICAL']
    spec_url = '/?spec'
    default_response = {'status': 200}
    _supported_methods = ['get', 'post']

    def __init__(self, host_ip, base_url, timeout=5):
        """
        Initialize the checker

        Args:
            host_ip (str): The host ipv4 address (also works with a hostname)

            base_url (str): The base url the service expects to respond from

            timeout (int): Number of seconds to wait for each request
        """
        self.host_ip = host_ip
        self.base_url = urlparse.urlsplit(base_url)
        http_host_port = self.base_url.netloc.split(':')
        if len(http_host_port) < 2:
            if self.base_url.scheme == 'https':
                http_host_port.append('443')
            else:
                http_host_port.append('80')
        self.http_host, self.port = http_host_port
        self._url_prefix = self.base_url.path
        self.endpoints = {}
        self._timeout = timeout

    @property
    def _url(self):
        """
        Returns an url pointing to the IP of the host to check.
        """
        return "{}://{}:{}{}".format(self.base_url.scheme,
                                     self.host_ip,
                                     self.port,
                                     self._url_prefix)

    def get_endpoints(self):
        """
        Gets the full spec from base_url + '/?spec' and parses it.
        Returns a generator iterating over the available endpoints
        """
        http = self._spawn_downloader()
        # TODO: cache all this.
        response = fetch_url(
            http,
            self._url + self.spec_url,
            timeout=self._timeout,
            headers={'Host': self.http_host}
        )

        resp = response.data.decode('utf-8')

        try:
            r = json.loads(resp)
        except ValueError:
            raise ValueError("No valid spec found")

        TemplateUrl.default = r.get('x-default-params', {})
        for endpoint, data in r['paths'].items():
            if not endpoint:
                continue
            for key in self._supported_methods:
                try:
                    d = data[key]
                    # If x-monitor is False, skip this
                    if not d.get('x-monitor', True):
                        continue
                    if key == 'get':
                        default_example = [{
                            'request': {},
                            'response': self.default_response
                        }]
                    else:
                        # Only GETs have default examples
                        default_example = []
                    examples = d.get('x-amples', default_example)
                    for x in examples:
                        x['http_method'] = key
                        yield endpoint, x
                except KeyError:
                    # No data for this method
                    pass

    def run(self):
        """
        Runs the checks on all the endpoints we find
        """
        res = []
        status = 'OK'
        idx = self.nagios_codes.index(status)
        try:
            for endpoint, data in self.get_endpoints():
                ep_status, msg = self._check_endpoint(endpoint, data)
                if ep_status != 'OK':
                    res.append("{} ({}) is {}: {}".format(
                        endpoint, data.get('title', 'no title'),
                        ep_status, msg))
                    ep_idx = self.nagios_codes.index(ep_status)
                    if ep_idx >= idx:
                        status = ep_status
                        idx = ep_idx
            message = u"; ".join(res)
            if status == 'OK':
                message = "All endpoints are healthy"
        except Exception as e:
            message = "Generic error: {}".format(e)
            status = 'CRITICAL'
        print message
        sys.exit(self.nagios_codes.index(status))

    def _check_endpoint(self, endpoint, data):
        """
        Actually performs the checks on each single endpoint
        """
        req = data.get('request', {})
        req['http_host'] = self.http_host
        er = EndpointRequest(
            data.get('title',
                     "test for {}".format(endpoint)),
            self._url,
            data['http_method'],
            endpoint,
            req,
            data.get('response')
        )
        er.run(self._spawn_downloader())
        return (er.status, er.msg)

    def _spawn_downloader(self):
        """
        Spawns an urllib3.Poolmanager with the correct configuration.
        """
        kw = {
            # 'retries': 1, uncomment this once we've got rid of trusty
            'timeout': self._timeout
        }
        kw['ca_certs'] = "/etc/ssl/certs/ca-certificates.crt"
        kw['cert_reqs'] = 'CERT_REQUIRED'
        return urllib3.PoolManager(**kw)


class EndpointRequest(object):

    """
    Manages a request to a specific endpoint
    """

    def __init__(self, title, base_url, http_method,
                 endpoint,  request, response):
        """
        Initialize the endpoint request

        Args:
            title (str): a descriptive name

            base_url (str): the base url

            http_method(str): the HTTP method

            endpoint (str): an url template for the endpoint, per RFC 6570

            request (dict): All data for building the request

            response (dict): What we should test in the response
        """
        self.status = 'OK'
        self.msg = 'Test "{}" healthy'.format(title)
        self.title = title
        self.method = http_method
        self._request(request)
        self._response(response)
        self.tpl_url = TemplateUrl(base_url + endpoint)

    def run(self, client):
        """
        Perform the request, and test the result

        Args:
            client (urllib3.Poolmanager): the HTTP client we want to use
        """
        try:
            url = self.tpl_url.realize(self.url_parameters)
            r = fetch_url(
                client,
                url,
                headers=self.request_headers,
                fields=self.query_parameters,
                redirect=False,
                method=self.method
            )
        except CheckServiceError as e:
            self.status = 'CRITICAL'
            self.msg = "Could not fetch url {}: {}".format(
                url, e)
            return

        # Response status
        if r.status != self.resp_status:
            self.status = "CRITICAL"
            self.msg = ("Test {} returned "
                        "the unexpected status {} (expecting: {})".format(
                            self.title, r.status, self.resp_status))
            return

        # Headers
        for k, v in self.headers.items():
            h = r.getheader(k)
            if h is None or not v(h):
                self.status = "CRITICAL"
                self.msg = ("Test {} had an unexpected value "
                            "for header {}: {}".format(self.title, k, h))
                return
        # Body
        if self.body is not None:
            body = r.data.decode('utf-8')
            if isinstance(self.body, dict) or isinstance(self.body, list):
                data = json.loads(body)
                try:
                    self._check_json_chunk(data, self.body)
                except CheckServiceError:
                    return
                except Exception as e:
                    self.status = "CRITICAL"
                    self.msg = ("Test {} responds with malformed "
                                "body: {}".format(self.title, e))
            else:
                check = self._verify(self.body)
                if not check(body):
                    self.status = "WARNING"
                    self.msg = ("Test {} responds with unexpected "
                                "body: {} != {}".format(
                                    self.title,
                                    body,
                                    self.body))
                    return

    def _request(self, data):
        """
        Gather data from the request object
        """
        self.request_headers = {'Host': data['http_host']}
        if 'headers' in data:
            self.request_headers.update(data['headers'])
        self.url_parameters = data.get('params', {})
        qkey = 'query' if self.method == 'get' else 'body'
        self.query_parameters = data.get(qkey, {})

    def _response(self, data):
        """
        Organize the expected response data
        """
        self.resp_status = data['status']
        self.body = data.get('body', None)
        self.headers = {}
        try:
            for k, v in data['headers'].items():
                self.headers[k] = self._verify(v)
        except KeyError:
            pass

    def _verify(self, orig):
        """
        Return a lambda function to verify the response data

        Args:
            arg (str): The argument to check against. If enclosed
                       in slashes, it's assumed to be a regex
        """
        arg = str(orig)
        t = 'eq'
        if arg.startswith('/') and arg.endswith('/'):
            arg = arg.strip('/')
            t = 're'
        if t == 'eq':
            return lambda x: (x == arg) or x.startswith(arg)
        elif t == 're':
            return lambda x: re.search(arg, x)

    def _check_json_chunk(self, data, model, prefix=''):
        """
        Recursively check a json chunk of the response.

        Args:
            data (mixed): the data to check

            model (mixed): the model to check the data against

            prefix (str): the depth we're checking at
        """
        if isinstance(model, dict):
            for k, v in model.items():
                p = prefix + '/' + k
                d = data.get(k, None)
                self._check_json_chunk(d, v, prefix=p)
        elif isinstance(model, list):
            for i in range(len(model)):
                p = prefix + '[%d]' % i
                self._check_json_chunk(data[i], model[i], prefix=p)
        else:
            check = self._verify(model)
            if not check(str(data)):
                self.status = "WARNING"
                self.msg = ("Test {} responds with "
                            "unexpected body: {} => {}".format(
                                self.title, prefix, data))
                raise CheckServiceError("{} => {}".format(prefix, data))
        return True


class TemplateUrl(object):

    """
    A very partial implementation of RFC 6570, limited to our use
    """
    transforms = {
        'simple': lambda x: x,
        'optional': lambda x: '/' + x,
        'multiple': lambda x: '/'.join(x)
    }
    default = {}
    base = re.compile('(\{.+?\})', re.U)

    def __init__(self, url_string):
        """
        Initialize the template

        Args:
            url_string (str): The url template
        """
        Token = namedtuple('Token', ['key', 'types', 'original'])
        self._url_string = url_string
        self.tokens = []
        for param in self.base.findall(self._url_string):
            types = ['simple']
            key = param.strip('{}')
            if key.startswith('/'):
                types.append('optional')
                key = key.lstrip('/')
            if key.startswith('+'):
                types.append('multiple')
                key = key.lstrip('+')
            self.tokens.append(Token(original=param, key=key, types=types))

    def realize(self, params):
        """
        Returns an url based on the template.

        Args:
            params (dict): the list of params to substitute in the template
        """
        realized = self._url_string
        p = {}
        p.update(self.default)
        p.update(params)
        for token in self.tokens:
            if token.key in p:
                v = p[token.key]
                if isinstance(v, list):
                    v = map(urllib.quote_plus, map(str, v))
                else:
                    v = urllib.quote_plus(str(v))
                for transform in reversed(token.types):
                    v = self.transforms[transform](v)
            else:
                v = u""
            realized = realized.replace(
                token.original, v, 1)

        return realized


def main():
    parser = argparse.ArgumentParser(
        description='Checks the availability and response of one WMF service')
    parser.add_argument('host_ip', help="The IP address of the host to check")
    parser.add_argument('service_url',
                        help="The base url for the service, including port")
    parser.add_argument('-t', dest="timeout", default=5, type=int,
                        help="Timeout (in seconds) for each "
                        "request. Default: 5")
    args = parser.parse_args()
    checker = CheckService(args.host_ip, args.service_url, args.timeout)
    checker.run()


if __name__ == '__main__':
    main()
