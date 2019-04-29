# This role is used by testing services
# Ex: Parsoid roundtrip testing, Parsoid & PHP parser visual diff testing
class role::parsoid::testing {
    system::role { 'parsoid::testing':
        description => 'Parsoid server (rt-testing, visual-diffing, etc.)'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::mediawiki::php
    include ::profile::parsoid::diffserver
    include ::profile::parsoid::rt_server
    include ::profile::parsoid::rt_client
    include ::profile::parsoid::vd_server
    include ::profile::parsoid::vd_client
    include ::profile::parsoid::testing
}
