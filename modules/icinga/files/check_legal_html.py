#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
2015 Chase Pettet
2023 Jaime Crespo

HTML that needs to exist per T108081/T119456

This is meant to ensure certain legal required
content is present.  Content assurance is
case INSENSITIVE.

Try to do more robust validation, that would
still work if the general wording changes, or
the license's url get moved, without
frequently alerting sysops: T317169.
"""


import argparse
import logging
import sys
from urllib.error import URLError
from urllib.parse import urljoin
from urllib.request import urlopen, Request

from bs4 import BeautifulSoup


# version of the CC license to check the match with
LICENSE_VERSION = '4.0'
# User agent used to retrieve web content, so it is not a generic one
UA = 'Python/WMF/check_legal_html.py https://wikitech.org'
# Icinga error constants
ICINGA_OK = 0
ICINGA_WARNING = 1
ICINGA_CRITICAL = 2
ICINGA_UNKNOWN = 3


def uniformize_url(site, url):
    """
    Make sure provided urls are complete, valid ones, as sometimes
    humans and browsers use shortcuts. Return the provided one, completed.
    """
    return urljoin(site, url)  # Should we enforce https or not this layer concern?


def download_page(site, url):
    """
    Given a URL with the address of a website, send a GET request
    to download it and return its html
    """
    logging.info('Downloading website: %s', url)
    url = uniformize_url(site, url)
    try:
        html = urlopen(Request(url, headers={'User-Agent': UA}))
    except URLError as error:
        logging.error('Error while downloading %s: %s', url, error)
        sys.exit(ICINGA_CRITICAL)
    return html


def text_contains_all_words(text, words):
    """
    Check that the given text contain all words on given list
    """
    for word in words:
        if word not in text:
            logging.info('Expected word %s is missing!', word)
            return False
    return True


def link_contains_all_words(site, url, words):
    """
    Check that the given url, once downloaded contains every single world in the given list,
    returns true if that is the case, false in other cases. Produces an error if the page fails
    to load correctly.
    """
    html = download_page(site, url)
    text = BeautifulSoup(html, 'html.parser').get_text().lower()
    return text_contains_all_words(text, words)


def link_contains_cc_license(site, url):
    """
    Check that the given url is a link to creative commons or an internal link containing all
    of the following words "license creative commons share remix attribution share+alike <version>"
    """
    # avoid scraping external sites, which have robots.txt and filtering limitations
    words = ['creativecommons.org', 'license', 'by-sa', LICENSE_VERSION]
    if text_contains_all_words(url, words):
        return True
    words = ['license', 'creative', 'commons', 'share', 'remix', 'attribution',
             'share alike', LICENSE_VERSION]
    return link_contains_all_words(site, url, words)


def copyright(site, footer):
    """
    Check that the footer contains a copyright link with the words "creative commons attribution
    sharealike" or "cc by sa", and the url linked is a valid license. Return true if valid.
    """
    copyright_links = [link for link in footer.find_all('a')
                       if (('creative' in link.get_text().lower()
                            and 'commons' in link.get_text().lower())
                           or 'cc' in link.get_text().lower())]
    for link in copyright_links:
        text = link.get_text().lower()
        href = link.get('href')
        logging.info('Checking text: "%s"', text)
        if (text_contains_all_words(text, ['attribution', 'sharealike'])
                or text_contains_all_words(text, ['by', 'sa'])):
            return link_contains_cc_license(site, href)
    logging.info('No link was found on the footer containing references to Creative Commons!')
    return False


def link_contains_wikimedia_terms(site, url):
    """
    Check that the given url is a link to Wikimedia's term of use"
    """
    words = ['services', 'privacy policy', 'content', 'activities', 'illegal', 'password',
             'trademarks', 'licensing', 'dmca', 'third-party', 'management', 'termination',
             'disclaimers',  'liability', 'modifications']
    return link_contains_all_words(site, url, words)


def terms(site, footer):
    """
    Check that the footer contains a terms of use link with the text 'terms' & 'use' and it links
    to a url containing valid terms of use. Return true if valid.
    """
    terms_links = [link for link in footer.find_all('a')
                   if 'terms' in link.get_text().lower()
                      and 'use' in link.get_text().lower()]

    for link in terms_links:
        href = link.get('href')
        text = link.get_text()
        logging.info('Checking text: "%s"', text)
        if len(text) > 0:
            return link_contains_wikimedia_terms(site, href)
    logging.info('No link was found on the footer containing references to Terms of use!')
    return False


def link_contains_wikimedia_privacy_policy(site, url):
    """
    Check that the given url is a link to Wikimedia's privacy policy
    """
    words = ['wikimedia', 'introduction', 'site', 'personal information', 'third part',
             'collect', 'contribution', 'metadata', 'information',
             'sharing', 'protect', 'contact']
    return link_contains_all_words(site, url, words)


def privacy(site, footer):
    """
    Check that the footer contains a privacy policy link with the text 'privacy' & 'policy' and
    it links to a url containing a valid privacy policy. Return true if valid.
    """
    privacy_policy_links = [link for link in footer.find_all('a')
                            if 'privacy' in link.get_text().lower()
                               and 'policy' in link.get_text().lower()]

    for links in privacy_policy_links:
        href = links.get('href')
        return link_contains_wikimedia_privacy_policy(site, href)
    logging.info('No link was found on the footer containing references to a Privacy policy!')
    return False


def trademark(_site, footer):
    """
    Check that the footer contains a trademark link with the text 'trademark' and it links to a
    url containing a valid trademark description. Return true if valid.
    """
    text = footer.get_text().lower()
    logging.info("Checking Wikipedia® trademark mention...")
    words = ['wikipedia®', 'registered', 'trademark', 'wikimedia', 'foundation', 'inc']
    if text_contains_all_words(text, words):
        return True
    logging.info('No reference to the Wikipedia trademark was found!')
    return False


def get_checks():
    """
    Return the list of functions to check, for each given check: desktop_enwb (English Wikibooks,
    desktop site), desktop_enwp (English Wikipedia, desktop site) and mobile (wiki mobile site).
    """
    return {
        'desktop_enwb': [
            copyright,
            terms,
            privacy,
        ],
        'desktop_enwp': [
            copyright,
            terms,
            privacy,
            trademark,
        ],
        'mobile': [
            copyright,
            terms,
            privacy,
        ],
    }


def site_footer(site, url):
    """
    Request and retrieve the HTML parsed tree of the footer
    section (area contained within the <footer> html tag) of a given
    webpage. Return the DOM of the first one found.
    """
    html = download_page(site, url)
    footers = BeautifulSoup(html, 'html.parser').find_all('footer')
    if len(footers) == 0:
        logging.error("Found no footer section on html")
        sys.exit(ICINGA_CRITICAL)
    if len(footers) > 1:
        logging.error("Found more than 1 footer sections")
        sys.exit(ICINGA_CRITICAL)
    return footers[0]


def handle_args():
    """
    Handle the input arguments. Keep compatibility with older execution parameters.
    """
    parser = argparse.ArgumentParser(description=(
        "Validate certain legal HTML exists on the footer of a given webpage, as per "
        "legal requirement. See https://phabricator.wikimedia.org/T317169 & "
        "https://phabricator.wikimedia.org/T108081 for more context.")
    )
    parser.add_argument('-site', default='localhost', help=(
        "The url of the website to check"
        "(e.g. 'https://en.wikipedia.org/wiki/Main_page'). By default it checks 'localhost'.")
    )
    parser.add_argument('-ensure', type=str, choices=get_checks().keys(), help=(
        "Selection of checks to perform (mobile "
        "site and non-Wikipedias don't have a Wikipedia trademark check).")
    )
    parser.add_argument('-v', '--verbose', action='store_true', default=False, help=(
        "Enable verbose description "
        "of checks, useful to debug the icinga errors.")
    )
    args = parser.parse_args()
    return args


def main():
    """
    Main procedure
    """
    args = handle_args()
    site = args.site
    if args.verbose:
        logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s', level=logging.INFO)
    else:
        logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.ERROR)
    ensures = get_checks().get(args.ensure, [])
    if not ensures:
        logging.error("No valid list of checks found for the given ensure list")
        sys.exit(ICINGA_UNKNOWN)

    site_version = 'mobile site' if args.ensure == 'mobile' else 'desktop site'
    check_list = ', '.join([c.__name__ for c in ensures])

    logging.info('Checking site: %s', site)
    footer = site_footer('localhost', site)

    for check in ensures:
        logging.info('Executing check of %s...', check.__name__)
        found = check(site, footer)
        if not found:
            logging.error('%s html not found for %s (%s).', check.__name__, site, site_version)
            sys.exit(ICINGA_CRITICAL)
        logging.info('%s html found correctly', check.__name__)

    print(f'All legal html excerpts are present for {site} ({site_version}): {check_list}')
    sys.exit(ICINGA_OK)


if __name__ == '__main__':
    main()
