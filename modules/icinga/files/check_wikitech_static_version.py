#!/usr/bin/python

import requests

# This url ought to point us to the currently supported version as
#  MediaWiki as declared on mediawiki.org:
try:
    latest_version_url = ("https://www.mediawiki.org/w/api.php?"
        "action=expandtemplates&text=%7B%7BMW_stable_release_number%"
        "7D%7D&format=json&formatversion=2&prop=wikitext")
    latest_req = requests.get(latest_version_url, verify=False)
    latest_req.raise_for_status()
    latest_version = latest_req.json()['expandtemplates']['wikitext']
except:
    print "Failed to determine latest MediaWiki version from mediawiki.org"
    exit(3)


# And, this should grab the version of the currently running
#  version on wikitech-static:
try:
    static_version_url = ("https://wikitech-static.wikimedia.org/w/api.php?"
                          "action=query&meta=siteinfo&siprop=general&"
                          "format=json")
    static_req = requests.get(static_version_url, verify=False)
    static_req.raise_for_status()
    static_version_string = static_req.json()['query']['general']['generator']
    # static_version_string should be of the format "MediaWiki x.y.z"
    static_version = static_version_string.split(' ')[1]
except:
    print "Failed to determine wikitech-static MediaWiki version"
    exit(3)

if not latest_version:
    print "Failed to determine latest MediaWiki version from mediawiki.org"
    exit(3)

if not static_version:
    print "Failed to determine wikitech-static MediaWiki version"
    exit(3)

if static_version == latest_version:
    print("Wikitech-static is running the latest MediaWiki version, %s" %
          latest_version)
    exit(0)
else:
    print("Wikitech-static is running MediaWiki version %s.  "
          "It needs to be upgraded to %s." % (static_version,
                                              latest_version))
    exit(1)
