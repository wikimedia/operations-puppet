#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
2015 Chase Pettet

HTML that needs to exist per T108081/T119456

This is meant to ensure certain legal required
content is present.

In the absence of rendering I am doing
basic html validation here as it should suffice.
"""

import argparse
import re
import sys
import urllib2


mobile_copyright = 'Content\sis\savailable\sunder \
<a\sclass=\"external\"\srel=\"nofollow\" \
href="\/\/creativecommons.org/licenses/by-sa/3\.0/">\
CC\sBY-SA\s3\.0</a>\sunless\sotherwise\snoted\.'

mobile_terms = '<a\shref="\/\/m\.wikimediafoundation\.org\/wiki\/Terms_of_Use">\
Terms\sof\sUse</a>'

mobile_privacy = '<a\shref="\/\/wikimediafoundation\.org\/wiki\/Privacy_policy"\sclass=\"\S+"\s\
title="wmf:Privacy\spolicy">Privacy</a>'

copyright = 'Text\sis\savailable\sunder\sthe\s<a\srel="license"\s+\
href="\/\/en.wikipedia.org\/wiki\/Wikipedia:\
Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License">\
Creative\sCommons\sAttribution-ShareAlike\sLicense</a>\
<a\srel="license"\shref="\/\/creativecommons.org\/licenses\/by-sa\/3\.0/"'

terms = 'additional\sterms\smay\sapply\.  \
By\susing\sthis\ssite,\syou\sagree\sto\sthe \
<a\shref="\/\/wikimediafoundation.org\/wiki\/Terms_of_Use">Terms\sof\sUse</a>'

privacy = '<a\shref="//wikimediafoundation.org/wiki/Privacy_policy">\
Privacy\spolicy</a>'

enwb_privacy = '<a\shref="\/\/wikimediafoundation\.org\/wiki\/Privacy_policy">\
Privacy\sPolicy\.<\/a>'

enwp_trademark = 'Wikipedia®\sis\sa\sregistered\strademark \
of\sthe\s<a\shref="\/\/www\.wikimediafoundation\.org/">\
Wikimedia\sFoundation,\sInc\.</a>,\sa\snon-profit\sorganization\.'

enwb_copyright = 'Text\sis\savailable\sunder\sthe \
<a\shref="\/\/creativecommons\.org\/licenses\/by-sa\/3\.0\/">\
Creative\sCommons\sAttribution-ShareAlike\sLicense.</a>; \
additional\sterms\smay\sapply\.'


def log(msg, enabled):
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
            enwb_privacy,
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

    site = args.site
    verbose = args.verbose
    ensures = ensure.get(args.ensure, [])
    if not ensures:
        print "no html ensure list"
        sys.exit(3)

    log(site, verbose)
    html = site_html(site)
    for match in ensures:
        log(match, verbose)
        count = len(re.findall(match, html, re.IGNORECASE))
        log(count, verbose)
        if not count:
            print "%s html not found" % (match,)
            sys.exit(2)

    print "all html is present."

if __name__ == '__main__':
    main()
