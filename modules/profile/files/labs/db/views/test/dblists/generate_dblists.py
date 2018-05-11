"""
Helper script to update test dblists in this directory. Based on the production
dblists, this script determines a minimum subset of interesting wikis (at least
one from every dblist), then creates dblists with this subset of wikis.

NB. the 'source' variable may need to be modified to point to the actual
location of the production dblists.
"""

import os

source = r"/usr/local/lib/mediawiki-config/dblists"
target = os.path.split(__file__)[0]

required_dblists = """
closed.dblist
deleted.dblist
flaggedrevs.dblist
large.dblist
medium.dblist
private.dblist
s1.dblist
s2.dblist
s3.dblist
s4.dblist
s5.dblist
s6.dblist
s7.dblist
s8.dblist
small.dblist
special.dblist
visualeditor-nondefault.dblist
wikibooks.dblist
wikidata.dblist
wikidataclient.dblist
wikimania.dblist
wikimedia.dblist
wikinews.dblist
wikipedia.dblist
wikiquote.dblist
wikisource.dblist
wikiversity.dblist
wikivoyage.dblist
wiktionary.dblist
""".strip().split("\n")


def make_varied_wiki_set(dblists):
    wikis = {'jbowiki'}
    # first, make a list of wikis so that every dblist file is used at least once
    for dblist in dblists:
        wikis.add(get_first_wiki(dblist))

    return wikis


def get_first_wiki(dblist):
    with open(os.path.join(source, dblist)) as f:
        for line in f:
            if not line.startswith('#'):
                return line.strip()


def create_dblist(dblist, include_wikis):
    with open(os.path.join(source, dblist)) as s, open(os.path.join(target, dblist), 'w') as t:
        for line in s:
            if line.strip() in include_wikis or line.startswith('#'):
                t.write(line)


include_wikis = make_varied_wiki_set(required_dblists)

print("Including wikis: ")
for w in sorted(include_wikis):
    print("- {}".format(w))

for dblist in ["all.dblist"] + required_dblists:
    create_dblist(dblist, include_wikis)
