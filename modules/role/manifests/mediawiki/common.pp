class role::mediawiki::common {
    include ::standard
    include ::profile::mediawiki::scap_proxy
    include ::profile::mediawiki::common
    include ::profile::mediawiki::nutcracker
    # mcrouter testing (T151466)
    if $::realm == 'labs' {
        include ::profile::mediawiki::mcrouter_wancache
    }
}
