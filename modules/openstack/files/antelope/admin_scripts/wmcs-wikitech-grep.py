#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0

# -*- coding: utf-8 -*-
"""
  usage: mwgrep [-h] [--max-results N] [--timeout N] [--user | --module]
                [--title TITLE] regex

  Grep for Lua or CSS and JS code fragments
    on (per default) MediaWiki wiki pages

  positional arguments:
    regex            regex to search for

  optional arguments:
    -h, --help       show this help message and exit
    --max-results N  show at most this many results (default: 100)
    --timeout N      abort search after this many seconds (default: 30)
    --user           search NS_USER rather than NS_MEDIAWIKI
    --module         search NS_MODULE rather than NS_MEDIAWIKI
    --title TITLE    restrict search to pages with this title

  mwgrep will grep the MediaWiki namespace across Wikimedia wikis. specify
  --user to search the user namespace instead. See the lucene documentation
  for org.apache.lucene.util.automaton.RegExp for supported syntax. The current
  lucene version is available from `curl search.svc.eqiad.wmnet:9200`.

"""
import argparse
import bisect
import importlib
import json
import sys
import urllib.error
import urllib.parse
import urllib.request

importlib.reload(sys)
sys.setdefaultencoding("utf-8")


TIMEOUT = 30
BASE_URI = "http://search.svc.eqiad.wmnet:9200/_all/page/_search"
NS_MEDIAWIKI = 8
NS_USER = 2
NS_MODULE = 828
PREFIX_NS = {NS_MEDIAWIKI: "MediaWiki:", NS_USER: "User:", NS_MODULE: "Module:"}

ap = argparse.ArgumentParser(
    prog="mwgrep",
    description="Grep for CSS and JS code fragments in MediaWiki wiki pages",
    epilog="mwgrep will grep the MediaWiki namespace across Wikimedia wikis. "
    "specify --user to search the user namespace instead.",
)
ap.add_argument("term", help="text to search for")

ap.add_argument(
    "--max-results",
    metavar="N",
    type=int,
    default=1000,
    help="show at most this many results (default: 1000)",
)

ap.add_argument(
    "--timeout",
    metavar="N",
    type="{0}s".format,
    default="30",
    help="abort search after this many seconds (default: 30)",
)

args = ap.parse_args()

filters = [
    {
        "bool": {
            "must": [
                {"term": {"wiki": "labswiki"}},
                {
                    "source_regex": {
                        "regex": args.term,
                        "field": "source_text",
                        "ngram_field": "source_text.trigram",
                        "max_determinized_states": 20000,
                        "max_expand": 10,
                        "case_sensitive": True,
                        "locale": "en",
                        "timeout": args.timeout,
                    }
                },
            ],
            "must_not": [
                {"term": {"namespace": "2"}},  # User
                {"term": {"namespace": "3"}},  # User talk
            ],
        }
    }
]

search = {
    "size": args.max_results,
    "_source": ["namespace", "title", "namespace_text"],
    "sort": ["_doc"],
    "query": {"bool": {"filter": filters}},
    "stats": ["mwgrep"],
}

query = {"timeout": args.timeout}

matches = {"public": [], "private": []}
uri = BASE_URI + "?" + urllib.parse.urlencode(query)
try:
    req = urllib.request.urlopen(uri, json.dumps(search))
    full_result = json.load(req)
    result = full_result["hits"]

    for hit in result["hits"]:
        db_name = hit["_index"].rsplit("_", 2)[0]
        title = hit["_source"]["title"]
        ns = hit["_source"]["namespace_text"]
        if ns != "":
            ns = "%s:" % ns
        page_name = "%s%s" % (ns, title)
        bisect.insort(matches["public"], (db_name, page_name))

    if matches["public"]:
        print("## Public wiki results")
        for db_name, page_name in matches["public"]:
            print(("{:<20}{}".format(db_name, page_name)))

    print("")
    print(("(total: %s, shown: %s)" % (result["total"], len(result["hits"]))))
    if full_result["timed_out"]:
        print(
            """
The query was unable to complete within the alloted time. Only partial results
are shown here, and the reported total hits is <= the true value. To speed up
the query:

* Ensure the regular expression contains one or more sets of 3 contiguous
  characters. A character range ([a-z]) won't be expanded to count as
  contiguous if it matches more than 10 characters.
* Use a simpler regular expression. Consider breaking the query up into
  multiple queries where possible.
"""
        )

except urllib.error.HTTPError as error:
    try:
        error_body = json.load(error)
        if "error" in error_body and "root_cause" in error_body["error"]:
            root_cause = error_body["error"]["root_cause"][0]
            if root_cause["type"] == "invalid_regex_exception":
                sys.stderr.write(
                    "Error parsing regex: {0}\n{1}\n".format(
                        args.term, root_cause["reason"]
                    )
                )
            else:
                sys.stderr.write(
                    "Unknown error: \
                                 {0}\n".format(
                        root_cause["reason"]
                    )
                )
        else:
            sys.stderr.write(
                "Received unexpected json body \
                             from elasticsearch: \n{0}\n".format(
                    json.dumps(error_body, indent=4, separators=(",", ": "))
                )
            )
    except ValueError as e:
        sys.stderr.write(
            "Error '{0}' while parsing \
                         elasticsearch response '{1}'.\n".format(
                e.message, error
            )
        )
    exit(1)
