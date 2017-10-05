# wikiba.se (T99531)
class role::wikibase {

    include ::standard

    include ::profile::microsites::wikibase        # upcoming https://wikiba.se

    system::role { 'wikibase':
        description => 'https://wikiba.se'
    }
}
