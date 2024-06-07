# sets up MediaWiki Codesearch
# https://codesearch.wmcloud.org/search/
class role::codesearch {
    include profile::base::production
    include profile::firewall
    include profile::codesearch
}
