# == Class authdns
# A class to implement Wikimedia's authoritative DNS system
#
class authdns(
    $lvs_services,
    $discovery_services,
    $nameservers = [ $::fqdn ],
    $monitoring = true,
    $conftool_prefix = hiera('conftool_prefix'),
) {
    require ::authdns::account
    require ::authdns::scripts
    require ::authdns::rsync
    require ::geoip::data::puppet

    class { 'authdns::config':
        lvs_services       => $lvs_services,
        discovery_services => $discovery_services,
    }

    file { '/etc/gdnsd':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/gdnsd/zones':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/var/lib/gdnsd':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    package { 'gdnsd':
        ensure => installed,
    }

    service { 'gdnsd':
        ensure     => 'running',
        hasrestart => true,
        hasstatus  => true,
        require    => Package['gdnsd'],
    }

    if $monitoring {
        include ::authdns::monitoring
    }

    file { '/etc/wikimedia-authdns.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template("${module_name}/wikimedia-authdns.conf.erb"),
    }

    exec { 'authdns-local-update':
        command => '/usr/local/sbin/authdns-local-update --skip-review',
        user    => root,
        timeout => 60,
        creates => '/etc/gdnsd/discovery-geo-maps', # some unique ::config file
        require => [
            File['/etc/wikimedia-authdns.conf'],
            File['/etc/gdnsd'],
            File['/etc/gdnsd/zones'],
            File['/var/lib/gdnsd'],
        ],
        # we prepare the config even before the package gets installed, leaving
        # no window where service would be started and answer with REFUSED
        before  => Package['gdnsd'],
    }

    class { 'confd':
        prefix => $conftool_prefix,
    }

    create_resources(::authdns::discovery_statefile, $discovery_services, { lvs_services => $lvs_services })
}
