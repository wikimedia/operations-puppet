# SPDX-License-Identifier: Apache-2.0
# == Class: profile::grafana::production
#
# Grafana is a dashboarding web application.
# It powers <https://grafana.wikimedia.org>.
#
class profile::grafana::production (
    Stdlib::Fqdn $active_host      = lookup('profile::grafana::active_host'),
    Stdlib::Fqdn $standby_host     = lookup('profile::grafana::standby_host'),
    Boolean $enable_dashboard_sync = lookup('profile::grafana::enable_dashboard_sync', { 'default_value' => true }),
) {
    include ::profile::grafana
    include ::profile::grafana::grizzly

    $on_active_host = $active_host == $facts['networking']['fqdn'] ? {
        true  => present,
        false => absent,
    }

    $dashboard_sync_ensure = $enable_dashboard_sync ? {
        true  => 'present',
        false => 'absent',
    }

    # Enables rsync'ing /var/lib/grafana from active host to standby host.
    rsync::quickdatacopy { 'var-lib-grafana':
        ensure      => $dashboard_sync_ensure,
        source_host => $active_host,
        dest_host   => $standby_host,
        module_path => '/var/lib/grafana',
        exclude     => 'grafana.db-journal',
        chown       => 'grafana:grafana',
    }

    profile::auto_restarts::service { 'rsync': }

    class {'::grafana::ldap_sync':
        ensure => $on_active_host,
    }

    class {'::profile::grafana::datasource_exporter':
        ensure => $on_active_host,
    }

    # On Grafana 5 and later, datasource configurations are stored in Puppet
    # as YAML and pushed to Grafana that way, which reads them at startup.
    grafana::datasources { 'production-datasources':
        source => 'puppet:///modules/profile/grafana/production-datasources.yaml',
    }

    grafana::dashboard { 'varnish-aggregate-client-status-codes':
        ensure  => 'absent',
        content => ''
    }

    grafana::dashboard { 'swift':
        source => 'puppet:///modules/grafana/dashboards/swift',
    }

    include ::profile::slothslos::report2drive
}
