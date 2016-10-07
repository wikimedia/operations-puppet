#! /usr/bin/python3
# -*- coding: utf-8 -*-

#  Based on work by Marc-André Pelletier, ported to Python by Alex Monk
#  Copyright © 2015 Alex Monk <krenair@gmail.com>
#  Copyright © 2013 Marc-André Pelletier <mpelletier@wikimedia.org>
#
#  Permission to use, copy, modify, and/or distribute this software for any
#  purpose with or without fee is hereby granted, provided that the above
#  copyright notice and this permission notice appear in all copies.
#
#  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
#  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
#  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
#  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
#  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
#  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
#  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
##
##  This script sets up tables of metainformation on each slice (in the meta_p
##  database).
##
##  The script expects to be invoked in a fresh copy of
##  operations/mediawiki-config where it will get most of its information,
##  and will connect to each wiki through the API to get the rest.
##
##  It connects to the slices with the credentials in the invoking
##  user's .my.cnf, but is probably only useful if those credentials
##  have full control over the meta_p database on each slice to be processed.
##

slices = [
    ('labsdb1001.eqiad.wmnet', 3306),
    ('labsdb1002.eqiad.wmnet', 3306),
    ('labsdb1003.eqiad.wmnet', 3306)
]

import codecs
import collections
from configparser import ConfigParser
import json
import logging
import pymysql
import re
import subprocess
import urllib
import urllib.request

config = ConfigParser()
config.read('.my.cnf')
dbuser = config.get('client', 'user')[1:-1] # Strip first and last characters - just apostrophes
dbpassword = config.get('client', 'password')[1:-1] # Strip first and last characters - just apostrophes

subprocess.call(["git", "pull"], cwd = "mediawiki-config")

dbs = {db : {} for db in open('mediawiki-config/all.dblist').read().splitlines()}
def read_list(listFname, prop, val):
    for db in open('mediawiki-config/' + listFname + '.dblist').read().splitlines():
        if db in dbs:
            dbs[db][prop] = val

read_list("closed", "closed", True)
read_list("deleted", "deleted", True)
read_list("small", "size", 1)
read_list("medium", "size", 2)
read_list("large", "size", 3)
read_list("private", "private", True)
read_list("special", "family", "special")
read_list("flaggedrevs", "has_flaggedrevs", True)
read_list("visualeditor-default", "has_visualeditor", True)
read_list("wikidataclient", "has_wikidata", True)

for slice in ['s1', 's2', 's3', 's4', 's5', 's6', 's7']: # TODO: silver/labtestweb2001
    read_list(slice, "slice", slice)

for family in ["wikibooks", "wikidata", "wikinews", "wikiquote", "wikisource",
                "wikiversity", "wikivoyage", "wiktionary", "wikimania", "wikimedia",
                "wikipedia"]:
    read_list(family, "family", family)

# Sadly, case sensitivity of titles isn't in a .dblist, nor is it
# exposed through the API so we have to hardcode it here to match
# what is in InitialiseSettings.php
read_list("wiktionary", "sensitive", True)
dbs['jbowiki']['sensitive'] = True

inCanonConfig = False
canonical = {}
for line in open('mediawiki-config/wmf-config/InitialiseSettings.php').read().splitlines():
    if line == "'wgCanonicalServer' => array(":
        inCanonConfig = True
    elif inCanonConfig and line == "),":
        inCanonConfig = False
    else:
        matches = re.match("^\s+'(.*)'\s+=>\s+'(.*)'\s*,\s*$", line)
        if inCanonConfig and matches:
            canonical[matches.group(1)] = matches.group(2)

cached = collections.defaultdict(dict)
try:
    with open('wiki-cache.json') as cacheFile:
        cached = json.load(cacheFile)
except IOError as e:
    pass

for db, dbInfo in dbs.items():
    if 'private' in dbInfo and dbInfo['private']:
        continue
    elif 'deleted' in dbInfo and dbInfo['deleted']:
        continue

    canon = None
    if db in canonical:
        canon = canonical[db]
    else:
        matches = re.match("^(.*)(wik[it].*)", db)
        if matches:
            lang = matches.group(1)
            canon = canonical[dbInfo['family']].replace('$lang', lang)

    if canon:
        canon = canon.replace('_', '-')
        dbInfo['url'] = canon
        if canon in cached:
            dbInfo['lang'] = cached[canon]['lang']
            dbInfo['name'] = cached[canon]['name']
        else:
            logging.info("Querying " + canon + "...")
            try:
                req = urllib.request.Request(canon + "/w/api.php?action=query&meta=siteinfo&siprop=general&format=json")
                req.add_header("User-Agent", "operations/software.git maintain-meta_p.py")

                with urllib.request.urlopen(req) as response:
                    result = json.load(codecs.getreader("utf-8")(response))['query']
                    cached[canon]['lang'] = dbInfo['lang'] = result['general']['lang']
                    cached[canon]['name'] = dbInfo['name'] = result['general']['sitename']
            except Exception as e:
                logging.exception(e)

with open('wiki-cache.json', 'w') as cacheFile:
    json.dump(cached, cacheFile)

for dbhost, dbport in slices:
    dbh = pymysql.connect(host=dbhost, port=dbport, user=dbuser, passwd=dbpassword, charset='utf8')
    cursor = dbh.cursor()

    logging.info("Update/create meta tables on", dbhost + ":" + str(dbport) + "...")
    cursor.execute("CREATE DATABASE IF NOT EXISTS meta_p DEFAULT CHARACTER SET utf8;")
    cursor.execute("""CREATE TABLE IF NOT EXISTS meta_p.wiki (
        dbname varchar(32) PRIMARY KEY,
        lang varchar(12) NOT NULL DEFAULT 'en',
        name text,
        family text,
        url text,
        size numeric(1) NOT NULL DEFAULT 1,
        slice text NOT NULL,
        is_closed numeric(1) NOT NULL DEFAULT 0,
        has_echo numeric(1) NOT NULL DEFAULT 1,
        has_flaggedrevs numeric(1) NOT NULL DEFAULT 0,
        has_visualeditor numeric(1) NOT NULL DEFAULT 0,
        has_wikidata numeric(1) NOT NULL DEFAULT 0,
        is_sensitive numeric(1) NOT NULL DEFAULT 0);""")
    cursor.execute("""CREATE OR REPLACE VIEW meta_p.legacy AS
        SELECT dbname, lang, family, NULL AS domain, size, 0 AS is_meta,
               is_closed, 0 AS is_multilang, (family='wiktionary') AS is_sensitive,
               NULL AS root_category, slice AS server, '/w/' AS script_path
            FROM meta_p.wiki;""")
    cursor.execute("""CREATE TABLE IF NOT EXISTS meta_p.properties_anon_whitelist (
        pw_property varbinary(255) PRIMARY KEY);""")
    cursor.execute("START TRANSACTION;")
    cursor.execute("TRUNCATE meta_p.wiki;")
    for db, dbInfo in dbs.items():
        if 'deleted' in dbInfo and dbInfo['deleted']:
            continue
        elif 'private' in dbInfo and dbInfo['private']:
            continue
        elif 'slice' not in dbInfo: # TODO: wikitech breaks here
            continue

        if dbInfo['slice'] in ['s2', 's4', 's5']:
            ldb = 'c2'
        elif dbInfo['slice'] == 's1':
            ldb = 'c1'
        else:
            ldb = 'c3'

        fields = {
            'has_flaggedrevs': int('has_flaggedrevs' in dbInfo and dbInfo['has_flaggedrevs']),
            'has_visualeditor': int('has_visualeditor' in dbInfo and dbInfo['has_visualeditor']),
            'has_wikidata': int('has_wikidata' in dbInfo and dbInfo['has_wikidata']),
            'is_closed': int('closed' in dbInfo and dbInfo['closed']),
            'is_sensitive': int('sensitive' in dbInfo and dbInfo['sensitive']),
            'lang': 'en',
            'size': 1,
            'dbname': db,
            'slice': dbInfo['slice'] + '.labsdb',
            'url': None,
            'family': None,
            'name': None
        }
        if 'url' in dbInfo:
            fields['url'] = dbInfo['url']
        if 'family' in dbInfo:
            fields['family'] = dbInfo['family']
        if 'lang' in dbInfo:
            fields['lang'] = dbInfo['lang']
        if 'name' in dbInfo:
            fields['name'] = dbInfo['name']
        if 'size' in dbInfo:
            fields['size'] = dbInfo['size']
        cursor.execute(
            "INSERT INTO meta_p.wiki " +
            "(has_flaggedrevs, has_visualeditor, has_wikidata, is_closed, is_sensitive, dbname, slice, " +
                "url, family, lang, name, size) " +
            "VALUES (%(has_flaggedrevs)s, %(has_visualeditor)s, %(has_wikidata)s, %(is_closed)s, " +
                "%(is_sensitive)s, %(dbname)s, %(slice)s, %(url)s, %(family)s, %(lang)s, " +
                "%(name)s, %(size)s);",
            fields
        )

    cursor.execute("COMMIT;")
    cursor.execute("START TRANSACTION;")
    cursor.execute("DELETE FROM meta_p.properties_anon_whitelist;")
    # This is hardcoded for now
    cursor.execute("INSERT INTO meta_p.properties_anon_whitelist VALUES ('gadget-%');")
    cursor.execute("COMMIT;")

logging.info("All done.")
