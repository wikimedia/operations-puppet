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
        method = kw['method']
    else:
        method = 'GET'

    try:
        return client.request(
            method,
            url,
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
    default_response = {'status': 200 }

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
        for endpoint, data in r['paths'].items():
            if not endpoint:
                continue
            try:
                d = data['get']
                # If x-monitor is False or not present, skip this
                if not d.get('x-monitor', False):
                    continue
                examples = d.get('x-amples', [])
                if not isinstance(examples, list):
                    continue
                for x in examples:
                    yield endpoint, x
            except KeyError:
                # No GET
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
                    res.append("{} is {}: {}".format(endpoint, ep_status, msg))
                    ep_idx = self.nagios_codes.index(ep_status)
                    if ep_idx >= idx:
                        status = ep_status
                        idx = ep_idx
            message = u"; ".join(res)
            if status == 'OK':
                message = "All endpoints are healty"
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
            data['title'],
            self._url,
            endpoint,
            req,
            data.get('response', self.default_response)
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

    def __init__(self, title, base_url, endpoint,  request, response):
        """
        Initialize the endpoint request

        Args:
            title (str): a descriptive name

            base_url (str): the base url

            endpoint (str): an url template for the endpoint, per RFC 6570

            request (dict): All data for building the request

            response (dict): What we should test in the response
        """
        self.status = 'OK'
        self.msg = 'Endpoint {} healthy'.format(endpoint)
        self.title = title
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
                redirect=False
            )
        except CheckServiceError as e:
            return ('CRITICAL', "Could not fetch url {}: {}".format(
                url, e))

        # Response status
        if r.status != self.resp_status:
            self.status = "CRITICAL"
            self.msg = ("Endpoint {} returned "
                        "the unexpected status {} (expecting: {})".format(
                            self.title, r.status, self.resp_status))
            return

        # Headers
        for k, v in self.headers.items():
            h = r.getheader(k)
            if not v(h):
                self.status = "CRITICAL"
                self.msg = ("Endpoint {} had an unexpected value "
                            "for header {}: {}".format(self.title, k, h))
                return
        # Body
        if self.body is not None:
            body = r.data.decode('utf-8')
            if isinstance(self.body, dict):
                data = json.loads(body)
                self._check_json_chunk(data, self.body)
            else:
                check = self._verify(self.body)
                if not check(body):
                    self.status = "CRITICAL"
                    self.msg = ("Endpoint {} responds with unexpected "
                                "body: {}".format(self.title, body))
                    return

    def _request(self, data):
        """
        Gather data from the request object
        """
        self.request_headers = {'Host': data['http_host']}
        if 'headers' in data:
            self.request_headers.update(data['headers'])
        self.url_parameters = data.get('params', {})

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

    def _verify(self, arg):
        """
        Return a lambda function to verify the response data

        Args:
            arg (str): The argument to check against. If enclosed
                       in slashes, it's assumed to be a regex
        """
        t = 'eq'
        if arg.startswith('/') and arg.endswith('/'):
            arg = arg.strip('/')
            t = 're'
        if t == 'eq':
            return lambda x: (x == arg) or x.startswith(arg)
        elif t == 're':
            return lambda x: re.search(arg, x)

    def _check_json_chunk(self, data, model, prefix='/'):
        """
        Recursively check a json chunk of the response.

        Args:
            data (mixed): the data to check

            model (mixed): the model to check the data against

            prefix (str): the depth we're checking at
        """
        if type(data) != type(model):
            return False
        if isinstance(data, str):
            check = self._verify(model)
            if not check(data):
                self.status = "CRITICAL"
                self.msg = ("Endpoint {} responds with "
                            "unexpected body: {} => {}".format(
                                self.title, prefix, data))
                return False
        elif isinstance(data, dict):
            for k, v in model.items():
                p = prefix + '/' + k
                self._check_json_chunk(data[k], v, prefix=p)
        elif isinstance(data, list):
            for i in range(len(data)):
                p = prefix + '[%d]' % i
                self._check_json_chunk(data[i], model[i], prefix=p)
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
        for token in self.tokens:
            if token.key in params:
                v = str(params[token.key])
                for transform in token.types:
                    v = self.transforms[transform](v)
            else:
                v = u""
            realized = realized.replace(
                token.original, urllib.quote_plus(v), 1)

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
