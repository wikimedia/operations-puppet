# == Class: role::doc
#
# Sets up a machine to serve generated documentation.
# https://docs.wikimedia.org - T211974
class role::doc {

    system::role { 'doc':
        ensure      => 'present',
        description => 'Wikimedia Documentation Server',
    }

    include ::profile::base::production
    include ::profile::firewall
    include ::profile::backup::host
    include ::profile::doc
    include ::profile::prometheus::apache_exporter

    if $::realm == 'production' {
        include ::profile::tlsproxy::envoy
    }
}
