# Portions Copyright (c) 2010 OpenStack, LLC.
# Everything else Copyright (c) 2011 Wikimedia Foundation, Inc.
# all of it licensed under the Apache Software License, included by reference.

# unit test is in test_rewrite.py. Tests are referenced by numbered comments.

import webob
import webob.exc
import re
from eventlet.green import urllib2
import wmf.client
import time
import urlparse
from swift.common.utils import get_logger
from swift.common.wsgi import WSGIContext

class WMFRewrite(WSGIContext):
    """
    Rewrite Media Store URLs so that swift knows how to deal.

    Mostly it's a question of inserting the AUTH_ string, and changing / to - in the container section.
    """

    def __init__(self, app, conf):
        def striplist(l):
            return([x.strip() for x in l])
        self.app = app
        self.account = conf['account'].strip()
        self.authurl = conf['url'].strip()
        self.login = conf['login'].strip()
        self.key = conf['key'].strip()
        self.thumbhost = conf['thumbhost'].strip()
        self.user_agent = conf['user_agent'].strip()
        self.bind_port = conf['bind_port'].strip()
        self.shard_containers = conf['shard_containers'].strip() #all, some, none
        if (self.shard_containers == 'some'):
            # if we're supposed to shard some containers, get a cleaned list of the containers to shard
            self.shard_container_list = striplist(conf['shard_container_list'].split(','))
        # this parameter controls whether URLs sent to the thumbhost are sent as is (eg. upload/proj/lang/) or with the site/lang
        # converted  and only the path sent back (eg en.wikipedia/thumb).
        self.backend_url_format = conf['backend_url_format'].strip() #'asis', 'sitelang'

        self.logger = get_logger(conf)

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
        opener = urllib2.build_opener(proxy_handler)
        # Pass on certain headers from the caller squid to the scalers
        opener.addheaders = []
        if reqorig.headers.get('User-Agent') != None:
            opener.addheaders.append(('User-Agent', reqorig.headers.get('User-Agent')))
        else:
            opener.addheaders.append(('User-Agent', self.user_agent))
        for header_to_pass in ['X-Forwarded-For', 'X-Original-URI']:
            if reqorig.headers.get( header_to_pass ) != None:
                opener.addheaders.append((header_to_pass, reqorig.headers.get( header_to_pass )))
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

            # if sitelang, we're supposed to mangle the URL so that
            # http://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Little_kitten_.jpg/330px-Little_kitten_.jpg
            # changes to http://commons.wikipedia.org/thumb/a/a2/Little_kitten_.jpg/330px-Little_kitten_.jpg
            if self.backend_url_format == 'sitelang':
                match = re.match(r'^http://(?P<host>[^/]+)/(?P<proj>[^-/]+)/(?P<lang>[^/]+)/thumb/(?P<path>.+)', encodedurl)
                if match:
                    proj = match.group('proj')
                    lang = match.group('lang')
                    # and here are all the legacy special cases, imported from thumb_handler.php
                    if(proj == 'wikipedia'):
                        if(lang in ['meta', 'commons', 'internal', 'grants', 'wikimania2006']):
                            proj = 'wikimedia'
                        if(lang in ['mediawiki']):
                            lang = 'www'
                            proj = 'mediawiki'
                    hostname = '%s.%s.org' % (lang, proj)
                    if(proj == 'wikipedia' and lang == 'sources'):
                        #yay special case
                        hostname = 'wikisource.org'
                    # ok, replace the URL with just the part starting with thumb/
                    # take off the first two parts of the path (eg /wikipedia/commons/); make sure the string starts with a /
                    encodedurl = 'http://%s/w/thumb_handler.php/%s' % (hostname, match.group('path'))
                    # add in the X-Original-URI with the swift got (minus the hostname)
                    opener.addheaders.append(('X-Original-URI', list(urlparse.urlsplit(reqorig.url))[2]))
                else:
                    # ASSERT this code should never be hit since only thumbs should call the 404 handler
                    self.logger.warn("non-thumb in 404 handler! encodedurl = %s" % encodedurl)
                    resp = webob.exc.HTTPNotFound('Unexpected error')
                    return resp
            else:
                # log the result of the match here to test and make sure it's sane before enabling the config
                match = re.match(r'^http://(?P<host>[^/]+)/(?P<proj>[^-/]+)/(?P<lang>[^/]+)/thumb/(?P<path>.+)', encodedurl)
                if match:
                    proj = match.group('proj')
                    lang = match.group('lang')
                    self.logger.warn("sitelang match has proj %s lang %s encodedurl %s" % (proj, lang, encodedurl))
                else:
                    self.logger.warn("no sitelang match on encodedurl: %s" % encodedurl)

            # ok, call the encoded url
            upcopy = opener.open(encodedurl)
        except urllib2.HTTPError,status:
            if status.code == 404:
                resp = webob.exc.HTTPNotFound('Expected original file not found')
                return resp
            else:
                resp = webob.exc.HTTPNotFound('Unexpected error %s' % status)
                resp.body = "".join(status.readlines())
                resp.status = status.code
                return resp

        # get the Content-Type.
        uinfo = upcopy.info()
        c_t = uinfo.gettype()
        content_length = uinfo.getheader('Content-Length', None)
        # sometimes Last-Modified isn't present; use now() when that happens.
        try:
            last_modified = time.mktime(uinfo.getdate('Last-Modified'))
        except TypeError:
            last_modified = time.mktime(time.localtime())

        resp = webob.Response(app_iter=upcopy, content_type=c_t)
        # add in the headers if we've got them
        for header in ['Content-Length', 'Content-Disposition', 'Last-Modified', 'Accept-Ranges']:
            if(uinfo.getheader(header)):
                resp.headers.add(header, uinfo.getheader(header))
        return resp

    def __call__(self, env, start_response):
      #try: commented-out while debugging so you can see where stuff happened.
        req = webob.Request(env)
        # End-users should only do GET/HEAD, nothing else needs a rewrite
        if req.method != 'GET' and req.method != 'HEAD':
            return self.app(env, start_response)

        # Double (or triple, etc.) slashes in the URL should be ignored; collapse them. fixes bug 32864
        req.path_info = re.sub( r'/{2,}', '/', req.path_info )

        # If it already has AUTH, presume that it's good. #07. fixes bug 33620
        hasauth = re.search('/AUTH_[0-9a-fA-F-]{32,36}', req.path)
        if req.path.startswith('/auth') or hasauth:
            return self.app(env, start_response)

        # keep a copy of the original request so we can ask the scalers for it
        reqorig = req.copy()

        # Containers have 4 components: project, language, zone, and shard.
        # Shard is optional (and configurable).  If there's no zone in the URL,
        # the zone is 'public'.  Project, language, and zone are turned into containers
        # with the pattern proj-lang-local-zone (or proj-lang-local-zone.shard).
        # Projects are wikipedia, wikinews, etc.
        # Languages are en, de, fr, commons, etc.
        # Zones are public, thumb, and temp.
        # Shards are stolen from the URL and are 2 digits of hex.
        # Examples:
        # Rewrite URLs of these forms (source, temp, and thumbnail files):
        # (a) http://upload.wikimedia.org/<proj>/<lang>/.*
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-public/.*
        # (b) http://upload.wikimedia.org/<proj>/<lang>/archive/.*
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-public/archive/.*
        # (c) http://upload.wikimedia.org/<proj>/<lang>/thumb/.*
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-thumb/.*
        # (d) http://upload.wikimedia.org/<proj>/<lang>/thumb/archive/.*
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-thumb/archive/.*
        # (e) http://upload.wikimedia.org/<proj>/<lang>/thumb/temp/.*
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-thumb/temp/.*
        # (f) http://upload.wikimedia.org/<proj>/<lang>/temp/.*
        #         => http://msfe/v1/AUTH_<hash>/<proj>-<lang>-local-temp/.*
        match = re.match(r'^/(?P<proj>[^/]+)/(?P<lang>[^/]+)/((?P<zone>thumb|temp)/)?(?P<path>((temp|archive)/)?[0-9a-f]/(?P<shard>[0-9a-f]{2})/.+)$', req.path)
        if match:
            # Get the repo zone (if not provided that means "public")
            zone = (match.group('zone') if match.group('zone') else 'public')
            # Get the object path relative to the zone (and thus container)
            obj = match.group('path') # e.g. "archive/a/ab/..."

            # Get the per-project "conceptual" container name, e.g. "<proj><lang><repo><zone>"
            container = "%s-%s-local-%s" % (match.group('proj'), match.group('lang'), zone) #02/#03
            # Add 2-digit shard to the container if it is supposed to be sharded.
            # We may thus have an "actual" container name like "<proj><lang><repo><zone>.<shard>"
            if ( (self.shard_containers == 'all') or \
                 ((self.shard_containers == 'some') and (container in self.shard_container_list)) ):
                container += ".%s" % match.group('shard')

            # Save a url with just the account name in it.
            req.path_info = "/v1/%s" % (self.account)
            port = self.bind_port
            req.host = '127.0.0.1:%s' % port
            url = req.url[:]
            # Create a path to our object's name.
            req.path_info = "/v1/%s/%s/%s" % (self.account, container, urllib2.unquote(obj))
            #self.logger.warn("new path is %s" % req.path_info)

            # do_start_response just remembers what it got called with,
            # because our 404 handler will generate a different response.
            app_iter = self._app_call(env) #01
            status = self._get_status_int()
            headers = self._response_headers

            if 200 <= status < 300 or status == 304:
                # We have it! Just return it as usual.
                #headers['X-Swift-Proxy']= `headers`
                if 'etag' in headers: del headers['etag']
                return webob.Response(status=status, headers=headers,
                        app_iter=app_iter)(env, start_response) #01a
            elif status == 404: #4
                # only send thumbs to the 404 handler; just return a 404 for everything else.
                if zone == 'thumb':
                    resp = self.handle404(reqorig, url, container, obj)
                    return resp(env, start_response)
                else:
                    resp = webob.exc.HTTPNotFound('File not found: %s' % req.path)
                    return resp(env, start_response)
            elif status == 401:
                # if the Storage URL is invalid or has expired we'll get this error.
                resp = webob.exc.HTTPUnauthorized('Token may have timed out') #05
                return resp(env, start_response)
            else:
                resp = webob.exc.HTTPNotImplemented('Unknown Status: %s' % (status)) #10
                return resp(env, start_response)
        else:
            resp = webob.exc.HTTPNotFound('Regexp failed to match URI: "%s"' % (req.path)) #11
            return resp(env, start_response)

def filter_factory(global_conf, **local_conf):
    conf = global_conf.copy()
    conf.update(local_conf)

    def wmfrewrite_filter(app):
        return WMFRewrite(app, conf)

    return wmfrewrite_filter

# vim: set expandtab tabstop=4 shiftwidth=4 autoindent:

