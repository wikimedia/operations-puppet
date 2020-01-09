# sets up Wikimedia Codesearch
# https://codesearch.wmflabs.org/search/
class role::codesearch {

    system::role { 'codesearch':
        description => 'Wikimedia Codesearch instance'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::codesearch
}
