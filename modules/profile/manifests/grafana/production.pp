# == Class: profile::grafana::production
#
# Grafana is a dashboarding web application.
# It powers <https://grafana.wikimedia.org>.
#
class profile::grafana::production (
    Stdlib::Fqdn $active_host = lookup('profile::grafana::active_host'),
) {
    include ::profile::grafana
    include ::profile::grafana::grizzly

    $on_active_host = $active_host == $::fqdn ? {
        true  => present,
        false => absent,
    }

    $not_on_active_host = $active_host == $::fqdn ? {
        true  => absent,
        false => present,
    }

    rsync::quickdatacopy { 'var-lib-grafana':
      ensure              => $not_on_active_host,
      source_host         => $active_host,
      dest_host           => $::fqdn,
      module_path         => '/var/lib/grafana',
      server_uses_stunnel => true,
    }

    class {'::grafana::ldap_sync':
        ensure => $on_active_host,
    }

    # On Grafana 5 and later, datasource configurations are stored in Puppet
    # as YAML and pushed to Grafana that way, which reads them at startup.
    file { '/etc/grafana/provisioning/datasources/production-datasources.yaml':
        ensure  => present,
        source  => 'puppet:///modules/profile/grafana/production-datasources.yaml',
        owner   => 'root',
        group   => 'grafana',
        mode    => '0440',
        require => Package['grafana'],
        notify  => Service['grafana-server'],
    }

    grafana::dashboard { 'varnish-http-errors':
        ensure  => absent,
        content => '',
    }

    grafana::dashboard { 'varnish-aggregate-client-status-codes':
        source => 'puppet:///modules/grafana/dashboards/varnish-aggregate-client-status-codes',
    }

    grafana::dashboard { 'swift':
        source => 'puppet:///modules/grafana/dashboards/swift',
    }
}
