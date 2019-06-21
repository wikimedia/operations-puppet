# Portions Copyright (c) 2010 OpenStack, LLC.
# Everything else Copyright (c) 2011 Wikimedia Foundation, Inc.
# all of it licensed under the Apache Software License, included by reference.

# unit test is in test_rewrite.py. Tests are referenced by numbered comments.

import eventlet
import re
import urlparse
import monotonic

from eventlet.green import urllib2
from swift.common import swob
from swift.common.utils import get_logger
from swift.common.wsgi import WSGIContext, make_subrequest


class DumbRedirectHandler(urllib2.HTTPRedirectHandler):

    def http_error_301(self, req, fp, code, msg, headers):
        return None

    def http_error_302(self, req, fp, code, msg, headers):
        return None


class _WMFRewriteContext(WSGIContext):
    """
    Rewrite Media Store URLs so that swift knows how to deal with them.
    """

    auth_token = False
    auth_token_expiry = 0

    def __init__(self, rewrite, conf):
        WSGIContext.__init__(self, rewrite.app)
        self.app = rewrite.app
        self.logger = rewrite.logger

        self.account = conf['account'].strip()
        self.thumborhost = conf['thumborhost'].strip()
        self.inactivedc_thumborhost = conf['inactivedc_thumborhost'].strip()
        self.user_agent = conf['user_agent'].strip()
        self.bind_port = conf['bind_port'].strip()
        self.shard_container_list = [
            item.strip() for item in conf['shard_container_list'].split(',')]
        self.thumbnail_update_expiry_headers = \
            conf['thumbnail_update_expiry_headers'].strip().lower() == 'true'
        self.thumbnail_expiry = conf['thumbnail_expiry'].strip()
        self.thumbnail_user = conf['thumbnail_user'].strip()
        self.thumbnail_key = conf['thumbnail_key'].strip()

    def thumborify_url(self, reqorig, host):
        reqorig.host = host
        thumbor_urlobj = list(urlparse.urlsplit(reqorig.url))
        thumbor_urlobj[2] = urllib2.quote(thumbor_urlobj[2], '%/')
        return urlparse.urlunsplit(thumbor_urlobj)

    def inactivedc_request(self, opener, url):
        try:
            opener.open(url)
        except urllib2.HTTPError as error:
            self.logger.warn("Inactive DC request HTTP error: %d %s %s" % (
                error.code, error.reason, url))
        except urllib2.URLError as error:
            self.logger.warn("Inactive DC request URL error: %s %s" % (error.reason, url))

    def handle404(self, reqorig, url, container, obj):
        """
        Return a swob.Response which fetches the thumbnail from the thumb
        host and returns it. Note also that the thumb host might write it out
        to Swift so it won't 404 next time.
        """
        # upload doesn't like our User-agent, otherwise we could call it
        # using urllib2.url()
        thumbor_opener = urllib2.build_opener(DumbRedirectHandler())

        # Pass on certain headers from Varnish to Thumbor
        thumbor_opener.addheaders = []
        if reqorig.headers.get('User-Agent') is not None:
            thumbor_opener.addheaders.append(('User-Agent', reqorig.headers.get('User-Agent')))
        else:
            thumbor_opener.addheaders.append(('User-Agent', self.user_agent))
        for header_to_pass in ['X-Forwarded-For', 'X-Forwarded-Proto',
                               'Accept', 'Accept-Encoding', 'X-Original-URI']:
            if reqorig.headers.get(header_to_pass) is not None:
                header = (header_to_pass, reqorig.headers.get(header_to_pass))
                thumbor_opener.addheaders.append(header)

        # At least in theory, we shouldn't be handing out links to originals
        # that we don't have (or in the case of thumbs, can't generate).
        # However, someone may have a formerly valid link to a file, so we
        # should do them the favor of giving them a 404.
        try:
            thumbor_encodedurl = self.thumborify_url(reqorig, self.thumborhost)
            upcopy = thumbor_opener.open(thumbor_encodedurl)
        except urllib2.HTTPError as error:
            # Wrap the urllib2 HTTPError into a swob HTTPException
            status = error.code
            body = error.fp.read()
            headers = error.hdrs.items()
            if status not in swob.RESPONSE_REASONS:
                # Generic status description in case of unknown status reasons.
                status = "%s Error" % status
            return swob.HTTPException(status=status, body=body, headers=headers)
        except urllib2.URLError as error:
            msg = 'There was a problem while contacting the thumbnailing service: %s' % \
                  error.reason
            return swob.HTTPServiceUnavailable(msg)

        # We successfully generated a thumbnail on the active DC, send the same request
        # blindly to the inactive DC to populate Swift there, not waiting for the response
        inactivedc_encodedurl = self.thumborify_url(reqorig, self.inactivedc_thumborhost)
        eventlet.spawn(self.inactivedc_request, thumbor_opener, inactivedc_encodedurl)

        # get the Content-Type.
        uinfo = upcopy.info()
        c_t = uinfo.gettype()

        resp = swob.Response(app_iter=upcopy, content_type=c_t)

        headers_whitelist = [
            'Content-Length',
            'Content-Disposition',
            'Last-Modified',
            'Accept-Ranges',
            'XKey',
            'Thumbor-Engine',
            'Server',
            'Nginx-Request-Date',
            'Nginx-Response-Date',
            'Thumbor-Processing-Time',
            'Thumbor-Processing-Utime',
            'Thumbor-Request-Id',
            'Thumbor-Request-Date'
        ]

        # add in the headers if we've got them
        for header in headers_whitelist:
            if(uinfo.getheader(header) != ''):
                resp.headers[header] = uinfo.getheader(header)

        # also add CORS; see also our CORS middleware
        resp.headers['Access-Control-Allow-Origin'] = '*'

        return resp

    def get_auth_token(self, env):
        if (_WMFRewriteContext.auth_token and
                _WMFRewriteContext.auth_token_expiry > monotonic.monotonic()):
            self.logger.debug('Reusing existing auth token for thumbnail expiry update')
            return _WMFRewriteContext.auth_token

        headers = {
            'X-Auth-User': self.thumbnail_user,
            'X-Auth-Key': self.thumbnail_key,
        }

        sub = make_subrequest(env, path='/auth/v1.0', headers=headers)
        resp = sub.get_response(self.app)

        if resp.status_int != 200:
            self.logger.error('Could not acquire auth token while updating thumbnail expiry')
            return False

        _WMFRewriteContext.auth_token = resp.headers['X-Auth-Token']

        expiry = int(resp.headers['X-Auth-Token-Expires'])
        _WMFRewriteContext.auth_token_expiry = monotonic.monotonic() + expiry

        return _WMFRewriteContext.auth_token

    def post_expiry(self, env):
        # Since the request to the swift proxy can be unauthenticated, we need to
        # get an auth token for the POST to update the X-Delete- header
        auth_token = self.get_auth_token(env)

        if not auth_token:
            self.logger.error('Could not acquire auth token, cannot update thumbnail expiry')
            return False

        headers = {
            'X-Delete-After': self.thumbnail_expiry,
            'X-Auth-Token': auth_token,
        }

        sub = make_subrequest(env, method='POST', headers=headers)
        return sub.get_response(self.app)

    def update_expiry(self, env):
        resp = self.post_expiry(env)

        if not resp:
            return

        if resp.status_int == 401:
            # Reset the auth token, since it's probably expired, and try again
            _WMFRewriteContext.auth_token = False
            resp = self.post_expiry(env)

        if resp and resp.status_int != 202:
            self.logger.error(
                'Could not set expiry header on path %s, HTTP status: %d' %
                (env['PATH_INFO'], resp.status_int)
            )
        elif resp:
            self.logger.debug('Successfully updated expiry header on path %s' % env['PATH_INFO'])

    def handle_request(self, env, start_response):
        try:
            return self._handle_request(env, start_response)
        except UnicodeDecodeError:
            self.logger.exception('Failed to decode request %r', env)
            resp = swob.HTTPBadRequest('Failed to decode request')
            return resp(env, start_response)

    def _handle_request(self, env, start_response):
        req = swob.Request(env)

        # Double (or triple, etc.) slashes in the URL should be ignored;
        # collapse them. fixes T34864
        req.path_info = re.sub(r'/{2,}', '/', req.path_info)

        # Keep a copy of the original request so we can ask the scalers for it
        reqorig = swob.Request(req.environ.copy())

        # Containers have 5 components: project, language, repo, zone, and shard.
        # If there's no zone in the URL, the zone is assumed to be 'public' (for b/c).
        # Shard is optional (and configurable), and is only used for large containers.
        #
        # Projects are wikipedia, wikinews, etc.
        # Languages are en, de, fr, commons, etc.
        # Repos are local, timeline, etc.
        # Zones are public, thumb, temp, etc.
        # Shard is extracted from "hash paths" in the URL and is 2 hex digits.
        #
        # These attributes are mapped to container names in the form of either:
        # (a) proj-lang-repo-zone (if not sharded)
        # (b) proj-lang-repo-zone.shard (if sharded)
        # (c) global-data-repo-zone (if not sharded)
        # (d) global-data-repo-zone.shard (if sharded)
        #
        # Rewrite wiki-global URLs of these forms:
        # (a) http://upload.wikimedia.org/math/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/global-data-math-render/<relpath>
        # (b) http://upload.wikimedia.org/<proj>/<lang>/math/<relpath> (legacy)
        #         => http://msfe/v1/AUTH_<hash>/global-data-math-render/<relpath>
        #
        # Rewrite wiki-relative URLs of these forms:
        # (a) http://upload.wikimedia.org/<proj>/<lang>/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-public/<relpath>
        # (b) http://upload.wikimedia.org/<proj>/<lang>/archive/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-public/archive/<relpath>
        # (c) http://upload.wikimedia.org/<proj>/<lang>/thumb/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-thumb/<relpath>
        # (d) http://upload.wikimedia.org/<proj>/<lang>/thumb/archive/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-thumb/archive/<relpath>
        # (e) http://upload.wikimedia.org/<proj>/<lang>/thumb/temp/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-thumb/temp/<relpath>
        # (f) http://upload.wikimedia.org/<proj>/<lang>/transcoded/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-transcoded/<relpath>
        # (g) http://upload.wikimedia.org/<proj>/<lang>/timeline/<relpath>
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-timeline-render/<relpath>

        # regular uploads
        match = re.match(
            (r'^/(?P<proj>[^/]+)/(?P<lang>[^/]+)/'
             r'((?P<zone>transcoded|thumb)/)?'
             r'(?P<path>((temp|archive)/)?[0-9a-f]/(?P<shard>[0-9a-f]{2})/.+)$'),
            req.path)
        if match:
            proj = match.group('proj')
            lang = match.group('lang')
            repo = 'local'  # the upload repo name is "local"
            # Get the repo zone (if not provided that means "public")
            zone = (match.group('zone') if match.group('zone') else 'public')
            # Get the object path relative to the zone (and thus container)
            obj = match.group('path')  # e.g. "archive/a/ab/..."
            shard = match.group('shard')

        # timeline renderings
        if match is None:
            # /wikipedia/en/timeline/a876297c277d80dfd826e1f23dbfea3f.png
            match = re.match(
                r'^/(?P<proj>[^/]+)/(?P<lang>[^/]+)/(?P<repo>timeline)/(?P<path>.+)$',
                req.path)
            if match:
                proj = match.group('proj')  # wikipedia
                lang = match.group('lang')  # en
                repo = match.group('repo')  # timeline
                zone = 'render'
                obj = match.group('path')  # a876297c277d80dfd826e1f23dbfea3f.png
                shard = ''

        # math renderings
        if match is None:
            # /math/c/9/f/c9f2055dadfb49853eff822a453d9ceb.png
            # /wikipedia/en/math/c/9/f/c9f2055dadfb49853eff822a453d9ceb.png (legacy)
            match = re.match(
                (r'^(/(?P<proj>[^/]+)/(?P<lang>[^/]+))?/(?P<repo>math)/'
                 r'(?P<path>(?P<shard1>[0-9a-f])/(?P<shard2>[0-9a-f])/.+)$'),
                req.path)

            if match:
                proj = 'global'
                lang = 'data'
                repo = match.group('repo')  # math
                zone = 'render'
                obj = match.group('path')  # c/9/f/c9f2055dadfb49853eff822a453d9ceb.png
                shard = match.group('shard1') + match.group('shard2')  # c9

        # score renderings
        if match is None:
            # /score/j/q/jqn99bwy8777srpv45hxjoiu24f0636/jqn99bwy.png
            # /score/override-midi/8/i/8i9pzt87wtpy45lpz1rox8wusjkt7ki.ogg
            match = re.match(r'^/(?P<repo>score)/(?P<path>.+)$', req.path)
            if match:
                proj = 'global'
                lang = 'data'
                repo = match.group('repo')  # score
                zone = 'render'
                obj = match.group('path')  # j/q/jqn99bwy8777srpv45hxjoiu24f0636/jqn99bwy.png
                shard = ''

        if match is None:
            match = re.match(r'^/monitoring/(?P<what>.+)$', req.path)
            if match:
                what = match.group('what')
                if what == 'frontend':
                    headers = {'Content-Type': 'application/octet-stream'}
                    resp = swob.Response(headers=headers, body="OK\n")
                elif what == 'backend':
                    req.host = '127.0.0.1:%s' % self.bind_port
                    req.path_info = "/v1/%s/monitoring/backend" % self.account

                    app_iter = self._app_call(env)
                    status = self._get_status_int()
                    headers = self._response_headers

                    resp = swob.Response(status=status, headers=headers, app_iter=app_iter)
                else:
                    resp = swob.HTTPNotFound('Monitoring type not found "%s"' % (req.path))
                return resp(env, start_response)

        if match is None:
            match = re.match(r'^/(?P<path>[^/]+)?$', req.path)
            # /index.html /favicon.ico /robots.txt etc.
            # serve from a default "root" container
            if match:
                path = match.group('path')
                if not path:
                    path = 'index.html'

                req.host = '127.0.0.1:%s' % self.bind_port
                req.path_info = "/v1/%s/root/%s" % (self.account, path)

                app_iter = self._app_call(env)
                status = self._get_status_int()
                headers = self._response_headers

                resp = swob.Response(status=status, headers=headers, app_iter=app_iter)
                return resp(env, start_response)

        # Internally rewrite the URL based on the regex it matched...
        if match:
            # Get the per-project "conceptual" container name, e.g. "<proj><lang><repo><zone>"
            container = "%s-%s-%s-%s" % (proj, lang, repo, zone)
            # Add 2-digit shard to the container if it is supposed to be sharded.
            # We may thus have an "actual" container name like "<proj><lang><repo><zone>.<shard>"
            if container in self.shard_container_list:
                container += ".%s" % shard

            # Save a url with just the account name in it.
            req.path_info = "/v1/%s" % (self.account)
            port = self.bind_port
            req.host = '127.0.0.1:%s' % port
            url = req.url[:]
            # Create a path to our object's name.
            req.path_info = "/v1/%s/%s/%s" % (self.account, container, urllib2.unquote(obj))
            # self.logger.warn("new path is %s" % req.path_info)

            # do_start_response just remembers what it got called with,
            # because our 404 handler will generate a different response.
            app_iter = self._app_call(env)
            status = self._get_status_int()
            headers = self._response_headers

            if status == 404:
                # only send thumbs to the 404 handler; just return a 404 for everything else.
                if repo == 'local' and zone == 'thumb':
                    resp = self.handle404(reqorig, url, container, obj)
                    return resp(env, start_response)
                else:
                    resp = swob.HTTPNotFound('File not found: %s' % req.path)
                    return resp(env, start_response)
            else:
                for key, value in headers:
                    if key == 'X-Delete-At' and self.thumbnail_update_expiry_headers:
                        # Update expiry header asynchronously
                        eventlet.spawn(self.update_expiry, env)
                        break

                # Return the response verbatim
                return swob.Response(status=status, headers=headers,
                                     app_iter=app_iter)(env, start_response)
        else:
            resp = swob.HTTPNotFound('Regexp failed to match URI: "%s"' % (req.path))
            return resp(env, start_response)


class WMFRewrite(object):

    def __init__(self, app, conf):
        self.app = app
        self.conf = conf
        self.logger = get_logger(conf)

    def __call__(self, env, start_response):
        # end-users should only do GET/HEAD, nothing else needs a rewrite
        if env['REQUEST_METHOD'] not in ('HEAD', 'GET'):
            return self.app(env, start_response)

        # do nothing on authenticated and authentication requests
        path = env['PATH_INFO']
        if path.startswith('/auth') or path.startswith('/v1/AUTH_'):
            return self.app(env, start_response)

        context = _WMFRewriteContext(self, self.conf)
        return context.handle_request(env, start_response)


def filter_factory(global_conf, **local_conf):
    conf = global_conf.copy()
    conf.update(local_conf)

    def wmfrewrite_filter(app):
        return WMFRewrite(app, conf)

    return wmfrewrite_filter

# vim: set expandtab tabstop=4 shiftwidth=4 autoindent:
