# = Class: role::certspotter
#
# Sets up certspotter for Wikimedia prod
#
class role::certspotter {
    class { '::certspotter':
        address => 'noc@wikimedia.org',
        # cf. role::cache::ssl::unified
        # prefix with a dot to monitor domain + all subdomains
        domains => [
            '.wikipedia.org',
            '.wikimedia.org',
            '.mediawiki.org',
            '.wikibooks.org',
            '.wikidata.org',
            '.wikinews.org',
            '.wikiquote.org',
            '.wikisource.org',
            '.wikiversity.org',
            '.wikivoyage.org',
            '.wiktionary.org',
            '.wikimediafoundation.org',
            '.wmfusercontent.org',
            '.w.wiki',
        ],
    }
}
