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
#from swift.common.utils import get_logger

# Copy2 is hairy. If we were only opening a URL, and returning it, we could
# just return the open file handle, and webob would take care of reading from
# the socket and returning the data to the client machine. If we were only
# opening a URL and writing its contents out to Swift, we could call
# put_object with the file handle and it would take care of reading from
# the socket and writing the data to the Swift proxy.
#     We have to do both at the same time. This requires that we hand over a class which
# is an iterable which reads, writes one copy to Swift (using put_object_chunked), and
# returns a copy to webob.  This is controlled by writethumb in /etc/swift/proxy.conf,

class Copy2(object):
    """
    Given an open file and a Swift object, we hand back an iterator which
    reads from the file, writes a copy into a Swift object, and returns
    what it read.
    """
    token = None

    def __init__(self, conn, app, url, container, obj, authurl, login, key,
            content_type=None, modified=None, content_length=None):
        self.app = app
        self.conn = conn
        if self.token is None:
            (account, self.token) = wmf.client.get_auth(authurl, login, key)
        if modified is not None:
            # The issue here is that we need to keep the timestamp between the
            # thumb server and us. The Migration-Timestamp header was in 1.2,
            # but was deprecated. They likely have a different solution for
            # setting the timestamp on an uploaded file.
            h = {'!Migration-Timestamp!': '%s' % modified}
        else:
            h = {}

        if content_length is not None:
            h['Content-Length'] = content_length

        full_headers = conn.info()
        etag = full_headers.getheader('ETag')
        self.copyconn = wmf.client.Put_object_chunked(url, self.token,
                container, obj, etag=etag, content_type=content_type, headers=h)

    def __iter__(self):
        # We're an iterator; we get passed back to wsgi as a consumer.
        return self

    def next(self):
        # We read from the thumb server, write out to Swift, and return it.
        data = self.conn.read(4096)
        if not data:
            # if we get a 401 error, it's okay, but we should re-auth.
            try:
                self.copyconn.close() #06 or #04 if it fails.
            except wmf.client.ClientException, err:
                if err.http_status == 401:
                    # not worth retrying the write. Thumb will get saved
                    # the next time.
                    self.token = None
                else:
                    raise
            raise StopIteration
        self.copyconn.write(data)
        return data

class ObjectController(object):
    """
    We're an object controller that doesn't actually do anything, but we
    will need these arguments later
    """

    def __init__(self):
        self.response_args = []

    def do_start_response(self, *args):
        """ Remember our arguments but do nothing with them """
        self.response_args.extend(args)

class WMFRewrite(object):
    """
    Rewrite Media Store URLs so that swift knows how to deal.

    Mostly it's a question of inserting the AUTH_ string, and changing / to - in the container section.
    """

    def __init__(self, app, conf):
        self.app = app
        self.account = conf['account'].strip()
        self.authurl = conf['url'].strip()
        self.login = conf['login'].strip()
        self.key = conf['key'].strip()
        self.thumbhost = conf['thumbhost'].strip()
        self.writethumb = 'writethumb' in conf
        self.user_agent = conf['user_agent'].strip()
        self.bind_port = conf['bind_port'].strip()
        self.shard_containers = conf['shard_containers'].strip() #all, some, none
        if (self.shard_containers == 'some'):
            # if we're supposed to shard some containers, get a cleaned list of the containers to shard
            def striplist(l):
                return([x.strip() for x in l])
            self.shard_container_list = striplist(conf['shard_container_list'].split(','))

        #self.logger = get_logger(conf)

    def handle404(self, reqorig, url, container, obj):
        """
        Return a webob.Response which fetches the thumbnail from the thumb
        host, potentially writes it out to Swift so we don't 404 next time,
        and returns it. Note also that the thumb host might write it out
        to Swift so we don't have to.
        """
        # go to the thumb media store for unknown files
        reqorig.host = self.thumbhost
        # upload doesn't like our User-agent, otherwise we could call it
        # using urllib2.url()
        opener = urllib2.build_opener()
        opener.addheaders = [('User-agent', self.user_agent)]
        # At least in theory, we shouldn't be handing out links to originals
        # that we don't have (or in the case of thumbs, can't generate).
        # However, someone may have a formerly valid link to a file, so we
        # should do them the favor of giving them a 404.
        try:
            # break apach the url, url-encode it, and put it back together
            urlobj = list(urlparse.urlsplit(reqorig.url))
            urlobj[2] = urllib2.quote(urlobj[2], '%/')
            encodedurl = urlparse.urlunsplit(urlobj)
            # ok, call the encoded url
            upcopy = opener.open(encodedurl)

        except urllib2.HTTPError,status:
            if status.code == 404:
                resp = webob.exc.HTTPNotFound('Expected original file not found')
                return resp
            else:
                resp = webob.exc.HTTPNotFound('Unexpected error %s' % status)
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

        if self.writethumb:
            # Fetch from upload, write into the cluster, and return it
            upcopy = Copy2(upcopy, self.app, url,
                urllib2.quote(container), obj, self.authurl, self.login,
                self.key, content_type=c_t, modified=last_modified,
                content_length=content_length)

        resp = webob.Response(app_iter=upcopy, content_type=c_t)
        resp.headers.add('Last-Modified', uinfo.getheader('Last-Modified'))
        return resp

    def __call__(self, env, start_response):
      #try: commented-out while debugging so you can see where stuff happened.
        req = webob.Request(env)
        # End-users should only do GET/HEAD, nothing else needs a rewrite
        if req.method != 'GET' and req.method != 'HEAD':
            return self.app(env, start_response)

        # Double (or triple, etc.) slashes in the URL should be ignored; collapse them. fixes bug 32864
        while(req.path_info != req.path_info.replace('//', '/')):
            req.path_info = req.path_info.replace('//', '/')

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

            controller = ObjectController()
            # do_start_response just remembers what it got called with,
            # because our 404 handler will generate a different response.
            app_iter = self.app(env, controller.do_start_response) #01
            status = int(controller.response_args[0].split()[0])
            headers = dict(controller.response_args[1])

            if 200 <= status < 300 or status == 304:
                # We have it! Just return it as usual.
                #headers['X-Swift-Proxy']= `headers`
                if 'etag' in headers: del headers['etag']
                return webob.Response(status=status, headers=headers,
                        app_iter=app_iter)(env, start_response) #01a
            elif status == 404: #4
                resp = self.handle404(reqorig, url, container, obj)
                return resp(env, start_response)
            elif status == 401:
                # if the Storage URL is invalid or has expired we'll get this error.
                resp = webob.exc.HTTPUnauthorized('Token may have timed out') #05
                return resp(env, start_response)
            else:
                resp = webob.exc.HTTPNotImplemented('Unknown Status: %s' % (status)) #10
                return resp(env, start_response)
        else:
            resp = webob.exc.HTTPBadRequest('Regexp failed: "%s"' % (req.path)) #11
            return resp(env, start_response)

def filter_factory(global_conf, **local_conf):
    conf = global_conf.copy()
    conf.update(local_conf)

    def wmfrewrite_filter(app):
        return WMFRewrite(app, conf)
    return wmfrewrite_filter

