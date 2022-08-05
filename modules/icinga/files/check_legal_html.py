#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
2015 Chase Pettet

HTML that needs to exist per T108081/T119456

This is meant to ensure certain legal required
content is present.  Content assurance is
case INSENSITIVE.

In the absence of rendering I am doing
basic html validation here as it should suffice.
"""

import argparse
import re
import sys
import urllib.request


mobile_copyright = (r'Content\sis\savailable\sunder '
                    r'<a\sclass=\"external\"\srel=\"nofollow\" '
                    r'href="(https:)?\/\/creativecommons.org/licenses/by-sa/3\.0/">'
                    r'CC\sBY-SA\s3\.0</a>\sunless\sotherwise\snoted\.')

mobile_terms = (r'<a\shref="(https:)?\/\/m\.wikimediafoundation\.org\/wiki\/Terms_of_Use">'
                r'Terms\sof\sUse</a>')

mobile_privacy = (r'<a\shref="(https:)?\/\/foundation\.wikimedia\.org\/wiki\/Privacy_policy">'
                  r'Privacy\spolicy</a>')

copyright = (r'Text\sis\savailable\sunder\sthe\s<a\srel="license"\s+'
             r'href="(https:)?\/\/en.wikipedia.org\/wiki\/Wikipedia:'
             r'Text_of_Creative_Commons_Attribution-ShareAlike_3.0_Unported_License">'
             r'Creative\sCommons\sAttribution-ShareAlike\sLicense 3.0</a>'
             r'<a\srel="license"\shref="\/\/creativecommons.org\/licenses\/by-sa\/3\.0/"')

terms = (r'additional\sterms\smay\sapply\.  '
         r'By\susing\sthis\ssite,\syou\sagree\sto\sthe '
         r'<a\shref="(https:)?\/\/foundation\.wikimedia\.org\/wiki\/Terms_of_Use">Terms\sof'
         r'\sUse</a>')

privacy = (r'<a\shref="(https:)?\/\/foundation\.wikimedia\.org/wiki/Privacy_policy">'
           r'Privacy\spolicy</a>')

enwb_privacy = (r'<a\shref="(https:)?\/\/foundation\.wikimedia\.org\/wiki\/Privacy_policy">'
                r'Privacy\sPolicy\.<\/a>')

enwp_trademark = (r'Wikipedia®\sis\sa\sregistered\strademark '
                  r'of\sthe\s<a\shref="\/\/(www\.)?wikimediafoundation\.org/">'
                  r'Wikimedia\sFoundation,\sInc\.</a>,\sa\snon-profit\sorganization\.')

enwb_copyright = (r'Text\sis\savailable\sunder\sthe '
                  r'<a\shref="\/\/creativecommons\.org\/licenses\/by-sa\/3\.0\/">'
                  r'Creative\sCommons\sAttribution-ShareAlike\sLicense.</a>; '
                  r'additional\sterms\smay\sapply\.')


def log(msg, enabled):
    if enabled:
        print(msg)


def site_html(url):
    html_content = urllib.request.urlopen(url).readlines()
    return '\n'.join([line.decode() for line in html_content])


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
        print("no html ensure list")
        sys.exit(3)

    log(site, verbose)
    html = site_html(site)
    for match in ensures:
        log(match, verbose)
        count = len(re.findall(match, html, re.IGNORECASE))
        log(count, verbose)
        if not count:
            print("%s html not found" % (match,))
            sys.exit(2)

    print("all html is present.")


if __name__ == '__main__':
    main()
