try:
    import urlparse
except ImportError:
    import urllib.parse as urlparse
import yaml
import urllib3
import sys
import argparse


class CheckServiceError(Exception):
    pass


def fetch_url(client, url, **kw):
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
            urllib3.exceptions.ConnectionError,
            urllib3.exceptions.ReadTimeoutError):
        raise CheckServiceError("Timeout on connection while "
                                "downloading {}".format(url))
    except Exception as e:
        raise CheckServiceError("Generic connection error: {}".format(e))


class CheckService(object):
    nagios_codes = ['OK', 'WARNING', 'CRITICAL']
    spec_url = '/?spec'

    def __init__(self, host_ip, base_url, timeout=5):
        self.host_ip = host_ip
        self.base_url = urlparse.urlsplit(base_url)
        http_host_port = self.base_url.netloc.split(':')
        if len(http_host_port) < 2:
            http_host_port.append('80')
        self.http_host, self.port = http_host_port
        self.endpoints = {}

    def _spawn_downloader(self):
        kw = {
            'retries': 1,
            'timeout': self._timeout
        }
        kw['ca_certs'] = "/etc/ssl/certs/ca-certificates.crt"
        kw['cert_reqs'] = 'CERT_REQUIRED'
        return urllib3.PoolMananger(**kw)

    def get_endpoints(self):
        http = self._spawn_downloader()
        # TODO: cache all this.
        response = fetch_url(
            http,
            self._url(self.spec_url),
            timeout=self.timeout,
            headers={'Host': self.http_host}
        )

        resp = response.data.decode('utf-8')

        try:
            r = yaml.load(resp)
        except ValueError:
            raise ValueError("No valid spec found")
        for endpoint, data in r['paths'].items():
            try:
                for x in data['x-amples']:
                    yield endpoint, x
            except KeyError:
                # No example
                pass

    def run(self):
        res = []
        status = 'OK'
        idx = self.nagios_codes.index(status)
        try:
            for endpoint, data in self.get_endpoints():
                ep_status, msg = self._check_endpoint(endpoint, data)
                res.append("{} is {}: {}".format(endpoint, status, msg))
                if ep_status != 'OK':
                    ep_idx = self.nagios_codes.index(ep_status)
                    if ep_idx >= idx:
                        status = ep_status
                        idx = ep_idx
            message = u"; ".join(res)
        except Exception as e:
            message = "Generic error: {}".format(e)
            status = 'CRITICAL'
        print message
        sys.exit(self.nagios_codes.index(status))

    def _check_endpoint(self, url, data):
        data['request']['http_host'] - self.http_host
        er = EndpointRequest(
            data['title'],
            self._url(url),
            data['request'],
            data['response']
        )
        er.run()
        return (er.status, er.msg)

    def _url(self, url):
        return "{}://{}:{}{}".format(self.base_url.scheme,
                                     self.host_ip,
                                     self.port,
                                     url)


class EndpointRequest(object):

    def __init__(self, title, url,  request, response):
        self.status = 'OK'
        self.msg = 'Endpoint {} healthy'.format(url)
        self.title = title
        self._request(request)
        self._response(response)
        self.url = url

    def _request(self, data):
        raise NotImplementedError

    def _response(self, data):
        raise NotImplementedError

    def run(self, client):
        try:

            r = fetch_url(
                client,
                self.url,
                headers=self.request_headers,
                redirect=False
            )
        except CheckServiceError as e:
            return ('CRITICAL', "Could not fetch url {}: {}".format(
                self.url, e))

        # Response status
        if r.status != self.expected.status:
            self.status = "CRITICAL"
            self.msg = "Endpoint {} returned "
            "the unexpected status {} (expecting: {})".format(
                self.url, r.status, self.expected.status)
            return

        # Headers
        for k, v in self.expected.headers:
            h = r.getheader(k)
            if h != v:
                self.status = "CRITICAL"
                self.msg = "Endpoint {} had an unexpected value "
                "for header {}: {}".format(self.url, k, h)
                return
        # Body
        if self.expected.body is not None:
            body = r.data.decode('utf-8')
            if self.expected.body != body:
                self.status = "CRITICAL"
                self.msg = "Endpoint {} responds with "
                "unexpected body: {}".format(self.url, body)


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
