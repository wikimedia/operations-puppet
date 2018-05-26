# rawdog: RSS aggregator without delusions of grandeur.
# Copyright 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012, 2013, 2014, 2015, 2016 Adam Sampson <ats@offog.org>
#
# rawdog is free software; you can redistribute and/or modify it
# under the terms of that license as published by the Free Software
# Foundation; either version 2 of the License, or (at your option)
# any later version.
#
# rawdog is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with rawdog; see the file COPYING. If not, write to the Free
# Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
# MA 02110-1301, USA, or see http://www.gnu.org/.

VERSION = "2.22"
HTTP_AGENT = "rawdog/" + VERSION
STATE_VERSION = 2

import rawdoglib.feedscanner
from rawdoglib.persister import Persistable, Persister
from rawdoglib.plugins import Box, call_hook, load_plugins

from cStringIO import StringIO
import base64
import calendar
import cgi
import feedparser
import getopt
import hashlib
import locale
import os
import re
import socket
import string
import sys
import threading
import time
import types
import urllib2
import urlparse

try:
    import tidylib
except:
    tidylib = None

try:
    import mx.Tidy as mxtidy
except:
    mxtidy = None

# Turn off content-cleaning, since we want to see an approximation to the
# original content for hashing. rawdog will sanitise HTML when writing.
feedparser.RESOLVE_RELATIVE_URIS = 0
feedparser.SANITIZE_HTML = 0

# Disable microformat support, because it tends to return poor-quality data
# (e.g. identifying inappropriate things as enclosures), and it relies on
# BeautifulSoup which is unable to parse many feeds.
feedparser.PARSE_MICROFORMATS = 0

# This is initialised in main().
persister = None

system_encoding = None


def get_system_encoding():
    """Get the system encoding."""
    return system_encoding


def safe_ftime(format, t):
    """Format a time value into a string in the current locale (as
    time.strftime), but encode the result as ASCII HTML."""
    try:
        u = unicode(time.strftime(format, t), get_system_encoding())
    except ValueError, e:
        u = u"(bad time %s; %s)" % (repr(t), str(e))
    return encode_references(u)


def format_time(secs, config):
    """Format a time and date nicely."""
    try:
        t = time.localtime(secs)
    except ValueError, e:
        return u"(bad time %s; %s)" % (repr(secs), str(e))
    format = config["datetimeformat"]
    if format is None:
        format = config["timeformat"] + ", " + config["dayformat"]
    return safe_ftime(format, t)


high_char_re = re.compile(r'[^\000-\177]')


def encode_references(s):
    """Encode characters in a Unicode string using HTML references."""
    def encode(m):
        return "&#" + str(ord(m.group(0))) + ";"
    return high_char_re.sub(encode, s)


# This list of block-level elements came from the HTML 4.01 specification.
block_level_re = re.compile(
    r'^\s*<(p|h1|h2|h3|h4|h5|h6|ul|ol|pre|dl|div|noscript|blockquote|form|hr|table|fieldset|address)[^a-z]',
     re.I)


def sanitise_html(html, baseurl, inline, config):
    """Attempt to turn arbitrary feed-provided HTML into something
    suitable for safe inclusion into the rawdog output. The inline
    parameter says whether to expect a fragment of inline text, or a
    sequence of block-level elements."""
    if html is None:
        return None

    html = encode_references(html)
    type = "text/html"

    # sgmllib handles "<br/>/" as a SHORTTAG; this workaround from
    # feedparser.
    html = re.sub(r'(\S)/>', r'\1 />', html)

    # sgmllib is fragile with broken processing instructions (e.g.
    # "<!doctype html!>"); just remove them all.
    html = re.sub(r'<![^>]*>', '', html)

    html = feedparser._resolveRelativeURIs(html, baseurl, "UTF-8", type)
    p = feedparser._HTMLSanitizer("UTF-8", type)
    p.feed(html)
    html = p.output()

    if not inline and config["blocklevelhtml"]:
        # If we're after some block-level HTML and the HTML doesn't
        # start with a block-level element, then insert a <p> tag
        # before it. This still fails when the HTML contains text, then
        # a block-level element, then more text, but it's better than
        # nothing.
        if block_level_re.match(html) is None:
            html = "<p>" + html

    if config["tidyhtml"]:
        args = {
            "numeric_entities": 1,
            "input_encoding": "ascii",
            "output_encoding": "ascii",
            "output_html": 1,
            "output_xhtml": 0,
            "output_xml": 0,
            "wrap": 0,
            }
        call_hook("mxtidy_args", config, args, baseurl, inline)
        call_hook("tidy_args", config, args, baseurl, inline)
        if tidylib is not None:
            # Disable PyTidyLib's somewhat unhelpful defaults.
            tidylib.BASE_OPTIONS = {}
            output = tidylib.tidy_document(html, args)[0]
        elif mxtidy is not None:
            output = mxtidy.tidy(html, None, None, **args)[2]
        else:
            # No Tidy bindings installed -- do nothing.
            output = "<body>" + html + "</body>"
        html = output[output.find("<body>") + 6: output.rfind("</body>")].strip()

    html = html.decode("UTF-8")
    box = Box(html)
    call_hook("clean_html", config, box, baseurl, inline)
    return box.value


def select_detail(details):
    """Pick the preferred type of detail from a list of details. (If the
    argument isn't a list, treat it as a list of one.)"""
    TYPES = {
        "text/html": 30,
        "application/xhtml+xml": 20,
        "text/plain": 10,
        }

    if details is None:
        return None
    if type(details) is not list:
        details = [details]

    ds = []
    for detail in details:
        ctype = detail.get("type", None)
        if ctype is None:
            continue
        if TYPES.has_key(ctype):
            score = TYPES[ctype]
        else:
            score = 0
        if detail["value"] != "":
            ds.append((score, detail))
    ds.sort()

    if len(ds) == 0:
        return None
    else:
        return ds[-1][1]


def detail_to_html(details, inline, config, force_preformatted=False):
    """Convert a detail hash or list of detail hashes as returned by
    feedparser into HTML."""
    detail = select_detail(details)
    if detail is None:
        return None

    if force_preformatted:
        html = "<pre>" + cgi.escape(detail["value"]) + "</pre>"
    elif detail["type"] == "text/plain":
        html = cgi.escape(detail["value"])
    else:
        html = detail["value"]

    return sanitise_html(html, detail["base"], inline, config)


def author_to_html(entry, feedurl, config):
    """Convert feedparser author information to HTML."""
    author_detail = entry.get("author_detail")

    if author_detail is not None and author_detail.has_key("name"):
        name = author_detail["name"]
    else:
        name = entry.get("author")

    url = None
    fallback = "author"
    if author_detail is not None:
        if author_detail.has_key("href"):
            url = author_detail["href"]
        elif author_detail.has_key("email") and author_detail["email"] is not None:
            url = "mailto:" + author_detail["email"]
        if author_detail.has_key("email") and author_detail["email"] is not None:
            fallback = author_detail["email"]
        elif author_detail.has_key("href") and author_detail["href"] is not None:
            fallback = author_detail["href"]

    if name == "":
        name = fallback

    if url is None:
        html = name
    else:
        html = "<a href=\"" + cgi.escape(url) + "\">" + cgi.escape(name) + "</a>"

    # We shouldn't need a base URL here anyway.
    return sanitise_html(html, feedurl, True, config)


def string_to_html(s, config):
    """Convert a string to HTML."""
    return sanitise_html(cgi.escape(s), "", True, config)


template_re = re.compile(r'(__[^_].*?__)')


def fill_template(template, bits):
    """Expand a template, replacing __x__ with bits["x"], and only
    including sections bracketed by __if_x__ .. [__else__ ..]
    __endif__ if bits["x"] is not "". If not bits.has_key("x"),
    __x__ expands to ""."""
    result = Box()
    call_hook("fill_template", template, bits, result)
    if result.value is not None:
        return result.value

    encoding = get_system_encoding()

    f = StringIO()
    if_stack = []

    def write(s):
        if not False in if_stack:
            f.write(s)
    for part in template_re.split(template):
        if part.startswith("__") and part.endswith("__"):
            key = part[2:-2]
            if key.startswith("if_"):
                k = key[3:]
                if_stack.append(bits.has_key(k) and bits[k] != "")
            elif key == "endif":
                if if_stack != []:
                    if_stack.pop()
            elif key == "else":
                if if_stack != []:
                    if_stack.append(not if_stack.pop())
            elif bits.has_key(key):
                if type(bits[key]) == types.UnicodeType:
                    write(bits[key].encode(encoding))
                else:
                    write(bits[key])
        else:
            write(part)
    v = f.getvalue()
    f.close()
    return v


file_cache = {}


def load_file(name):
    """Read the contents of a template file, caching the result so we don't
    have to read the file multiple times. The file is assumed to be in the
    system encoding; the result will be an ASCII string."""
    if not file_cache.has_key(name):
        try:
            f = open(name)
            data = f.read()
            f.close()
        except IOError:
            raise ConfigError("Can't read template file: " + name)

        try:
            data = data.decode(get_system_encoding())
        except UnicodeDecodeError, e:
            raise ConfigError(
    "Character encoding problem in template file: " +
    name +
    ": " +
     str(e))

        data = encode_references(data)
        file_cache[name] = data.encode(get_system_encoding())
    return file_cache[name]


def write_ascii(f, s, config):
    """Write the string s, which should only contain ASCII characters, to
    file f; if it isn't encodable in ASCII, then print a warning message
    and write UTF-8."""
    try:
        f.write(s)
    except UnicodeEncodeError, e:
        config.bug("Error encoding output as ASCII; UTF-8 has been written instead.\n", e)
        f.write(s.encode("UTF-8"))


def short_hash(s):
    """Return a human-manipulatable 'short hash' of a string."""
    return hashlib.sha1(s).hexdigest()[-8:]


def ensure_unicode(value, encoding):
    """Convert a structure returned by feedparser into an equivalent where
    all strings are represented as fully-decoded unicode objects."""

    if isinstance(value, str):
        try:
            return value.decode(encoding)
        except:
            # If the encoding's invalid, at least preserve
            # the byte stream.
            return value.decode("ISO-8859-1")
    elif isinstance(value, unicode) and type(value) is not unicode:
        # This is a subclass of unicode (e.g.  BeautifulSoup's
        # NavigableString, which is unpickleable in some versions of
        # the library), so force it to be a real unicode object.
        return unicode(value)
    elif isinstance(value, dict):
        d = {}
        for (k, v) in value.items():
            d[k] = ensure_unicode(v, encoding)
        return d
    elif isinstance(value, list):
        return [ensure_unicode(v, encoding) for v in value]
    else:
        return value


timeout_re = re.compile(r'timed? ?out', re.I)


def is_timeout_exception(exc):
    """Return True if the given exception object suggests that a timeout
    occurred, else return False."""

    # Since urlopen throws away the original exception object,
    # we have to look at the stringified form to tell if it was a timeout.
    # (We're in reasonable company here, since test_ssl.py in the Python
    # distribution does the same thing!)
    #
    # The message we're looking for is something like:
    # Stock Python 2.7.7 and 2.7.8:
    #   <urlopen error _ssl.c:495: The handshake operation timed out>
    # Debian python 2.7.3-4+deb7u1:
    #   <urlopen error _ssl.c:489: The handshake operation timed out>
    # Debian python 2.7.8-1:
    #   <urlopen error ('_ssl.c:563: The handshake operation timed out',)>
    return timeout_re.search(str(exc)) is not None


class BasicAuthProcessor(urllib2.BaseHandler):
    """urllib2 handler that does HTTP basic authentication
    or proxy authentication with a fixed username and password.
    (Unlike the classes to do this in urllib2, this doesn't wait
    for a 401/407 response first.)"""

    def __init__(self, user, password, proxy=False):
        self.auth = base64.b64encode(user + ":" + password)
        if proxy:
            self.header = "Proxy-Authorization"
        else:
            self.header = "Authorization"

    def http_request(self, req):
        req.add_header(self.header, "Basic " + self.auth)
        return req

    https_request = http_request


class DisableIMProcessor(urllib2.BaseHandler):
    """urllib2 handler that disables RFC 3229 for a request."""

    def http_request(self, req):
        # Request doesn't provide a method for removing headers --
        # so overwrite the header instead.
        req.add_header("A-IM", "identity")
        return req

    https_request = http_request


class ResponseLogProcessor(urllib2.BaseHandler):
    """urllib2 handler that maintains a log of HTTP responses."""

    # Run after anything that's mangling headers (usually 500 or less), but
    # before HTTPErrorProcessor (1000).
    handler_order = 900

    def __init__(self):
        self.log = []

    def http_response(self, req, response):
        entry = {
            "url": req.get_full_url(),
            "status": response.getcode(),
            }
        location = response.info().get("Location")
        if location is not None:
            entry["location"] = location
        self.log.append(entry)
        return response

    https_response = http_response

    def get_log(self):
        return self.log


non_alphanumeric_re = re.compile(r'<[^>]*>|\&[^\;]*\;|[^a-z0-9]')


class Feed:
    """An RSS feed."""

    def __init__(self, url):
        self.url = url
        self.period = 30 * 60
        self.args = {}
        self.etag = None
        self.modified = None
        self.last_update = 0
        self.feed_info = {}

    def needs_update(self, now):
        """Return True if it's time to update this feed, or False if
        its update period has not yet elapsed."""
        return (now - self.last_update) >= self.period

    def get_state_filename(self):
        return "feeds/%s.state" % (short_hash(self.url),)

    def fetch(self, rawdog, config):
        """Fetch the current set of articles from the feed."""

        handlers = []

        logger = ResponseLogProcessor()
        handlers.append(logger)

        proxies = {}
        for name, value in self.args.items():
            if name.endswith("_proxy"):
                proxies[name[:-6]] = value
        if len(proxies) != 0:
            handlers.append(urllib2.ProxyHandler(proxies))

        if self.args.has_key("proxyuser") and self.args.has_key("proxypassword"):
            handlers.append(
    BasicAuthProcessor(
        self.args["proxyuser"],
        self.args["proxypassword"],
         proxy=True))

        if self.args.has_key("user") and self.args.has_key("password"):
            handlers.append(BasicAuthProcessor(self.args["user"], self.args["password"]))

        if self.get_keepmin(config) == 0 or config["currentonly"]:
            # If RFC 3229 and "A-IM: feed" is used, then there's
            # no way to tell when an article has been removed.
            # So if we only want to keep articles that are still
            # being published by the feed, we have to turn it off.
            handlers.append(DisableIMProcessor())

        call_hook("add_urllib2_handlers", rawdog, config, self, handlers)

        url = self.url
        # Turn plain filenames into file: URLs. (feedparser will open
        # plain filenames itself, but we want it to open the file with
        # urllib2 so we get a URLError if something goes wrong.)
        if not ":" in url:
            url = "file:" + url

        try:
            result = feedparser.parse(url,
                etag=self.etag,
                modified=self.modified,
                agent=HTTP_AGENT,
                handlers=handlers)
        except Exception, e:
            result = {
                "rawdog_exception": e,
                "rawdog_traceback": sys.exc_info()[2],
                }
        result["rawdog_responses"] = logger.get_log()
        return result

    def update(self, rawdog, now, config, articles, p):
        """Add new articles from a feed to the collection.
        Returns True if any articles were read, False otherwise."""

        # Note that feedparser might have thrown an exception --
        # so until we print the error message and return, we
        # can't assume that p contains any particular field.

        responses = p.get("rawdog_responses")
        if len(responses) > 0:
            last_status = responses[-1]["status"]
        elif len(p.get("feed", [])) != 0:
            # Some protocol other than HTTP -- assume it's OK,
            # since we got some content.
            last_status = 200
        else:
            # Timeout, or empty response from non-HTTP.
            last_status = 0

        version = p.get("version")
        if version is None:
            version = ""

        self.last_update = now

        errors = []
        fatal = False
        old_url = self.url

        if "rawdog_exception" in p:
            errors.append("Error fetching or parsing feed:")
            errors.append(str(p["rawdog_exception"]))
            if config["showtracebacks"]:
                from traceback import format_tb
                errors.append("".join(format_tb(p["rawdog_traceback"])))
            errors.append("")
            fatal = True

        if len(responses) != 0 and responses[0]["status"] == 301:
            # Permanent redirect(s). Find the new location.
            i = 0
            while i < len(responses) and responses[i]["status"] == 301:
                i += 1
            location = responses[i - 1].get("location")

            # According to RFC 2616, the Location header should be
            # an absolute URI. This doesn't stop the occasional
            # server sending something like "Location: /" or
            # "Location: //foo/bar". It's usually a sign of
            # brokenness, so fail rather than trying to interpret
            # it liberally.
            valid_uri = True
            if location is not None:
                parsed = urlparse.urlparse(location)
                if parsed.scheme == "" or parsed.netloc == "":
                    valid_uri = False

            if not valid_uri:
                errors.append("New URL:     " + location)
                errors.append(
                    "The feed returned a permanent redirect, but with an invalid new location.")
            elif location is None:
                errors.append("The feed returned a permanent redirect, but without a new location.")
            else:
                errors.append("New URL:     " + location)
                errors.append("The feed has moved permanently to a new URL.")
                if config["changeconfig"]:
                    rawdog.change_feed_url(self.url, location, config)
                    errors.append("The config file has been updated automatically.")
                else:
                    errors.append("You should update its entry in your config file.")
            errors.append("")

        bozo_exception = p.get("bozo_exception")
        got_urlerror = isinstance(bozo_exception, urllib2.URLError)
        got_timeout = isinstance(bozo_exception, socket.timeout)
        if got_urlerror or got_timeout:
            # urllib2 reported an error when fetching the feed.
            # Check to see if it was a timeout.
            if not (got_timeout or is_timeout_exception(bozo_exception)):
                errors.append("Error while fetching feed:")
                errors.append(str(bozo_exception))
                errors.append("")
                fatal = True
            elif config["ignoretimeouts"]:
                return False
            else:
                errors.append("Timeout while reading feed.")
                errors.append("")
                fatal = True
        elif last_status == 304:
            # The feed hasn't changed. Return False to indicate
            # that we shouldn't do expiry.
            return False
        elif last_status in [403, 410]:
            # The feed is disallowed or gone. The feed should be
            # unsubscribed.
            errors.append("The feed has gone.")
            errors.append("You should remove it from your config file.")
            errors.append("")
            fatal = True
        elif last_status / 100 != 2:
            # Some sort of client or server error. The feed may
            # need unsubscribing.
            errors.append("The feed returned an error.")
            errors.append("If this condition persists, you should remove it from your config file.")
            errors.append("")
            fatal = True
        elif version == "" and len(p.get("entries", [])) == 0:
            # feedparser couldn't detect the type of this feed or
            # retrieve any entries from it.
            errors.append("The data retrieved from this URL could not be understood as a feed.")
            errors.append("You should check whether the feed has changed URLs or been removed.")
            errors.append("")
            fatal = True

        old_error = "\n".join(errors)
        call_hook("feed_fetched", rawdog, config, self, p, old_error, not fatal)

        if len(errors) != 0:
            print >>sys.stderr, "Feed:        " + old_url
            if last_status != 0:
                print >>sys.stderr, "HTTP Status: " + str(last_status)
            for line in errors:
                print >>sys.stderr, line
            if fatal:
                return False

        # From here, we can assume that we've got a complete feedparser
        # response.

        p = ensure_unicode(p, p.get("encoding") or "UTF-8")

        # No entries means the feed hasn't changed, but for some reason
        # we didn't get a 304 response. Handle it the same way.
        if len(p["entries"]) == 0:
            return False

        self.etag = p.get("etag")
        self.modified = p.get("modified")

        self.feed_info = p["feed"]
        feed = self.url

        article_ids = {}
        if config["useids"]:
            # Find IDs for existing articles.
            for (hash, a) in articles.items():
                id = a.entry_info.get("id")
                if a.feed == feed and id is not None:
                    article_ids[id] = a

        seen_articles = set()
        sequence = 0
        for entry_info in p["entries"]:
            article = Article(feed, entry_info, now, sequence)
            ignore = Box(False)
            call_hook("article_seen", rawdog, config, article, ignore)
            if ignore.value:
                continue
            seen_articles.add(article.hash)
            sequence += 1

            id = entry_info.get("id")
            if id in article_ids:
                existing_article = article_ids[id]
            elif article.hash in articles:
                existing_article = articles[article.hash]
            else:
                existing_article = None

            if existing_article is not None:
                existing_article.update_from(article, now)
                call_hook("article_updated", rawdog, config, existing_article, now)
            else:
                articles[article.hash] = article
                call_hook("article_added", rawdog, config, article, now)

        if config["currentonly"]:
            for (hash, a) in articles.items():
                if a.feed == feed and hash not in seen_articles:
                    del articles[hash]

        return True

    def get_html_name(self, config):
        if self.feed_info.has_key("title_detail"):
            r = detail_to_html(self.feed_info["title_detail"], True, config)
        elif self.feed_info.has_key("link"):
            r = string_to_html(self.feed_info["link"], config)
        else:
            r = string_to_html(self.url, config)
        if r is None:
            r = ""
        return r

    def get_html_link(self, config):
        s = self.get_html_name(config)
        if self.feed_info.has_key("link"):
            return '<a href="' + string_to_html(self.feed_info["link"], config) + '">' + s + '</a>'
        else:
            return s

    def get_id(self, config):
        if self.args.has_key("id"):
            return self.args["id"]
        else:
            r = self.get_html_name(config).lower()
            return non_alphanumeric_re.sub('', r)

    def get_keepmin(self, config):
        return self.args.get("keepmin", config["keepmin"])


class Article:
    """An article retrieved from an RSS feed."""

    def __init__(self, feed, entry_info, now, sequence):
        self.feed = feed
        self.entry_info = entry_info
        self.sequence = sequence

        self.date = None
        parsed = entry_info.get("updated_parsed")
        if parsed is None:
            parsed = entry_info.get("published_parsed")
        if parsed is None:
            parsed = entry_info.get("created_parsed")
        if parsed is not None:
            try:
                self.date = calendar.timegm(parsed)
            except OverflowError:
                pass

        self.hash = self.compute_initial_hash()

        self.last_seen = now
        self.added = now

    def compute_initial_hash(self):
        """Compute an initial unique hash for an article.
        The generated hash must be unique amongst all articles in the
        system (i.e. it can't just be the article ID, because that
        would collide if more than one feed included the same
        article)."""
        h = hashlib.sha1()

        def add_hash(s):
            h.update(s.encode("UTF-8"))

        add_hash(self.feed)
        entry_info = self.entry_info
        if entry_info.has_key("title"):
            add_hash(entry_info["title"])
        if entry_info.has_key("link"):
            add_hash(entry_info["link"])
        if entry_info.has_key("content"):
            for content in entry_info["content"]:
                add_hash(content["value"])
        if entry_info.has_key("summary_detail"):
            add_hash(entry_info["summary_detail"]["value"])

        return h.hexdigest()

    def update_from(self, new_article, now):
        """Update this article's contents from a newer article that's
        been identified to be the same."""
        self.entry_info = new_article.entry_info
        self.sequence = new_article.sequence
        self.date = new_article.date
        self.last_seen = now

    def can_expire(self, now, config):
        return (now - self.last_seen) > config["expireage"]

    def get_sort_date(self, config):
        if config["sortbyfeeddate"]:
            return self.date or self.added
        else:
            return self.added


class DayWriter:
    """Utility class for writing day sections into a series of articles."""

    def __init__(self, file, config):
        self.lasttime = []
        self.file = file
        self.counter = 0
        self.config = config

    def start_day(self, tm):
        print >>self.file, '<div class="day">'
        day = safe_ftime(self.config["dayformat"], tm)
        print >>self.file, '<h2>' + day + '</h2>'
        self.counter += 1

    def start_time(self, tm):
        print >>self.file, '<div class="time">'
        clock = safe_ftime(self.config["timeformat"], tm)
        print >>self.file, '<h3>' + clock + '</h3>'
        self.counter += 1

    def time(self, s):
        try:
            tm = time.localtime(s)
        except ValueError:
            # e.g. "timestamp out of range for platform time_t"
            return
        if tm[:3] != self.lasttime[:3] and self.config["daysections"]:
            self.close(0)
            self.start_day(tm)
        if tm[:6] != self.lasttime[:6] and self.config["timesections"]:
            if self.config["daysections"]:
                self.close(1)
            else:
                self.close(0)
            self.start_time(tm)
        self.lasttime = tm

    def close(self, n=0):
        while self.counter > n:
            print >>self.file, "</div>"
            self.counter -= 1


def parse_time(value, default="m"):
    """Parse a time period with optional units (s, m, h, d, w) into a time
    in seconds. If no unit is specified, use minutes by default; specify
    the default argument to change this. Raises ValueError if the format
    isn't recognised."""
    units = {
        "s": 1,
        "m": 60,
        "h": 3600,
        "d": 86400,
        "w": 604800,
        }
    for unit, size in units.items():
        if value.endswith(unit):
            return int(value[:-len(unit)]) * size
    return int(value) * units[default]


def parse_bool(value):
    """Parse a boolean value (0, 1, false or true). Raise ValueError if
    the value isn't recognised."""
    value = value.strip().lower()
    if value == "0" or value == "false":
        return False
    elif value == "1" or value == "true":
        return True
    else:
        raise ValueError("Bad boolean value: " + value)


def parse_list(value):
    """Parse a list of keywords separated by whitespace."""
    return value.strip().split(None)


def parse_feed_args(argparams, arglines):
    """Parse a list of feed arguments. Raise ConfigError if the syntax is
    invalid, or ValueError if an argument value can't be parsed."""
    args = {}
    for p in argparams:
        ps = p.split("=", 1)
        if len(ps) != 2:
            raise ConfigError("Bad feed argument in config: " + p)
        args[ps[0]] = ps[1]
    for p in arglines:
        ps = p.split(None, 1)
        if len(ps) != 2:
            raise ConfigError("Bad argument line in config: " + p)
        args[ps[0]] = ps[1]
    for name, value in args.items():
        if name == "allowduplicates":
            args[name] = parse_bool(value)
        elif name == "keepmin":
            args[name] = int(value)
        elif name == "maxage":
            args[name] = parse_time(value)
    return args


class ConfigError(Exception):
    pass


class Config:
    """The aggregator's configuration."""

    def __init__(self, locking=True, logfile_name=None):
        self.locking = locking
        self.files_loaded = []
        self.loglock = threading.Lock()
        self.logfile = None
        if logfile_name:
            self.logfile = open(logfile_name, "a")
        self.reset()

    def reset(self):
        # Note that these default values are *not* the same as
        # in the supplied config file. The idea is that someone
        # who has an old config file shouldn't notice a difference
        # in behaviour on upgrade -- so new options generally
        # default to False here, and True in the sample file.
        self.config = {
            "feedslist": [],
            "feeddefaults": {},
            "defines": {},
            "outputfile": "output.html",
                        "oldpages": 5,
            "maxarticles": 200,
            "maxage": 0,
            "expireage": 24 * 60 * 60,
            "keepmin": 0,
            "dayformat": "%A, %d %B %Y",
            "timeformat": "%I:%M %p",
            "datetimeformat": None,
            "userefresh": False,
            "showfeeds": True,
            "timeout": 30,
            "pagetemplate": "default",
            "itemtemplate": "default",
            "feedlisttemplate": "default",
            "feeditemtemplate": "default",
            "verbose": False,
            "ignoretimeouts": False,
            "showtracebacks": False,
            "daysections": True,
            "timesections": True,
            "blocklevelhtml": True,
            "tidyhtml": False,
            "sortbyfeeddate": False,
            "currentonly": False,
            "hideduplicates": [],
            "newfeedperiod": "3h",
            "changeconfig": False,
            "numthreads": 1,
            "splitstate": False,
            "useids": False,
            }

    def __getitem__(self, key):
        return self.config[key]

    def get(self, key, default=None):
        return self.config.get(key, default)

    def __setitem__(self, key, value):
        self.config[key] = value

    def reload(self):
        self.log("Reloading config files")
        self.reset()
        for filename in self.files_loaded:
            self.load(filename, False)

    def load(self, filename, explicitly_loaded=True):
        """Load configuration from a config file."""
        if explicitly_loaded:
            self.files_loaded.append(filename)

        lines = []
        try:
            f = open(filename, "r")
            for line in f.xreadlines():
                try:
                    line = line.decode(get_system_encoding())
                except UnicodeDecodeError, e:
                    raise ConfigError(
    "Character encoding problem in config file: " +
    filename +
    ": " +
     str(e))

                stripped = line.strip()
                if stripped == "" or stripped[0] == "#":
                    continue
                if line[0] in string.whitespace:
                    if lines == []:
                        raise ConfigError("First line in config cannot be an argument")
                    lines[-1][1].append(stripped)
                else:
                    lines.append((stripped, []))
            f.close()
        except IOError:
            raise ConfigError("Can't read config file: " + filename)

        for line, arglines in lines:
            try:
                self.load_line(line, arglines)
            except ValueError:
                raise ConfigError("Bad value in config: " + line)

    def load_line(self, line, arglines):
        """Process a configuration directive."""

        l = line.split(None, 1)
        if len(l) == 1 and l[0] == "feeddefaults":
            l.append("")
        elif len(l) != 2:
            raise ConfigError("Bad line in config: " + line)

        # Load template files immediately, so we produce an error now
        # rather than later if anything goes wrong.
        if l[0].endswith("template") and l[1] != "default":
            load_file(l[1])

        handled_arglines = False
        if l[0] == "feed":
            l = l[1].split(None)
            if len(l) < 2:
                raise ConfigError("Bad line in config: " + line)
            self["feedslist"].append((l[1], parse_time(l[0]), parse_feed_args(l[2:], arglines)))
            handled_arglines = True
        elif l[0] == "feeddefaults":
            self["feeddefaults"] = parse_feed_args(l[1].split(None), arglines)
            handled_arglines = True
        elif l[0] == "define":
            l = l[1].split(None, 1)
            if len(l) != 2:
                raise ConfigError("Bad line in config: " + line)
            self["defines"][l[0]] = l[1]
        elif l[0] == "plugindirs":
            for dir in parse_list(l[1]):
                load_plugins(dir, self)
        elif l[0] == "outputfile":
            self["outputfile"] = l[1]
        elif l[0] == "oldpages":
            self["oldpages"] = l[1]
        elif l[0] == "maxarticles":
            self["maxarticles"] = int(l[1])
        elif l[0] == "maxage":
            self["maxage"] = parse_time(l[1])
        elif l[0] == "expireage":
            self["expireage"] = parse_time(l[1])
        elif l[0] == "keepmin":
            self["keepmin"] = int(l[1])
        elif l[0] == "dayformat":
            self["dayformat"] = l[1]
        elif l[0] == "timeformat":
            self["timeformat"] = l[1]
        elif l[0] == "datetimeformat":
            self["datetimeformat"] = l[1]
        elif l[0] == "userefresh":
            self["userefresh"] = parse_bool(l[1])
        elif l[0] == "showfeeds":
            self["showfeeds"] = parse_bool(l[1])
        elif l[0] == "timeout":
            self["timeout"] = parse_time(l[1], "s")
        elif l[0] in ("template", "pagetemplate"):
            self["pagetemplate"] = l[1]
        elif l[0] == "itemtemplate":
            self["itemtemplate"] = l[1]
        elif l[0] == "feedlisttemplate":
            self["feedlisttemplate"] = l[1]
        elif l[0] == "feeditemtemplate":
            self["feeditemtemplate"] = l[1]
        elif l[0] == "verbose":
            self["verbose"] = parse_bool(l[1])
        elif l[0] == "ignoretimeouts":
            self["ignoretimeouts"] = parse_bool(l[1])
        elif l[0] == "showtracebacks":
            self["showtracebacks"] = parse_bool(l[1])
        elif l[0] == "daysections":
            self["daysections"] = parse_bool(l[1])
        elif l[0] == "timesections":
            self["timesections"] = parse_bool(l[1])
        elif l[0] == "blocklevelhtml":
            self["blocklevelhtml"] = parse_bool(l[1])
        elif l[0] == "tidyhtml":
            self["tidyhtml"] = parse_bool(l[1])
        elif l[0] == "sortbyfeeddate":
            self["sortbyfeeddate"] = parse_bool(l[1])
        elif l[0] == "currentonly":
            self["currentonly"] = parse_bool(l[1])
        elif l[0] == "hideduplicates":
            self["hideduplicates"] = parse_list(l[1])
        elif l[0] == "newfeedperiod":
            self["newfeedperiod"] = l[1]
        elif l[0] == "changeconfig":
            self["changeconfig"] = parse_bool(l[1])
        elif l[0] == "numthreads":
            self["numthreads"] = int(l[1])
        elif l[0] == "splitstate":
            self["splitstate"] = parse_bool(l[1])
        elif l[0] == "useids":
            self["useids"] = parse_bool(l[1])
        elif l[0] == "include":
            self.load(l[1], False)
        elif call_hook("config_option_arglines", self, l[0], l[1], arglines):
            handled_arglines = True
        elif call_hook("config_option", self, l[0], l[1]):
            pass
        else:
            raise ConfigError("Unknown config command: " + l[0])

        if arglines != [] and not handled_arglines:
            raise ConfigError("Bad argument lines in config after: " + line)

    def log(self, *args):
        """Print a status message. If running in verbose mode, write
        the message to stderr; if using a logfile, write it to the
        logfile."""
        if self["verbose"]:
            with self.loglock:
                print >>sys.stderr, "".join(map(str, args))
        if self.logfile is not None:
            with self.loglock:
                print >>self.logfile, "".join(map(str, args))
                self.logfile.flush()

    def bug(self, *args):
        """Report detection of a bug in rawdog."""
        print >>sys.stderr, "Internal error detected in rawdog:"
        print >>sys.stderr, "".join(map(str, args))
        print >>sys.stderr, "This could be caused by a bug in rawdog itself or in a plugin."
        print >>sys.stderr, "Please send this error message and your config file to the rawdog author."


def edit_file(filename, editfunc):
    """Edit a file in place: for each line in the input file, call
    editfunc(line, outputfile), then rename the output file over the input
    file."""
    newname = "%s.new-%d" % (filename, os.getpid())
    oldfile = open(filename, "r")
    newfile = open(newname, "w")
    editfunc(oldfile, newfile)
    newfile.close()
    oldfile.close()
    os.rename(newname, filename)


class AddFeedEditor:
    def __init__(self, feedline):
        self.feedline = feedline

    def edit(self, inputfile, outputfile):
        d = inputfile.read()
        outputfile.write(d)
        if not d.endswith("\n"):
            outputfile.write("\n")
        outputfile.write(self.feedline)


def add_feed(filename, url, rawdog, config):
    """Try to add a feed to the config file."""
    feeds = rawdoglib.feedscanner.feeds(url)
    if feeds == []:
        print >>sys.stderr, "Cannot find any feeds in " + url
        return

    feed = feeds[0]
    if feed in rawdog.feeds:
        print >>sys.stderr, "Feed " + feed + " is already in the config file"
        return

    print >>sys.stderr, "Adding feed " + feed
    feedline = "feed %s %s\n" % (config["newfeedperiod"], feed)
    edit_file(filename, AddFeedEditor(feedline).edit)


class ChangeFeedEditor:
    def __init__(self, oldurl, newurl):
        self.oldurl = oldurl
        self.newurl = newurl

    def edit(self, inputfile, outputfile):
        for line in inputfile.xreadlines():
            ls = line.strip().split(None)
            if len(ls) > 2 and ls[0] == "feed" and ls[2] == self.oldurl:
                line = line.replace(self.oldurl, self.newurl, 1)
            outputfile.write(line)


class RemoveFeedEditor:
    def __init__(self, url):
        self.url = url

    def edit(self, inputfile, outputfile):
        while True:
            l = inputfile.readline()
            if l == "":
                break
            ls = l.strip().split(None)
            if len(ls) > 2 and ls[0] == "feed" and ls[2] == self.url:
                while True:
                    l = inputfile.readline()
                    if l == "":
                        break
                    elif l[0] == "#":
                        outputfile.write(l)
                    elif l[0] not in string.whitespace:
                        outputfile.write(l)
                        break
            else:
                outputfile.write(l)


def remove_feed(filename, url, config):
    """Try to remove a feed from the config file."""
    if url not in [f[0] for f in config["feedslist"]]:
        print >>sys.stderr, "Feed " + url + " is not in the config file"
    else:
        print >>sys.stderr, "Removing feed " + url
        edit_file(filename, RemoveFeedEditor(url).edit)


class FeedFetcher:
    """Class that will handle fetching a set of feeds in parallel."""

    def __init__(self, rawdog, feedlist, config):
        self.rawdog = rawdog
        self.config = config
        self.lock = threading.Lock()
        self.jobs = set(feedlist)
        self.results = {}

    def worker(self, num):
        rawdog = self.rawdog
        config = self.config

        while True:
            with self.lock:
                try:
                    job = self.jobs.pop()
                except KeyError:
                    # No jobs left.
                    break

            config.log("[", num, "] Fetching feed: ", job)
            feed = rawdog.feeds[job]
            call_hook("pre_update_feed", rawdog, config, feed)
            result = feed.fetch(rawdog, config)

            with self.lock:
                self.results[job] = result

    def run(self, max_workers):
        max_workers = max(max_workers, 1)
        num_workers = min(max_workers, len(self.jobs))

        self.config.log("Fetching ", len(self.jobs), " feeds using ",
                        num_workers, " threads")
        workers = []
        for i in range(1, num_workers):
            t = threading.Thread(target=self.worker, args=(i,))
            t.start()
            workers.append(t)
        self.worker(0)
        for worker in workers:
            worker.join()
        self.config.log("Fetch complete")
        return self.results


class FeedState(Persistable):
    """The collection of articles in a feed."""

    def __init__(self):
        Persistable.__init__(self)
        self.articles = {}


class Rawdog(Persistable):
    """The aggregator itself."""

    def __init__(self):
        Persistable.__init__(self)
        self.feeds = {}
        self.articles = {}
        self.plugin_storage = {}
        self.state_version = STATE_VERSION
        self.using_splitstate = None

    def get_plugin_storage(self, plugin):
        try:
            st = self.plugin_storage.setdefault(plugin, {})
        except AttributeError:
            # rawdog before 2.5 didn't have plugin storage.
            st = {}
            self.plugin_storage = {plugin: st}
        return st

    def check_state_version(self):
        """Check the version of the state file."""
        try:
            version = self.state_version
        except AttributeError:
            # rawdog 1.x didn't keep track of this.
            version = 1
        return version == STATE_VERSION

    def change_feed_url(self, oldurl, newurl, config):
        """Change the URL of a feed."""

        assert self.feeds.has_key(oldurl)
        if self.feeds.has_key(newurl):
            print >>sys.stderr, "Error: New feed URL is already subscribed; please remove the old one"
            print >>sys.stderr, "from the config file by hand."
            return

        edit_file("config", ChangeFeedEditor(oldurl, newurl).edit)

        feed = self.feeds[oldurl]
        # Changing the URL will change the state filename as well,
        # so we need to save the old name to load from.
        old_state = feed.get_state_filename()
        feed.url = newurl
        del self.feeds[oldurl]
        self.feeds[newurl] = feed

        if config["splitstate"]:
            feedstate_p = persister.get(FeedState, old_state)
            feedstate_p.rename(feed.get_state_filename())
            with feedstate_p as feedstate:
                for article in feedstate.articles.values():
                    article.feed = newurl
                feedstate.modified()
        else:
            for article in self.articles.values():
                if article.feed == oldurl:
                    article.feed = newurl

        print >>sys.stderr, "Feed URL automatically changed."

    def list(self, config):
        """List the configured feeds."""
        for url, feed in self.feeds.items():
            feed_info = feed.feed_info
            print url
            print "  ID:", feed.get_id(config)
            print "  Hash:", short_hash(url)
            print "  Title:", feed.get_html_name(config)
            print "  Link:", feed_info.get("link")

    def sync_from_config(self, config):
        """Update rawdog's internal state to match the
        configuration."""

        # Make sure the splitstate directory exists.
        if config["splitstate"]:
            try:
                os.mkdir("feeds")
            except OSError:
                # Most likely it already exists.
                pass

        # Convert to or from splitstate if necessary.
        try:
            u = self.using_splitstate
        except AttributeError:
            # We were last run with a version of rawdog that didn't
            # have this variable -- so we must have a single state
            # file.
            u = False
        if u is None:
            self.using_splitstate = config["splitstate"]
        elif u != config["splitstate"]:
            if config["splitstate"]:
                config.log("Converting to split state files")
                for feed_hash, feed in self.feeds.items():
                    with persister.get(FeedState, feed.get_state_filename()) as feedstate:
                        feedstate.articles = {}
                        for article_hash, article in self.articles.items():
                            if article.feed == feed_hash:
                                feedstate.articles[article_hash] = article
                        feedstate.modified()
                self.articles = {}
            else:
                config.log("Converting to single state file")
                self.articles = {}
                for feed_hash, feed in self.feeds.items():
                    with persister.get(FeedState, feed.get_state_filename()) as feedstate:
                        for article_hash, article in feedstate.articles.items():
                            self.articles[article_hash] = article
                        feedstate.articles = {}
                        feedstate.modified()
                    persister.delete(feed.get_state_filename())
            self.modified()
            self.using_splitstate = config["splitstate"]

        seen_feeds = set()
        for (url, period, args) in config["feedslist"]:
            seen_feeds.add(url)
            if not self.feeds.has_key(url):
                config.log("Adding new feed: ", url)
                self.feeds[url] = Feed(url)
                self.modified()
            feed = self.feeds[url]
            if feed.period != period:
                config.log("Changed feed period: ", url)
                feed.period = period
                self.modified()
            newargs = {}
            newargs.update(config["feeddefaults"])
            newargs.update(args)
            if feed.args != newargs:
                config.log("Changed feed options: ", url)
                feed.args = newargs
                self.modified()
        for url in self.feeds.keys():
            if url not in seen_feeds:
                config.log("Removing feed: ", url)
                if config["splitstate"]:
                    persister.delete(self.feeds[url].get_state_filename())
                else:
                    for key, article in self.articles.items():
                        if article.feed == url:
                            del self.articles[key]
                del self.feeds[url]
                self.modified()

    def update(self, config, feedurl=None):
        """Perform the update action: check feeds for new articles, and
        expire old ones."""
        config.log("Starting update")
        now = time.time()

        socket.setdefaulttimeout(config["timeout"])

        if feedurl is None:
            update_feeds = [url for url in self.feeds.keys()
                                if self.feeds[url].needs_update(now)]
        elif self.feeds.has_key(feedurl):
            update_feeds = [feedurl]
            self.feeds[feedurl].etag = None
            self.feeds[feedurl].modified = None
        else:
            print "No such feed: " + feedurl
            update_feeds = []

        numfeeds = len(update_feeds)
        config.log("Will update ", numfeeds, " feeds")

        fetcher = FeedFetcher(self, update_feeds, config)
        fetched = fetcher.run(config["numthreads"])

        seen_some_items = set()

        def do_expiry(articles):
            """Expire articles from a list. Return True if any
            articles were expired."""

            feedcounts = {}
            for key, article in articles.items():
                url = article.feed
                feedcounts[url] = feedcounts.get(url, 0) + 1

            expiry_list = []
            feedcounts = {}
            for key, article in articles.items():
                url = article.feed
                feedcounts[url] = feedcounts.get(url, 0) + 1
                expiry_list.append((article.added, article.sequence, key, article))
            expiry_list.sort()

            count = 0
            for date, seq, key, article in expiry_list:
                url = article.feed
                if url not in self.feeds:
                    config.log("Expired article for nonexistent feed: ", url)
                    count += 1
                    del articles[key]
                    continue
                if (url in seen_some_items
                    and self.feeds.has_key(url)
                    and article.can_expire(now, config)
                    and feedcounts[url] > self.feeds[url].get_keepmin(config)):
                    call_hook("article_expired", self, config, article, now)
                    count += 1
                    feedcounts[url] -= 1
                    del articles[key]
            config.log("Expired ", count, " articles, leaving ", len(articles))

            return count > 0

        count = 0
        for url in update_feeds:
            count += 1
            config.log("Updating feed ", count, " of ", numfeeds, ": ", url)
            feed = self.feeds[url]

            if config["splitstate"]:
                feedstate_p = persister.get(FeedState, feed.get_state_filename())
                feedstate = feedstate_p.open()
                articles = feedstate.articles
            else:
                articles = self.articles

            content = fetched[url]
            call_hook("mid_update_feed", self, config, feed, content)
            rc = feed.update(self, now, config, articles, content)
            url = feed.url
            call_hook("post_update_feed", self, config, feed, rc)
            if rc:
                seen_some_items.add(url)
                if config["splitstate"]:
                    feedstate.modified()

            if config["splitstate"]:
                if do_expiry(articles):
                    feedstate.modified()
                feedstate_p.close()

        if config["splitstate"]:
            self.articles = {}
        else:
            do_expiry(self.articles)

        self.modified()
        config.log("Finished update")

    def get_template(self, config, name="page"):
        """Return the contents of a template."""

        filename = config.get(name + "template", "default")
        if filename != "default":
            return load_file(filename)

        if name == "page":
            template = """<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
    <meta name="robots" content="noindex,nofollow,noarchive">
"""
            if config["userefresh"]:
                template += """__refresh__
"""
            template += """    <link rel="stylesheet" href="style.css" type="text/css">
    <title>rawdog</title>
</head>
<body id="rawdog">
<div id="header">
<h1>rawdog</h1>
</div>
<div id="items">
__items__
</div>
"""
            if config["showfeeds"]:
                template += """<h2 id="feedstatsheader">Feeds</h2>
<div id="feedstats">
__feeds__
</div>
"""
            template += """<div id="footer">
<p id="aboutrawdog">Generated by
<a href="http://offog.org/code/rawdog.html">rawdog</a>
version __version__
by <a href="mailto:ats@offog.org">Adam Sampson</a>.</p>
</div>
</body>
</html>
"""
            return template
        elif name == "item":
            return """<div class="item feed-__feed_hash__ feed-__feed_id__" id="item-__hash__">
<p class="itemheader">
<span class="itemtitle">__title__</span>
<span class="itemfrom">[__feed_title__]</span>
</p>
__if_description__<div class="itemdescription">
__description__
</div>__endif__
</div>

"""
        elif name == "feedlist":
            return """<table id="feeds">
<tr id="feedsheader">
<th>Feed</th><th>RSS</th><th>Last fetched</th><th>Next fetched after</th>
</tr>
__feeditems__
</table>
"""
        elif name == "feeditem":
            return """
<tr class="feedsrow">
<td>__feed_title__</td>
<td>__feed_icon__</td>
<td>__feed_last_update__</td>
<td>__feed_next_update__</td>
</tr>
"""
        else:
            raise KeyError("Unknown template name: " + name)

    def show_template(self, name, config):
        """Show the contents of a template, as currently configured."""
        try:
            print self.get_template(config, name),
        except KeyError:
            print >>sys.stderr, "Unknown template name: " + name

    def write_article(self, f, article, config):
        """Write an article to the given file."""
        feed = self.feeds[article.feed]
        entry_info = article.entry_info

        link = entry_info.get("link")
        if link == "":
            link = None

        guid = entry_info.get("id")
        if guid == "":
            guid = None

        itembits = self.get_feed_bits(config, feed)
        for name, value in feed.args.items():
            if name.startswith("define_"):
                itembits[name[7:]] = sanitise_html(value, "", True, config)

        title = detail_to_html(entry_info.get("title_detail"), True, config)

        key = None
        for k in ["content", "summary_detail"]:
            if entry_info.has_key(k):
                key = k
                break
        if key is None:
            description = None
        else:
            force_preformatted = (feed.args.get("format", "default") == "text")
            description = detail_to_html(entry_info[key], False, config, force_preformatted)

        date = article.date
        if title is None:
            if link is None:
                title = "Article"
            else:
                title = "Link"

        itembits["title_no_link"] = title
        if link is not None:
            itembits["url"] = string_to_html(link, config)
        else:
            itembits["url"] = ""
        if guid is not None:
            itembits["guid"] = string_to_html(guid, config)
        else:
            itembits["guid"] = ""
        if link is None:
            itembits["title"] = title
        else:
            itembits["title"] = '<a href="' + string_to_html(link, config) + '">' + title + '</a>'

        itembits["hash"] = short_hash(article.hash)

        if description is not None:
            itembits["description"] = description
        else:
            itembits["description"] = ""

        author = author_to_html(entry_info, feed.url, config)
        if author is not None:
            itembits["author"] = author
        else:
            itembits["author"] = ""

        itembits["added"] = format_time(article.added, config)
        if date is not None:
            itembits["date"] = format_time(date, config)
        else:
            itembits["date"] = ""

        call_hook("output_item_bits", self, config, feed, article, itembits)
        itemtemplate = self.get_template(config, "item")
        f.write(fill_template(itemtemplate, itembits))

    def write_remove_dups(self, articles, config, now):
        """Filter the list of articles to remove articles that are too
        old or are duplicates."""
        kept_articles = []
        seen_links = set()
        seen_guids = set()
        dup_count = 0
        for article in articles:
            feed = self.feeds[article.feed]
            age = now - article.added

            maxage = feed.args.get("maxage", config["maxage"])
            if maxage != 0 and age > maxage:
                continue

            entry_info = article.entry_info

            link = entry_info.get("link")
            if link == "":
                link = None

            guid = entry_info.get("id")
            if guid == "":
                guid = None

            if not feed.args.get("allowduplicates", False):
                is_dup = False
                for key in config["hideduplicates"]:
                    if key == "id" and guid is not None:
                        if guid in seen_guids:
                            is_dup = True
                        seen_guids.add(guid)
                    elif key == "link" and link is not None:
                        if link in seen_links:
                            is_dup = True
                        seen_links.add(link)
                if is_dup:
                    dup_count += 1
                    continue

            kept_articles.append(article)
        return (kept_articles, dup_count)

    def get_feed_bits(self, config, feed):
        """Get the bits that are used to describe a feed."""

        bits = {}
        bits["feed_id"] = feed.get_id(config)
        bits["feed_hash"] = short_hash(feed.url)
        bits["feed_title"] = feed.get_html_link(config)
        bits["feed_title_no_link"] = detail_to_html(
    feed.feed_info.get("title_detail"), True, config)
        bits["feed_url"] = string_to_html(feed.url, config)
        bits["feed_icon"] = '<a class="xmlbutton" href="' + cgi.escape(feed.url) + '">XML</a>'
        bits["feed_last_update"] = format_time(feed.last_update, config)
        bits["feed_next_update"] = format_time(feed.last_update + feed.period, config)
        return bits

    def write_feeditem(self, f, feed, config):
        """Write a feed list item."""
        bits = self.get_feed_bits(config, feed)
        f.write(fill_template(self.get_template(config, "feeditem"), bits))

    def write_feedlist(self, f, config):
        """Write the feed list."""
        bits = {}

        feeds = [(feed.get_html_name(config).lower(), feed)
                 for feed in self.feeds.values()]
        feeds.sort()

        feeditems = StringIO()
        for key, feed in feeds:
            self.write_feeditem(feeditems, feed, config)
        bits["feeditems"] = feeditems.getvalue()
        feeditems.close()

        f.write(fill_template(self.get_template(config, "feedlist"), bits))

    def get_main_template_bits(self, config):
        """Get the bits that are used in the default main template,
        with the exception of items and num_items."""
        bits = {"version": VERSION}
        bits.update(config["defines"])

        refresh = min([config["expireage"]]
                      + [feed.period for feed in self.feeds.values()])
        bits["refresh"] = '<meta http-equiv="Refresh" content="' + str(refresh) + '">'

        f = StringIO()
        self.write_feedlist(f, config)
        bits["feeds"] = f.getvalue()
        f.close()
        bits["num_feeds"] = str(len(self.feeds))

        return bits

    def write_output_file(self, articles, article_dates, config, oldpage=0):
        """Write a regular rawdog HTML output file."""
        f = StringIO()
        dw = DayWriter(f, config)
        call_hook("output_items_begin", self, config, f)

        for article in articles:
            if not call_hook(
    "output_items_heading",
    self,
    config,
    f,
    article,
     article_dates[article]):
                dw.time(article_dates[article])

            self.write_article(f, article, config)

        dw.close()
        call_hook("output_items_end", self, config, f)

        if oldpage != config["oldpages"]:
                       filename = config["outputfile"].split("/")[-1:][0]  # get the filename only
                       filename = filename.split(".html")
               outputfile = filename[0] + str(oldpage+1) + ".html"
               f.write('<p><a class="btn btn-mat" href="'+outputfile+'">Older blog entries</a></p>')

        bits = self.get_main_template_bits(config)
        bits["items"] = f.getvalue()
        f.close()
        bits["num_items"] = str(len(articles))
        call_hook("output_bits", self, config, bits)
        s = fill_template(self.get_template(config, "page"), bits)
        if oldpage > 0:
            filename = config["outputfile"].split(".html")
            outputfile = filename[0] + str(oldpage) + ".html"
        else:
            outputfile = config["outputfile"]
        if outputfile == "-":
            write_ascii(sys.stdout, s, config)
        else:
            config.log("Writing output file: ", outputfile)
            f = open(outputfile + ".new", "w")
            write_ascii(f, s, config)
            f.close()
            os.rename(outputfile + ".new", outputfile)

    def write(self, config):
        """Perform the write action: write articles to the output
        file."""
        config.log("Starting write")
        now = time.time()

        def list_articles(articles):
            return [(-a.get_sort_date(config), a.feed, a.sequence, a.hash) for a in articles.values()]
        if config["splitstate"]:
            article_list = []
            for feed in self.feeds.values():
                with persister.get(FeedState, feed.get_state_filename()) as feedstate:
                    article_list += list_articles(feedstate.articles)
        else:
            article_list = list_articles(self.articles)
        numarticles = len(article_list)

        if not call_hook("output_sort_articles", self, config, article_list):
            article_list.sort()

                # for multiple pages split further down
        # if config["maxarticles"] != 0:
        #   article_list = article_list[:config["maxarticles"]]

        if config["splitstate"]:
            wanted = {}
            for (date, feed_url, seq, hash) in article_list:
                if not feed_url in self.feeds:
                    # This can happen if you've managed to
                    # kill rawdog between it updating a
                    # split state file and the main state
                    # -- so just ignore the article and
                    # it'll expire eventually.
                    continue
                wanted.setdefault(feed_url, []).append(hash)

            found = {}
            for (feed_url, article_hashes) in wanted.items():
                feed = self.feeds[feed_url]
                with persister.get(FeedState, feed.get_state_filename()) as feedstate:
                    for hash in article_hashes:
                        found[hash] = feedstate.articles[hash]
        else:
            found = self.articles

        articles = []
        article_dates = {}
        for (date, feed, seq, hash) in article_list:
            a = found.get(hash)
            if a is not None:
                articles.append(a)
                article_dates[a] = -date

        call_hook("output_write", self, config, articles)

        if not call_hook("output_sorted_filter", self, config, articles):
            (articles, dup_count) = self.write_remove_dups(articles, config, now)
        else:
            dup_count = 0

        config.log("Selected ", len(articles), " of ", numarticles, " articles to write; ignored ", dup_count, " duplicates")

        for page in range(0, config["oldpages"]+1):
            print "on page: " + str(page)
            if config["maxarticles"] != 0:
                pageArticles = articles[config["maxarticles"]*page:config["maxarticles"]*(page+1)]

            if not call_hook("output_write_files", self, config, pageArticles, article_dates):
                self.write_output_file(pageArticles, article_dates, config, page)

        config.log("Finished write")

def usage():
    """Display usage information."""
    print """rawdog, version """ + VERSION + """
Usage: rawdog [OPTION]...

General options (use only once):
-d|--dir DIR                 Use DIR instead of ~/.rawdog
-N, --no-locking             Do not lock the state file
-v, --verbose                Print more detailed status information
-V|--log FILE                Append detailed status information to FILE
-W, --no-lock-wait           Exit silently if state file is locked

Actions (performed in order given):
-a|--add URL                 Try to find a feed associated with URL and
                             add it to the config file
-c|--config FILE             Read additional config file FILE
-f|--update-feed URL         Force an update on the single feed URL
-l, --list                   List feeds known at time of last update
-r|--remove URL              Remove feed URL from the config file
-s|--show TEMPLATE           Show the contents of a template
                             (TEMPLATE may be: page item feedlist feeditem)
-u, --update                 Fetch data from feeds and store it
-w, --write                  Write out HTML output

Special actions (all other options are ignored if one of these is specified):
--dump URL                   Show what rawdog's parser returns for URL
--help                       Display this help and exit

Report bugs to <ats@offog.org>."""

def main(argv):
    """The command-line interface to the aggregator."""

    locale.setlocale(locale.LC_ALL, "")

    # This is quite expensive and not threadsafe, so we do it on
    # startup and cache the result.
    global system_encoding
    system_encoding = locale.getpreferredencoding()

    try:
        SHORTOPTS = "a:c:d:f:lNr:s:tTuvV:wW"
        LONGOPTS = [
            "add=",
            "config=",
            "dir=",
            "dump=",
            "help",
            "list",
            "log=",
            "no-lock-wait",
            "no-locking",
            "remove=",
            "show=",
            "show-itemtemplate",
            "show-template",
            "update",
            "update-feed=",
            "verbose",
            "write",
            ]
        (optlist, args) = getopt.getopt(argv, SHORTOPTS, LONGOPTS)
    except getopt.GetoptError, s:
        print s
        usage()
        return 1

    if len(args) != 0:
        usage()
        return 1

    if "HOME" in os.environ:
        statedir = os.environ["HOME"] + "/.rawdog"
    else:
        statedir = None
    verbose = False
    logfile_name = None
    locking = True
    no_lock_wait = False
    for o, a in optlist:
        if o == "--dump":
            import pprint
            pprint.pprint(feedparser.parse(a, agent=HTTP_AGENT))
            return 0
        elif o == "--help":
            usage()
            return 0
        elif o in ("-d", "--dir"):
            statedir = a
        elif o in ("-N", "--no-locking"):
            locking = False
        elif o in ("-v", "--verbose"):
            verbose = True
        elif o in ("-V", "--log"):
            logfile_name = a
        elif o in ("-W", "--no-lock-wait"):
            no_lock_wait = True
    if statedir is None:
        print "$HOME not set and state dir not explicitly specified; please use -d/--dir"
        return 1

    try:
        os.chdir(statedir)
    except OSError:
        print "No " + statedir + " directory"
        return 1

    sys.path.append(".")

    config = Config(locking, logfile_name)
    def load_config(fn):
        try:
            config.load(fn)
        except ConfigError, err:
            print >>sys.stderr, "In " + fn + ":"
            print >>sys.stderr, err
            return 1
        if verbose:
            config["verbose"] = True
        return 0
    rc = load_config("config")
    if rc != 0:
        return rc

    global persister
    persister = Persister(config)

    rawdog_p = persister.get(Rawdog, "state")
    rawdog = rawdog_p.open(no_block=no_lock_wait)
    if rawdog is None:
        return 0
    if not rawdog.check_state_version():
        print "The state file " + statedir + "/state was created by an older"
        print "version of rawdog, and cannot be read by this version."
        print "Removing the state file will fix it."
        return 1

    rawdog.sync_from_config(config)

    call_hook("startup", rawdog, config)

    for o, a in optlist:
        if o in ("-a", "--add"):
            add_feed("config", a, rawdog, config)
            config.reload()
            rawdog.sync_from_config(config)
        elif o in ("-c", "--config"):
            rc = load_config(a)
            if rc != 0:
                return rc
            rawdog.sync_from_config(config)
        elif o in ("-f", "--update-feed"):
            rawdog.update(config, a)
        elif o in ("-l", "--list"):
            rawdog.list(config)
        elif o in ("-r", "--remove"):
            remove_feed("config", a, config)
            config.reload()
            rawdog.sync_from_config(config)
        elif o in ("-s", "--show"):
            rawdog.show_template(a, config)
        elif o in ("-t", "--show-template"):
            rawdog.show_template("page", config)
        elif o in ("-T", "--show-itemtemplate"):
            rawdog.show_template("item", config)
        elif o in ("-u", "--update"):
            rawdog.update(config)
        elif o in ("-w", "--write"):
            rawdog.write(config)

    call_hook("shutdown", rawdog, config)

    rawdog_p.close()

    return 0
