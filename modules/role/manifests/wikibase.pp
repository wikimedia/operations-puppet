# wikiba.se (T99531)
class role::wikibase {

    include ::standard
    include ::profile::microsites::httpd
    include ::profile::microsites::wikibase

    system::role { 'wikibase':
        description => 'https://wikiba.se'
    }
}
