# sets up MediaWiki Codesearch
# https://codesearch.wmcloud.org/search/
class role::codesearch {

    system::role { 'codesearch':
        description => 'MediaWiki Codesearch instance'
    }

    include ::profile::base::production
    include ::profile::firewall
    include ::profile::codesearch
}
