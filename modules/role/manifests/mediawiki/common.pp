class role::mediawiki::common {
    include ::standard
    include ::profile::mediawiki::scap_proxy
    include ::profile::mediawiki::common
    include ::profile::mediawiki::nutcracker
    # dynomite testing (T97562)
    if $::realm == 'labs' {
        include ::profile::mediawiki::dynomite_wancache
    }
}
