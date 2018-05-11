# encoding: utf-8
import importlib
import re
import logging
import sys
import mock
from pathlib import Path

test_dir = Path(__file__).parent

sys.path.append(str(test_dir.parent))
script = importlib.import_module("maintain-meta_p")


class StubHandler(logging.Handler):
    records = []

    def emit(self, record):
        if record.module == 'maintain-meta_p':
            self.records.append(record)


expected_inserts_str = """
INSERT INTO meta_p.properties_anon_whitelist VALUES ('gadget-%'), ('language'), ('skin'), ('variant');
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('aawiki', 'aa', 'Wikipedia', 'wikipedia', 'https://aa.wikipedia.org', 1, 's3.labsdb', 1, 0, 1, 1, 0) ON DUPLICATE KEY UPDATE dbname='aawiki', lang='aa', name='Wikipedia', family='wikipedia', url='https://aa.wikipedia.org', size=1, slice='s3.labsdb', is_closed=1, has_flaggedrevs=0, has_visualeditor=1, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('aawikibooks', 'aa', 'Wikibooks', 'wikibooks', 'https://aa.wikibooks.org', 1, 's3.labsdb', 1, 0, 0, 1, 0) ON DUPLICATE KEY UPDATE dbname='aawikibooks', lang='aa', name='Wikibooks', family='wikibooks', url='https://aa.wikibooks.org', size=1, slice='s3.labsdb', is_closed=1, has_flaggedrevs=0, has_visualeditor=0, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('aawiktionary', 'aa', 'Wiktionary', 'wiktionary', 'https://aa.wiktionary.org', 1, 's3.labsdb', 1, 0, 0, 0, 1) ON DUPLICATE KEY UPDATE dbname='aawiktionary', lang='aa', name='Wiktionary', family='wiktionary', url='https://aa.wiktionary.org', size=1, slice='s3.labsdb', is_closed=1, has_flaggedrevs=0, has_visualeditor=0, has_wikidata=0, is_sensitive=1;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('acewiki', 'ace', 'Wikipedia', 'wikipedia', 'https://ace.wikipedia.org', 2, 's3.labsdb', 0, 0, 1, 1, 0) ON DUPLICATE KEY UPDATE dbname='acewiki', lang='ace', name='Wikipedia', family='wikipedia', url='https://ace.wikipedia.org', size=2, slice='s3.labsdb', is_closed=0, has_flaggedrevs=0, has_visualeditor=1, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('afwikiquote', 'af', 'Wikiquote', 'wikiquote', 'https://af.wikiquote.org', 1, 's3.labsdb', 0, 0, 0, 1, 0) ON DUPLICATE KEY UPDATE dbname='afwikiquote', lang='af', name='Wikiquote', family='wikiquote', url='https://af.wikiquote.org', size=1, slice='s3.labsdb', is_closed=0, has_flaggedrevs=0, has_visualeditor=0, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('alswiki', 'gsw', 'Wikipedia', 'wikipedia', 'https://als.wikipedia.org', 2, 's3.labsdb', 0, 1, 1, 1, 0) ON DUPLICATE KEY UPDATE dbname='alswiki', lang='gsw', name='Wikipedia', family='wikipedia', url='https://als.wikipedia.org', size=2, slice='s3.labsdb', is_closed=0, has_flaggedrevs=1, has_visualeditor=1, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('amwikimedia', 'hy', 'Վիքիմեդիա Հայաստան', 'wikimedia', 'https://am.wikimedia.org', 1, 's3.labsdb', 0, 0, 1, 0, 0) ON DUPLICATE KEY UPDATE dbname='amwikimedia', lang='hy', name='Վիքիմեդիա Հայաստան', family='wikimedia', url='https://am.wikimedia.org', size=1, slice='s3.labsdb', is_closed=0, has_flaggedrevs=0, has_visualeditor=1, has_wikidata=0, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('angwikisource', 'ang', 'Wicifruma', 'wikisource', 'https://ang.wikisource.org', 1, 's3.labsdb', 1, 0, 0, 1, 0) ON DUPLICATE KEY UPDATE dbname='angwikisource', lang='ang', name='Wicifruma', family='wikisource', url='https://ang.wikisource.org', size=1, slice='s3.labsdb', is_closed=1, has_flaggedrevs=0, has_visualeditor=0, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('arwiki', 'ar', 'ويكيبيديا', 'wikipedia', 'https://ar.wikipedia.org', 3, 's7.labsdb', 0, 1, 1, 1, 0) ON DUPLICATE KEY UPDATE dbname='arwiki', lang='ar', name='ويكيبيديا', family='wikipedia', url='https://ar.wikipedia.org', size=3, slice='s7.labsdb', is_closed=0, has_flaggedrevs=1, has_visualeditor=1, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('arwikinews', 'ar', 'ويكي_الأخبار', 'wikinews', 'https://ar.wikinews.org', 2, 's3.labsdb', 0, 0, 0, 1, 0) ON DUPLICATE KEY UPDATE dbname='arwikinews', lang='ar', name='ويكي_الأخبار', family='wikinews', url='https://ar.wikinews.org', size=2, slice='s3.labsdb', is_closed=0, has_flaggedrevs=0, has_visualeditor=0, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('arwikiversity', 'ar', 'ويكي الجامعة', 'wikiversity', 'https://ar.wikiversity.org', 2, 's3.labsdb', 0, 0, 0, 1, 0) ON DUPLICATE KEY UPDATE dbname='arwikiversity', lang='ar', name='ويكي الجامعة', family='wikiversity', url='https://ar.wikiversity.org', size=2, slice='s3.labsdb', is_closed=0, has_flaggedrevs=0, has_visualeditor=0, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('bgwiki', 'bg', 'Уикипедия', 'wikipedia', 'https://bg.wikipedia.org', 2, 's2.labsdb', 0, 0, 1, 1, 0) ON DUPLICATE KEY UPDATE dbname='bgwiki', lang='bg', name='Уикипедия', family='wikipedia', url='https://bg.wikipedia.org', size=2, slice='s2.labsdb', is_closed=0, has_flaggedrevs=0, has_visualeditor=1, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('commonswiki', 'en', 'Wikimedia Commons', 'special', 'https://commons.wikimedia.org', 3, 's4.labsdb', 0, 0, 0, 1, 0) ON DUPLICATE KEY UPDATE dbname='commonswiki', lang='en', name='Wikimedia Commons', family='special', url='https://commons.wikimedia.org', size=3, slice='s4.labsdb', is_closed=0, has_flaggedrevs=0, has_visualeditor=0, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('dewiki', 'de', 'Wikipedia', 'wikipedia', 'https://de.wikipedia.org', 3, 's5.labsdb', 0, 1, 1, 1, 0) ON DUPLICATE KEY UPDATE dbname='dewiki', lang='de', name='Wikipedia', family='wikipedia', url='https://de.wikipedia.org', size=3, slice='s5.labsdb', is_closed=0, has_flaggedrevs=1, has_visualeditor=1, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('dewikivoyage', 'de', 'Wikivoyage', 'wikivoyage', 'https://de.wikivoyage.org', 2, 's3.labsdb', 0, 0, 1, 1, 0) ON DUPLICATE KEY UPDATE dbname='dewikivoyage', lang='de', name='Wikivoyage', family='wikivoyage', url='https://de.wikivoyage.org', size=2, slice='s3.labsdb', is_closed=0, has_flaggedrevs=0, has_visualeditor=1, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('enwiki', 'en', 'Wikipedia', 'wikipedia', 'https://en.wikipedia.org', 3, 's1.labsdb', 0, 1, 1, 1, 0) ON DUPLICATE KEY UPDATE dbname='enwiki', lang='en', name='Wikipedia', family='wikipedia', url='https://en.wikipedia.org', size=3, slice='s1.labsdb', is_closed=0, has_flaggedrevs=1, has_visualeditor=1, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('frwiki', 'fr', 'Wikipédia', 'wikipedia', 'https://fr.wikipedia.org', 3, 's6.labsdb', 0, 0, 1, 1, 0) ON DUPLICATE KEY UPDATE dbname='frwiki', lang='fr', name='Wikipédia', family='wikipedia', url='https://fr.wikipedia.org', size=3, slice='s6.labsdb', is_closed=0, has_flaggedrevs=0, has_visualeditor=1, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('jbowiki', 'jbo', 'Wikipedia', 'wikipedia', 'https://jbo.wikipedia.org', 1, 's3.labsdb', 0, 0, 1, 1, 1) ON DUPLICATE KEY UPDATE dbname='jbowiki', lang='jbo', name='Wikipedia', family='wikipedia', url='https://jbo.wikipedia.org', size=1, slice='s3.labsdb', is_closed=0, has_flaggedrevs=0, has_visualeditor=1, has_wikidata=1, is_sensitive=1;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('testwikidatawiki', 'en', 'Wikidata', 'wikidata', 'https://test.wikidata.org', 2, 's3.labsdb', 0, 0, 1, 1, 0) ON DUPLICATE KEY UPDATE dbname='testwikidatawiki', lang='en', name='Wikidata', family='wikidata', url='https://test.wikidata.org', size=2, slice='s3.labsdb', is_closed=0, has_flaggedrevs=0, has_visualeditor=1, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('wikidatawiki', 'en', 'Wikidata', 'wikidata', 'https://www.wikidata.org', 3, 's8.labsdb', 0, 0, 0, 1, 0) ON DUPLICATE KEY UPDATE dbname='wikidatawiki', lang='en', name='Wikidata', family='wikidata', url='https://www.wikidata.org', size=3, slice='s8.labsdb', is_closed=0, has_flaggedrevs=0, has_visualeditor=0, has_wikidata=1, is_sensitive=0;
INSERT INTO meta_p.wiki (dbname, lang, name, family, url, size, slice, is_closed, has_flaggedrevs, has_visualeditor, has_wikidata, is_sensitive) VALUES ('wikimania2005wiki', 'en', 'Wikimania', 'wikimania', 'https://wikimania2005.wikimedia.org', 1, 's3.labsdb', 1, 0, 1, 0, 0) ON DUPLICATE KEY UPDATE dbname='wikimania2005wiki', lang='en', name='Wikimania', family='wikimania', url='https://wikimania2005.wikimedia.org', size=1, slice='s3.labsdb', is_closed=1, has_flaggedrevs=0, has_visualeditor=1, has_wikidata=0, is_sensitive=0;
"""  # noqa
expected_inserts = set(expected_inserts_str.strip().split("\n"))


def test_end_to_end(caplog):
    caplog.set_level(logging.DEBUG)

    logger_handler = StubHandler()
    logging.getLogger().addHandler(logger_handler)

    with mock.patch("sys.argv", [
        "./maintain-meta_p.py",
        "--all-databases",
        "--dry-run",
        "--debug",
        "--config-location=" + str(test_dir / "maintain_views.yaml"),
        "--mediawiki-config=" + str(test_dir)
    ]):
        script.main()

        inserts = set(
            re.sub("\s+", " ", record.message.split("SQL: ")[1])
            for record in logger_handler.records
            if "SQL: INSERT" in record.message.upper()
        )

        assert inserts == expected_inserts
