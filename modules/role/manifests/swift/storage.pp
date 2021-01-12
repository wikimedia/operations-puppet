# filtertags: labs-project-deployment-prep labs-project-swift
class role::swift::storage {

    system::role { 'swift::storage':
        description => 'swift storage brick',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::swift::storage
    include ::toil::systemd_scope_cleanup
    include ::profile::statsite

    class { '::profile::prometheus::statsd_exporter':
        relay_address => '',
    }

    include ::profile::swift::storage::expirer

    # Temporary partial rollout in eqiad, a mix of new and old hosts
    if $::hostname =~ /^ms-be10(50|55|60|61)/ {
        include ::profile::swift::performance
    }
}
