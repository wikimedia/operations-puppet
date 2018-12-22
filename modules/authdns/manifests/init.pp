# == Class authdns
# A class to implement Wikimedia's authoritative DNS system
#
class authdns(
    $lvs_services,
    $discovery_services,
    $nameservers = [ $::fqdn ],
    $gitrepo = undef,
    $monitoring = true,
    $conftool_prefix = hiera('conftool_prefix'),
) {
    require ::authdns::account
    require ::authdns::scripts
    require ::geoip::data::puppet

    if os_version('debian == stretch') {
        apt::pin { 'gdnsd':
            pin      => 'release a=stretch-backports',
            package  => 'gdnsd',
            priority => '1001',
            before   => Package['gdnsd'],
        }
    }

    package { 'gdnsd':
        ensure => installed,
    }

    service { 'gdnsd':
        ensure     => 'running',
        hasrestart => true,
        hasstatus  => true,
        restart    => 'service gdnsd reload',
        require    => Package['gdnsd'],
    }

    # the package creates this, but we want to set up the config before we
    # install the package, so that the daemon starts up with a well-known
    # config that leaves no window where it'd refuse to answer properly
    file { '/etc/gdnsd':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/gdnsd/config-options':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/config-options.erb"),
        require => File['/etc/gdnsd'],
        notify  => Service['gdnsd'],
    }
    file { '/etc/gdnsd/zones':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # This abstracts the GeoIP2-City database path from the configuration
    file { '/etc/gdnsd/geoip':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/etc/gdnsd/geoip/GeoIP2-City.mmdb':
        ensure => 'link',
        target => '/usr/share/GeoIP/GeoIP2-City.mmdb',
    }

    # Shared cookie secret to avoid cookie validity disruptions
    file { '/etc/gdnsd/secrets':
        ensure => 'directory',
        owner  => 'gdnsd',
        group  => 'gdnsd',
        mode   => '0500',
    }
    file { '/etc/gdnsd/secrets/dnscookies.key':
        ensure    => 'present',
        owner     => 'gdnsd',
        group     => 'gdnsd',
        mode      => '0400',
        content   => secret('dns/dnscookies.key'),
        show_diff => false,
        notify    => Service['gdnsd'],
    }

    $workingdir = '/srv/authdns/git' # export to template

    file { '/etc/wikimedia-authdns.conf':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template("${module_name}/wikimedia-authdns.conf.erb"),
    }

    # do the initial clone via puppet
    git::clone { $workingdir:
        directory => $workingdir,
        origin    => $gitrepo,
        branch    => 'master',
        owner     => 'authdns',
        group     => 'authdns',
        notify    => Exec['authdns-local-update'],
    }

    exec { 'authdns-local-update':
        command     => '/usr/local/sbin/authdns-local-update --skip-review --initial',
        user        => root,
        refreshonly => true,
        timeout     => 60,
        require     => [
                File['/etc/wikimedia-authdns.conf'],
                File['/etc/gdnsd/config-options'],
                File['/etc/gdnsd/discovery-geo-resources'],
                File['/etc/gdnsd/discovery-metafo-resources'],
                File['/etc/gdnsd/discovery-states'],
                File['/etc/gdnsd/discovery-map'],
                File['/etc/gdnsd/geoip'],
                File['/etc/gdnsd/geoip/GeoIP2-City.mmdb'],
                File['/etc/gdnsd/zones'],
            ],
        # we prepare the config even before the package gets installed, leaving
        # no window where service would be started and answer with REFUSED
        before      => Package['gdnsd'],
    }

    if $monitoring {
        include ::authdns::monitoring
    }

    # Discovery Magic

    file { '/etc/gdnsd/discovery-geo-resources':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/discovery-geo-resources.erb"),
        notify  => Service['gdnsd'],
    }

    file { '/etc/gdnsd/discovery-metafo-resources':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/discovery-metafo-resources.erb"),
        notify  => Service['gdnsd'],
    }

    file { '/etc/gdnsd/discovery-states':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template("${module_name}/discovery-states.erb"),
        notify  => Service['gdnsd'],
    }

    file { '/etc/gdnsd/discovery-map':
        ensure => 'present',
        mode   => '0444',
        owner  => 'root',
        group  => 'root',
        source => "puppet:///modules/${module_name}/discovery-map",
        notify => Service['gdnsd'],
    }

    class { 'confd':
        prefix => $conftool_prefix,
    }

    create_resources(::authdns::discovery_statefile, $discovery_services, { lvs_services => $lvs_services })
}
