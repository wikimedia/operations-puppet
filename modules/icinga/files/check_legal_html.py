#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
2015 Chase Pettet

HTML that needs to exist per T108081

This is meant to ensure certain legal required
content is present.

In the absence of rendering I am doing
basic html validation here as it should suffice.
"""

import argparse
import re
import sys
import urllib2


mobile_copyright = 'Content is available under \
<a class="external" rel="nofollow" \
href="//creativecommons.org/licenses/by-sa/3.0/">\
CC BY-SA 3.0</a> unless otherwise noted.'

mobile_terms = '<a href="//m.wikimediafoundation.org/wiki/Terms_of_Use">\
Terms of Use</a>'

mobile_privacy = '<a href="//wikimediafoundation.org/wiki/Privacy_policy">\
Privacy</a>'

copyright = 'Text\sis available under the <a\s+rel="license"\s+\
href="//en.wikipedia.org/wiki/Wikipedia:\
Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License">\
Creative Commons Attribution-ShareAlike License</a>\
<a rel="license" href="//creativecommons.org/licenses/by-sa/3.0/"'

terms = 'additional terms may apply.  \
By using this site, you agree to the \
<a href="//wikimediafoundation.org/wiki/Terms_of_Use">Terms of Use</a>'

privacy = '<a href="//wikimediafoundation.org/wiki/Privacy_policy">\
Privacy policy</a>'

enwp_trademark = 'Wikipedia® is a registered trademark \
of the <a href="//www.wikimediafoundation.org/">\
Wikimedia Foundation, Inc.</a>, a non-profit organization.'

enwb_copyright = 'Text is available under the \
<a href="//creativecommons.org/licenses/by-sa/3.0/">\
Creative Commons Attribution-ShareAlike License.</a>; \
additional terms may apply.'


def logger(msg, enabled):
    if enabled:
        print msg


def site_html(url):
    html_content = urllib2.urlopen(url).readlines()
    return '\n'.join(html_content)


def main():

    ensure = {
        'desktop_enwb': [
            enwb_copyright,
            terms,
            privacy,
        ],
        'desktop_enwp': [
            copyright,
            terms,
            privacy,
            enwp_trademark,
        ],
        'mobile': [
            mobile_copyright,
            mobile_terms,
            mobile_privacy,
        ],
    }

    ap = argparse.ArgumentParser(description='Valid certain legal HTML exists')
    ap.add_argument('-site', default='localhost')
    ap.add_argument('-ensure', type=str)
    ap.add_argument('-v', dest='verbose', action='store_true')
    ap.set_defaults(verbose=False)
    args = ap.parse_args()

    log = lambda m: logger(m, args.verbose)
    site = args.site
    ensures = ensure.get(args.ensure, [])
    if not ensures:
        print "no html ensure list"
        sys.exit(3)

    log(site)
    html = site_html(site)
    for match in ensures:
        log(match)
        count = len(re.findall(match, html))
        log(count)
        if not count:
            print "%s html not found" % (match,)
            sys.exit(2)

    print "all html is present."

if __name__ == '__main__':
    main()
