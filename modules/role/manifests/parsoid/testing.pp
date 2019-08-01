# This role is used by testing services
# Ex: Parsoid roundtrip testing, Parsoid & PHP parser visual diff testing
class role::parsoid::testing {

    system::role { 'parsoid::testing':
        description => 'Parsoid server (rt-testing, visual-diffing, etc.)'
    }

    ## Basics
    include ::profile::standard
    include ::profile::base::firewall

    ## Parsoid
    include ::profile::parsoid::diffserver
    include ::profile::parsoid::rt_server
    include ::profile::parsoid::rt_client
    include ::profile::parsoid::vd_server
    include ::profile::parsoid::vd_client
    include ::profile::parsoid::testing

    ## Mediawiki
    include ::role::mediawiki::common
    include ::profile::mediawiki::php
    include ::profile::mediawiki::php::monitoring
    include ::profile::mediawiki::webserver
    # restart php-fpm if the opcache available is too low
    # currently not included because it pulls in LVS
    # include ::profile::mediawiki::php::restarts

    ## Prometheus
    include ::profile::prometheus::apache_exporter
    include ::profile::prometheus::hhvm_exporter
    include ::profile::prometheus::php_fpm_exporter
}
