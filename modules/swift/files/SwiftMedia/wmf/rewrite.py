# Portions Copyright (c) 2010 OpenStack, LLC.
# Everything else Copyright (c) 2011 Wikimedia Foundation, Inc.
# all of it licensed under the Apache Software License, included by reference.

# unit test is in test_rewrite.py. Tests are referenced by numbered comments.

import webob
import webob.exc
import re
from eventlet.green import urllib2
import urlparse
from swift.common.utils import get_logger
from swift.common.wsgi import WSGIContext


class DumbRedirectHandler(urllib2.HTTPRedirectHandler):

    def http_error_301(self, req, fp, code, msg, headers):
        return None

    def http_error_302(self, req, fp, code, msg, headers):
        return None


class _WMFRewriteContext(WSGIContext):
    """
    Rewrite Media Store URLs so that swift knows how to deal with them.
    """

    def __init__(self, rewrite, conf):
        WSGIContext.__init__(self, rewrite.app)
        self.app = rewrite.app
        self.logger = rewrite.logger

        self.account = conf['account'].strip()
        self.thumbhost = conf['thumbhost'].strip()
        self.thumborhost = conf['thumborhost'].strip()
        self.user_agent = conf['user_agent'].strip()
        self.bind_port = conf['bind_port'].strip()
        self.shard_container_list = [
            item.strip() for item in conf['shard_container_list'].split(',')]
        # this parameter controls whether URLs sent to the thumbhost are sent
        # as is (eg. upload/proj/lang/) or with the site/lang converted  and
        # only the path sent back (eg en.wikipedia/thumb).
        self.backend_url_format = conf['backend_url_format'].strip()  # asis, sitelang
        self.tld = conf['tld'].strip()

    def handle404(self, reqorig, url, container, obj):
        """
        Return a webob.Response which fetches the thumbnail from the thumb
        host and returns it. Note also that the thumb host might write it out
        to Swift so it won't 404 next time.
        """
        # go to the thumb media store for unknown files
        reqorig.host = self.thumbhost
        # upload doesn't like our User-agent, otherwise we could call it
        # using urllib2.url()
        proxy_handler = urllib2.ProxyHandler({'http': self.thumbhost})
        redirect_handler = DumbRedirectHandler()
        opener = urllib2.build_opener(redirect_handler, proxy_handler)
        # Thumbor doesn't need (and doesn't like) the proxy
        thumbor_opener = urllib2.build_opener(redirect_handler)

        # Pass on certain headers from the caller squid to the scalers
        opener.addheaders = []
        if reqorig.headers.get('User-Agent') is not None:
            opener.addheaders.append(('User-Agent', reqorig.headers.get('User-Agent')))
        else:
            opener.addheaders.append(('User-Agent', self.user_agent))
        for header_to_pass in ['X-Forwarded-For', 'X-Forwarded-Proto',
                               'Accept', 'Accept-Encoding', 'X-Original-URI']:
            if reqorig.headers.get(header_to_pass) is not None:
                opener.addheaders.append((header_to_pass, reqorig.headers.get(header_to_pass)))

        thumbor_opener.addheaders = opener.addheaders

        # At least in theory, we shouldn't be handing out links to originals
        # that we don't have (or in the case of thumbs, can't generate).
        # However, someone may have a formerly valid link to a file, so we
        # should do them the favor of giving them a 404.
        try:
            # break apach the url, url-encode it, and put it back together
            urlobj = list(urlparse.urlsplit(reqorig.url))
            # encode the URL but don't encode %s and /s
            urlobj[2] = urllib2.quote(urlobj[2], '%/')
            encodedurl = urlparse.urlunsplit(urlobj)

            # Thumbor never needs URL mangling and it needs a different host
            if self.thumborhost:
                thumbor_reqorig = reqorig.copy()
                thumbor_reqorig.host = self.thumborhost
                thumbor_urlobj = list(urlparse.urlsplit(thumbor_reqorig.url))
                thumbor_urlobj[2] = urllib2.quote(thumbor_urlobj[2], '%/')
                thumbor_encodedurl = urlparse.urlunsplit(thumbor_urlobj)

            # if sitelang, we're supposed to mangle the URL so that
            # http://upload.wm.o/wikipedia/commons/thumb/a/a2/Foo_.jpg/330px-Foo_.jpg
            # changes to
            # http://commons.wp.o/w/thumb_handler.php/a/a2/Foo_.jpg/330px-Foo_.jpg
            if self.backend_url_format == 'sitelang':
                match = re.match(
                    r'^http://(?P<host>[^/]+)/(?P<proj>[^-/]+)/(?P<lang>[^/]+)/thumb/(?P<path>.+)',
                    encodedurl)
                if match:
                    proj = match.group('proj')
                    lang = match.group('lang')
                    # and here are all the legacy special cases, imported from thumb_handler.php
                    if(proj == 'wikipedia'):
                        if(lang in ['meta', 'commons', 'internal', 'grants']):
                            proj = 'wikimedia'
                        if(lang in ['mediawiki']):
                            lang = 'www'
                            proj = 'mediawiki'
                    hostname = '%s.%s.%s' % (lang, proj, self.tld)
                    if(proj == 'wikipedia' and lang == 'sources'):
                        # yay special case
                        hostname = 'wikisource.%s' % self.tld
                    # ok, replace the URL with just the part starting with thumb/
                    # take off the first two parts of the path
                    # (eg /wikipedia/commons/); make sure the string starts
                    # with a /
                    encodedurl = 'http://%s/w/thumb_handler.php/%s' % (
                        hostname, match.group('path'))
                    # add in the X-Original-URI with the swift got (minus the hostname)
                    opener.addheaders.append(
                        ('X-Original-URI', list(urlparse.urlsplit(reqorig.url))[2]))
                else:
                    # ASSERT this code should never be hit since only thumbs
                    # should call the 404 handler
                    self.logger.warn("non-thumb in 404 handler! encodedurl = %s" % encodedurl)
                    resp = webob.exc.HTTPNotFound('Unexpected error')
                    return resp
            else:
                # log the result of the match here to test and make sure it's
                # sane before enabling the config
                match = re.match(
                    r'^http://(?P<host>[^/]+)/(?P<proj>[^-/]+)/(?P<lang>[^/]+)/thumb/(?P<path>.+)',
                    encodedurl)
                if match:
                    proj = match.group('proj')
                    lang = match.group('lang')
                    self.logger.warn(
                        "sitelang match has proj %s lang %s encodedurl %s" % (
                            proj, lang, encodedurl))
                else:
                    self.logger.warn("no sitelang match on encodedurl: %s" % encodedurl)

            # To turn thumbor off and have thumbnail traffic served by image scalers,
            # replace the line below with this one:
            # upcopy = opener.open(encodedurl)
            upcopy = thumbor_opener.open(thumbor_encodedurl)
        except urllib2.HTTPError, error:
            # copy the urllib2 HTTPError into a webob HTTPError class as-is

            class CopiedHTTPError(webob.exc.HTTPError):
                code = error.code
                title = error.msg

                def html_body(self, environ):
                    return self.detail

                def __init__(self):
                    super(CopiedHTTPError, self).__init__(
                        detail="".join(error.readlines()),
                        headers=error.hdrs.items())

            return CopiedHTTPError()
        except urllib2.URLError, error:
            msg = 'There was a problem while contacting the image scaler: %s' % \
                  error.reason
            return webob.exc.HTTPServiceUnavailable(msg)

        # get the Content-Type.
        uinfo = upcopy.info()
        c_t = uinfo.gettype()

        resp = webob.Response(app_iter=upcopy, content_type=c_t)

        headers_whitelist = [
            'Content-Length',
            'Content-Disposition',
            'Last-Modified',
            'Accept-Ranges',
            'XKey',
            'Engine',
            'Server',
            'Processing-Time',
            'Processing-Utime',
            'Request-Date',
            'Thumbor-Request-Id'
        ]

        # add in the headers if we've got them
        for header in headers_whitelist:
            if(uinfo.getheader(header)):
                resp.headers.add(header, uinfo.getheader(header))

        # also add CORS; see also our CORS middleware
        resp.headers.add('Access-Control-Allow-Origin', '*')

        return resp

    def handle_request(self, env, start_response):
        try:
            return self._handle_request(env, start_response)
        except UnicodeDecodeError:
            self.logger.exception('Failed to decode request %r', env)
            resp = webob.exc.HTTPBadRequest('Failed to decode request')
            return resp(env, start_response)

    def _handle_request(self, env, start_response):
        req = webob.Request(env)

        # Double (or triple, etc.) slashes in the URL should be ignored;
        # collapse them. fixes T34864
        req.path_info = re.sub(r'/{2,}', '/', req.path_info)

        # Keep a copy of the original request so we can ask the scalers for it
        reqorig = req.copy()

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
                    resp = webob.Response(headers=headers, body="OK\n")
                elif what == 'backend':
                    req.host = '127.0.0.1:%s' % self.bind_port
                    req.path_info = "/v1/%s/monitoring/backend" % self.account

                    app_iter = self._app_call(env)
                    status = self._get_status_int()
                    headers = self._response_headers

                    resp = webob.Response(status=status, headers=headers, app_iter=app_iter)
                else:
                    resp = webob.exc.HTTPNotFound('Monitoring type not found "%s"' % (req.path))
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

                resp = webob.Response(status=status, headers=headers, app_iter=app_iter)
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

            if 200 <= status < 300 or status == 304:
                # We have it! Just return it as usual.
                # headers['X-Swift-Proxy']= `headers`
                return webob.Response(status=status, headers=headers,
                                      app_iter=app_iter)(env, start_response)
            elif status == 404:
                # only send thumbs to the 404 handler; just return a 404 for everything else.
                if repo == 'local' and zone == 'thumb':
                    resp = self.handle404(reqorig, url, container, obj)
                    return resp(env, start_response)
                else:
                    resp = webob.exc.HTTPNotFound('File not found: %s' % req.path)
                    return resp(env, start_response)
            elif status == 401:
                # if the Storage URL is invalid or has expired we'll get this error.
                resp = webob.exc.HTTPUnauthorized('Token may have timed out')
                return resp(env, start_response)
            else:
                resp = webob.exc.HTTPNotImplemented('Unknown Status: %s' % (status))
                return resp(env, start_response)
        else:
            resp = webob.exc.HTTPNotFound('Regexp failed to match URI: "%s"' % (req.path))
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
